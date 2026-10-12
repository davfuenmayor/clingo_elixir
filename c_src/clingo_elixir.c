/* Thin clingo C ABI binding. All potentially long work runs on dirty schedulers.
 * Callback requests execute nested operations on the originating native thread. */
#include <erl_nif.h>
#include <pthread.h>
#include <stdatomic.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <ctype.h>
#include "clingo.h"

#ifdef CLINGO_FAULT_INJECTION
#include <unistd.h>
static pthread_once_t fault_once = PTHREAD_ONCE_INIT;
static _Atomic long fault_budget = -1;
static const char *fault_kind;
static void fault_configure(void) {
    fault_kind = getenv("CLINGO_FAIL_KIND");
    const char *value = getenv("CLINGO_FAIL_ALLOCATION");
    if (value)
        fault_budget = strtol(value, NULL, 10);
}
static int fault_fail(const char *kind) {
    pthread_once(&fault_once, fault_configure);
    if (!fault_kind || strcmp(fault_kind, kind) || fault_budget < 0)
        return 0;
    if (atomic_fetch_sub(&fault_budget, 1) != 0)
        return 0;
    const char message[] = "ALLOCATION_INJECTED\n";
    write(2, message, sizeof(message) - 1);
    return 1;
}
static void *fault_resource(ErlNifResourceType *type, size_t size) {
    return fault_fail("resource") ? NULL : enif_alloc_resource(type, size);
}
static ErlNifEnv *fault_env(void) {
    return fault_fail("env") ? NULL : enif_alloc_env();
}
#define enif_alloc_resource fault_resource
#define enif_alloc_env fault_env
#endif

/* BEAM resource allocation/publication is opaque to an instrumented NIF.
 * Model only those ownership transfers; native accesses remain instrumented. */
#ifdef __SANITIZE_THREAD__
#include <sanitizer/tsan_interface.h>
static void *tsan_resource_alloc(ErlNifResourceType *type, size_t size) {
    void *p = enif_alloc_resource(type, size);
    if (p)
        // BEAM may split/coalesce freed blocks of different resource types.
        for (size_t i = 0; i < size; i += sizeof(void *))
            __tsan_acquire((char *)p + i);
    return p;
}
static void tsan_resource_release(void *p) {
    __tsan_release(p);
    enif_release_resource(p);
}
static ERL_NIF_TERM tsan_resource_make(ErlNifEnv *e, void *p) {
    __tsan_release(p);
    return enif_make_resource(e, p);
}
static int tsan_resource_get(ErlNifEnv *e, ERL_NIF_TERM term, ErlNifResourceType *type, void **p) {
    int ok = enif_get_resource(e, term, type, p);
    if (ok)
        __tsan_acquire(*p);
    return ok;
}
#undef enif_alloc_resource
#define enif_alloc_resource tsan_resource_alloc
#define enif_release_resource tsan_resource_release
#define enif_make_resource tsan_resource_make
#define enif_get_resource tsan_resource_get
#define RESOURCE_DESTRUCTOR(name, type)                                                            \
    static void name##_tsan(ErlNifEnv *e, void *p) {                                               \
        __tsan_acquire(p);                                                                         \
        name(e, p);                                                                                \
        for (size_t i = 0; i < sizeof(type); i += sizeof(void *))                                  \
            __tsan_release((char *)p + i);                                                         \
    }
#define DESTRUCTOR(name) name##_tsan
#else
#define RESOURCE_DESTRUCTOR(name, type)
#define DESTRUCTOR(name) name
#endif

typedef enum {
    K_VOID,
    K_BOOL,
    K_SIGNED,
    K_UNSIGNED,
    K_DOUBLE,
    K_POINTER,
    K_CALLBACK,
    K_RECORD,
    K_OPAQUE,
    K_ALIAS
} Kind;
typedef struct {
    const char *name;
    int type;
    size_t offset;
    unsigned qualifiers;
} Field;
typedef struct {
    const char *name;
    Kind kind;
    size_t size;
    int target, result;
    int *args;
    int count;
    Field *fields;
    unsigned result_qualifiers;
    unsigned *qualifiers;
    int object;
} Type;
enum {
    F_REGISTER_SCRIPT = 16,
    F_FREE_CONTROL = 32,
    F_CLOSE_HANDLE = 64,
    F_RELEASE_AST = 128,
    F_ACQUIRE_AST = 256,
    F_RESUME = 512,
    F_ATOMS_EPOCH = 1024
};
/* Keep each argument's conversion and lifetime facts together. */
typedef struct {
    int type, size, string;
    unsigned qualifiers;
    int nullable, output, owned;
} Argument;
typedef struct {
    const char *name;
    void (*address)(void);
    int result, count;
    Argument *args;
    int variadic;
    unsigned result_qualifiers;
    void (*direct)(void **, void *);
    unsigned flags;
    int callback_type;
} Function;
typedef struct {
    const char *name;
    int type;
    void *address;
} Global;
typedef struct {
    const char *name;
    int64_t value;
} Constant;
#include "api.inc"
#define LEN(x) (sizeof(x) / sizeof(*(x)))
#define MAX_ARGS 64
#define INDEX_BUCKETS 1024
#ifndef CLINGO_MAX_ALLOC
#define CLINGO_MAX_ALLOC (64u * 1024u * 1024u)
#endif
#define MAX_ALLOC ((size_t)CLINGO_MAX_ALLOC)
#if !defined(__linux__) || !defined(__x86_64__)
#error "This binding currently supports Linux x86_64"
#endif

typedef struct Session Session;
typedef struct Cursor Cursor;
static void cleanup_cursors(Session *);
typedef struct {
    Session *session;
} SessionHandle;
typedef struct Node Node;
typedef struct Request Request;
typedef struct Job Job;
typedef struct Slot {
    void *address;
    Node *target, *owner;
    size_t offset;
    struct Slot *next;
    struct Slot *hash_next;
} Slot;
typedef struct Scope {
    _Atomic int active, handles, retained;
    int managed, marked;
    Session *session;
    ErlNifEnv *notifications;
    struct Scope *parent, *next;
} Scope;
static void cleanup_cursor_scope(Session *, Scope *);
static int control_has_cursor(Session *, Node *);
struct Node {
    void *data;
    int type;
    size_t count, bytes;
    int allocated;
    clingo_literal_t false_literal;
    _Atomic int readonly;
    _Atomic unsigned qualifiers;
    _Atomic int refs, valid, users, pointers;
    int marked;
    Node *work;
    _Atomic(Node *) parent, origin;
    Node *identity; /* Immutable native-object identity, shared by cast/const views. */
    Node *next, *hash_next;
    _Atomic(Scope *) scope;
};
typedef struct {
    Session *session;
    Node *node;
    size_t offset;
} Pointer;
typedef struct Closure {
    void *code;
    int type, id;
    Session *session;
    Scope *scope;
    struct Closure *next;
} Closure;
struct Session {
    SessionHandle *resource;
    Session *cleanup_next;
    pthread_mutex_t calls, nodes;
    ErlNifPid dispatcher;
    _Atomic int closed;
    _Atomic int pinned;
    _Atomic(Node *) memory;
    Scope *scopes;
    Cursor *cursors;
    _Atomic(Closure *) closures;
    Slot *slots;
    Node *node_index[INDEX_BUCKETS];
    Slot *slot_index[INDEX_BUCKETS];
    _Atomic size_t arena_used;
    size_t arena_limit;
};
typedef struct {
    Session *session;
    Scope *scope;
} ScopeHandle;
struct Job {
    Scope *region;
    ErlNifEnv *env;
    ERL_NIF_TERM operation, args, reference;
    ErlNifPid caller;
    Job *next;
};
struct Request {
    Session *session;
    pthread_mutex_t mutex;
    pthread_cond_t cond;
    Job *jobs;
    ErlNifEnv *reply_env;
    ERL_NIF_TERM reply;
    _Atomic int done;
    _Atomic int active;
    Scope *scope;
    int allocation_failed;
};
typedef struct ScriptRegistration {
    clingo_script_t api;
    void *data;
    Session *session;
    _Atomic int finalized;
    _Atomic int users;
    struct ScriptRegistration *next;
} ScriptRegistration;
static ScriptRegistration *scripts;
static pthread_mutex_t scripts_mutex = PTHREAD_MUTEX_INITIALIZER;
static _Atomic int scripts_finalized;
static _Thread_local Scope *execution_scope;
/* Conversion failures also propagate through recursive struct conversion. */
static _Thread_local int conversion_error;
static _Thread_local int tracking_slots;
static int scope_allowed(Scope *needed) {
    if (!needed)
        return 1;
    for (Scope *current = execution_scope; current; current = current->parent)
        if (current == needed)
            return 1;
    return 0;
}
static ErlNifResourceType *session_rt, *pointer_rt, *request_rt, *cursor_rt, *scope_rt;
static pthread_mutex_t cleanup_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t cleanup_cond = PTHREAD_COND_INITIALIZER;
static Session *cleanup_head, *cleanup_tail;
static pthread_t cleanup_worker;
static int cleanup_stopping, cleanup_active;
static _Atomic uint64_t call_counts[LEN(functions)];
static void counted(const char *name) {
    for (unsigned i = 0; i < LEN(functions); i++)
        if (!strcmp(name, functions[i].name)) {
            atomic_fetch_add(&call_counts[i], 1);
            return;
        }
}
static _Atomic int shutting_down;
static void mark_shutdown(void) {
    atomic_store(&shutting_down, 1);
}
static ERL_NIF_TERM a_nil, a_true, a_false, a_ok, a_error, a_badarg, a_closed, a_callback;

static ERL_NIF_TERM atom(ErlNifEnv *e, const char *s) {
    return enif_make_atom(e, s);
}
static ERL_NIF_TERM binary(ErlNifEnv *e, const char *s) {
    if (!s)
        return a_nil;
    ERL_NIF_TERM t;
    size_t n = strlen(s);
    unsigned char *p = enif_make_new_binary(e, n, &t);
    if (!p && n) {
        conversion_error = 2;
        return a_nil;
    }
    memcpy(p, s, n);
    return t;
}
static ERL_NIF_TERM failure(ErlNifEnv *e, ERL_NIF_TERM why) {
    return enif_make_tuple2(e, a_error, why);
}
static ERL_NIF_TERM out_of_memory(ErlNifEnv *e) {
    return failure(e, enif_make_tuple2(e, enif_make_int(e, clingo_error_bad_alloc),
                                       binary(e, "native allocation failed")));
}
static int name(ErlNifEnv *e, ERL_NIF_TERM t, char *out, size_t cap) {
    ErlNifBinary b;
    if (enif_get_atom(e, t, out, cap, ERL_NIF_LATIN1))
        return 1;
    if (enif_inspect_binary(e, t, &b) && b.size < cap) {
        memcpy(out, b.data, b.size);
        out[b.size] = 0;
        return 1;
    }
    return 0;
}
static int same_name(const char *a, const char *b) {
    while (*a || *b) {
        while (isspace((unsigned char)*a))
            a++;
        while (isspace((unsigned char)*b))
            b++;
        if (*a != *b)
            return 0;
        if (!*a)
            return 1;
        a++;
        b++;
    }
    return 1;
}
static int type_id(ErlNifEnv *e, ERL_NIF_TERM t) {
    char s[256];
    if (!name(e, t, s, sizeof(s)))
        return -1;
    for (unsigned i = 0; i < LEN(types); i++)
        if (same_name(s, types[i].name))
            return i;
    return -1;
}
static int resolve(int t) {
    while (types[t].kind == K_ALIAS)
        t = types[t].target;
    return t;
}
static int get_session(ErlNifEnv *e, ERL_NIF_TERM term, Session **session) {
    SessionHandle *handle;
    if (!enif_get_resource(e, term, session_rt, (void **)&handle) || !handle->session)
        return 0;
    *session = handle->session;
    return 1;
}
static int scalar_abi(int type) {
    Kind kind = types[resolve(type)].kind;
    return kind == K_VOID || kind == K_BOOL || kind == K_SIGNED || kind == K_UNSIGNED ||
           kind == K_DOUBLE || kind == K_POINTER || kind == K_CALLBACK;
}
static int valid(Node *n) {
    if (!n || !atomic_load(&n->valid))
        return 0;
    Scope *scope = atomic_load(&n->scope);
    Node *parent = atomic_load(&n->parent);
    return (n->identity == n || valid(n->identity)) && (!scope || atomic_load(&scope->active)) &&
           (!parent || valid(parent));
}
static void *arena_alloc(Session *s, size_t count, size_t size) {
    if (size && count > SIZE_MAX / size) {
        conversion_error = 2;
        return NULL;
    }
    size_t bytes = count * size, used = atomic_load(&s->arena_used);
    do {
        if (bytes > s->arena_limit - used) {
            conversion_error = 2;
            return NULL;
        }
    } while (!atomic_compare_exchange_weak(&s->arena_used, &used, used + bytes));
    void *memory = calloc(count, size);
    if (!memory) {
        atomic_fetch_sub(&s->arena_used, bytes);
        conversion_error = 2;
    }
    return memory;
}
static void arena_free(Session *s, void *memory, size_t bytes) {
    free(memory);
    atomic_fetch_sub(&s->arena_used, bytes);
}
static unsigned address_hash(const void *address) {
    uintptr_t n = (uintptr_t)address;
    return ((n >> 4) ^ (n >> 17)) & (INDEX_BUCKETS - 1);
}
static Node *node_new(Session *s, void *data, int type, size_t count, int allocated, Node *parent,
                      Scope *scope, Node *identity) {
    if (scope && scope->session != s)
        scope = NULL;
    Node *n = arena_alloc(s, 1, sizeof(*n));
    if (!n) {
        conversion_error = 2;
        return NULL;
    }
    *n = (Node){.data = data,
                .type = type,
                .count = count,
                .bytes = count == SIZE_MAX ? SIZE_MAX : count * types[resolve(type)].size,
                .allocated = allocated,
                .valid = 1,
                .parent = parent,
                .scope = scope,
                .identity = identity ? identity : n};
    pthread_mutex_lock(&s->nodes);
    n->next = s->memory;
    s->memory = n;
    unsigned bucket = address_hash(data);
    n->hash_next = s->node_index[bucket];
    s->node_index[bucket] = n;
    pthread_mutex_unlock(&s->nodes);
    return n;
}
static Node *lookup(Session *s, void *data, int type) {
    pthread_mutex_lock(&s->nodes);
    Node *n = s->node_index[address_hash(data)];
    while (n && (n->data != data || resolve(n->type) != resolve(type) || !valid(n)))
        n = n->hash_next;
    pthread_mutex_unlock(&s->nodes);
    return n;
}
/* Pointer-valued cells retain object identity, including expired generations.
 * An address reused by clingo cannot revive pointers saved in another cell. */
static int slot_set(Session *s, void *address, Node *target, size_t offset) {
    if (!tracking_slots)
        return 1;
    uintptr_t at = (uintptr_t)address;
    pthread_mutex_lock(&s->nodes);
    Node *owner = s->memory;
    while (owner && (!owner->allocated || at < (uintptr_t)owner->data ||
                     at - (uintptr_t)owner->data >= owner->bytes))
        owner = owner->next;
    if (!owner) {
        pthread_mutex_unlock(&s->nodes);
        return 1;
    }
    unsigned bucket = address_hash(address);
    Slot *slot = s->slot_index[bucket];
    while (slot && slot->address != address)
        slot = slot->hash_next;
    if (!slot) {
        /* Arena accounting is atomic; no native calls occur under this mutex. */
        slot = arena_alloc(s, 1, sizeof(*slot));
        if (!slot) {
            pthread_mutex_unlock(&s->nodes);
            conversion_error = 2;
            return 0;
        }
        slot->address = address;
        slot->owner = owner;
        slot->next = s->slots;
        s->slots = slot;
        slot->hash_next = s->slot_index[bucket];
        s->slot_index[bucket] = slot;
    }
    slot->target = target;
    slot->offset = offset;
    pthread_mutex_unlock(&s->nodes);
    return 1;
}
static int slot_get(Session *s, const void *address, Node **target, size_t *offset) {
    pthread_mutex_lock(&s->nodes);
    Slot *slot = s->slot_index[address_hash(address)];
    while (slot && slot->address != address)
        slot = slot->hash_next;
    if (slot) {
        *target = slot->target;
        *offset = slot->offset;
    }
    pthread_mutex_unlock(&s->nodes);
    return slot != NULL;
}
static Node *borrow(Session *s, void *data, int type, Node *parent, Scope *scope,
                    unsigned qualifiers) {
    Node *n = lookup(s, data, type);
    Node *identity = n && n->scope == scope ? n->identity : NULL;
    if (n && ((n->scope && n->scope != scope) || n->readonly != (int)(qualifiers & 1)))
        n = NULL;
    if (!n) {
        n = node_new(s, data, type, SIZE_MAX, 0, parent, scope, identity);
        if (n) {
            n->readonly = qualifiers & 1;
            n->qualifiers = qualifiers >> 1;
        }
    }
    return n;
}
static ERL_NIF_TERM pointer(ErlNifEnv *e, Session *s, Node *n, size_t offset) {
    if (!n) {
        conversion_error = 2;
        return a_nil;
    }
    Pointer *p = enif_alloc_resource(pointer_rt, sizeof(*p));
    if (!p) {
        conversion_error = 2;
        return a_nil;
    }
    p->session = s;
    p->node = n;
    atomic_fetch_add(&n->pointers, 1);
    p->offset = offset;
    enif_keep_resource(s->resource);
    ERL_NIF_TERM t = enif_make_resource(e, p);
    enif_release_resource(p);
    return t;
}
static int get_pointer(ErlNifEnv *e, ERL_NIF_TERM t, Session *s, Pointer **p) {
    return enif_get_resource(e, t, pointer_rt, (void **)p) && (*p)->session == s &&
           valid((*p)->node) && scope_allowed((*p)->node->scope) && !atomic_load(&s->closed);
}
static void pointer_destroy(ErlNifEnv *e, void *v) {
    (void)e;
    Pointer *p = v;
    atomic_fetch_sub(&p->node->pointers, 1);
    enif_release_resource(p->session->resource);
}
static void request_destroy(ErlNifEnv *e, void *v) {
    (void)e;
    Request *r = v;
    if (r->reply_env)
        enif_free_env(r->reply_env);
    pthread_mutex_destroy(&r->mutex);
    pthread_cond_destroy(&r->cond);
    enif_release_resource(r->session->resource);
}
/* Payloads retire immediately. Identities survive only while a pointer, saved
 * cell or live node refers to them; the sweep never allocates or calls clingo. */
static Scope *scope_new(Session *s, int managed) {
    Scope *scope = arena_alloc(s, 1, sizeof(*scope));
    if (!scope)
        return NULL;
    scope->session = s;
    if (managed) {
        scope->notifications = enif_alloc_env();
        if (!scope->notifications) {
            arena_free(s, scope, sizeof(*scope));
            conversion_error = 2;
            return NULL;
        }
    }
    scope->active = 1;
    scope->managed = managed;
    scope->parent = execution_scope && execution_scope->session == s ? execution_scope : NULL;
    pthread_mutex_lock(&s->nodes);
    scope->next = s->scopes;
    s->scopes = scope;
    pthread_mutex_unlock(&s->nodes);
    return scope;
}
static void scope_destroy(ErlNifEnv *e, void *value) {
    (void)e;
    ScopeHandle *handle = value;
    if (!handle->session)
        return;
    Scope *scope = handle->scope;
    if (!atomic_load(&scope->retained))
        atomic_store(&scope->active, 0);
    atomic_fetch_sub(&scope->handles, 1);
    enif_release_resource(handle->session->resource);
}
static int scope_get(ErlNifEnv *e, ERL_NIF_TERM term, Session *s, Scope **scope) {
    ScopeHandle *handle;
    if (!enif_get_resource(e, term, scope_rt, (void **)&handle) || handle->session != s ||
        !atomic_load(&handle->scope->active))
        return 0;
    *scope = handle->scope;
    return 1;
}
static void mark_node(Node **work, Node *node) {
    if (node && !node->marked) {
        node->marked = 1;
        node->work = *work;
        *work = node;
    }
}
static void sweep(Session *s) {
    pthread_mutex_lock(&s->nodes);
    /* Retired native payloads cannot be used even by escaped aliases. Remove
     * their slots before addresses can be reused for another allocation. */
    Slot **slot_at = &s->slots;
    while (*slot_at) {
        Slot *slot = *slot_at;
        if (slot->owner->scope && !atomic_load(&slot->owner->scope->active)) {
            *slot_at = slot->next;
            arena_free(s, slot, sizeof(*slot));
        } else
            slot_at = &slot->next;
    }
    memset(s->slot_index, 0, sizeof(s->slot_index));
    for (Slot *slot = s->slots; slot; slot = slot->next) {
        unsigned bucket = address_hash(slot->address);
        slot->hash_next = s->slot_index[bucket];
        s->slot_index[bucket] = slot;
    }
    Node *work = NULL;
    for (Node *n = s->memory; n; n = n->next) {
        n->marked = 0;
        if (n->scope && !atomic_load(&n->scope->active) && n->allocated) {
            size_t size = (n->count ? n->count : 1) * types[resolve(n->type)].size;
            arena_free(s, n->data, size);
            n->allocated = 0;
        }
    }
    for (Node *n = s->memory; n; n = n->next)
        if (!n->scope || atomic_load(&n->scope->active) || atomic_load(&n->pointers))
            mark_node(&work, n);
    for (;;) {
        while (work) {
            Node *n = work;
            work = n->work;
            mark_node(&work, n->identity);
            mark_node(&work, n->parent);
            mark_node(&work, n->origin);
        }
        for (Slot *slot = s->slots; slot; slot = slot->next)
            if (slot->owner->marked)
                mark_node(&work, slot->target);
        if (!work)
            break;
    }
    Node *head = s->memory;
    Node **at = &head;
    while (*at) {
        Node *n = *at;
        if (!n->marked) {
            *at = n->next;
            arena_free(s, n, sizeof(*n));
        } else
            at = &n->next;
    }
    s->memory = head;
    memset(s->node_index, 0, sizeof(s->node_index));
    for (Node *n = s->memory; n; n = n->next) {
        unsigned bucket = address_hash(n->data);
        n->hash_next = s->node_index[bucket];
        s->node_index[bucket] = n;
    }
    Closure *closures = s->closures;
    Closure **closure_at = &closures;
    while (*closure_at) {
        Closure *c = *closure_at;
        if (c->scope && !atomic_load(&c->scope->active)) {
            *closure_at = c->next;
            ErlNifEnv *env = c->scope->notifications;
            if (env) {
                enif_send(NULL, &s->dispatcher, env,
                          enif_make_tuple2(env, atom(env, "clingo_unregister"),
                                           enif_make_int(env, c->id)));
                enif_clear_env(env);
            }
            arena_free(s, c, sizeof(*c));
        } else
            closure_at = &c->next;
    }
    s->closures = closures;
    for (Scope *scope = s->scopes; scope; scope = scope->next) {
        scope->marked = atomic_load(&scope->active) || atomic_load(&scope->handles);
        if (!atomic_load(&scope->active) && scope->notifications) {
            enif_free_env(scope->notifications);
            scope->notifications = NULL;
        }
    }
    for (Node *n = s->memory; n; n = n->next)
        if (n->scope)
            n->scope->marked = 1;
    for (Scope *scope = s->scopes; scope; scope = scope->next)
        if (scope->marked)
            for (Scope *parent = scope->parent; parent; parent = parent->parent)
                parent->marked = 1;
    Scope **scope_at = &s->scopes;
    while (*scope_at) {
        Scope *scope = *scope_at;
        if (!scope->marked) {
            *scope_at = scope->next;
            if (scope->notifications)
                enif_free_env(scope->notifications);
            arena_free(s, scope, sizeof(*scope));
        } else
            scope_at = &scope->next;
    }
    pthread_mutex_unlock(&s->nodes);
}
static void retire_scope(Session *s, Scope *scope) {
    atomic_store(&scope->active, 0);
    sweep(s);
}
static int native_object(int t) {
    return types[resolve(t)].object;
}
static void drain(Node *n) {
    n->valid = 0;
    while (atomic_load(&n->users)) {
        struct timespec pause = {0, 1000000};
        nanosleep(&pause, NULL);
    }
}
static void cleanup_object(Node *n) {
    if (!valid(n) || !n->refs)
        return;
    drain(n);
    int k = native_object(n->type);
    if (k == 1)
        clingo_control_free(n->data);
    else if (k == 2)
        clingo_solve_handle_close(n->data);
    else if (k == 3)
        while (n->refs-- > 0)
            clingo_ast_release(n->data);
    n->refs = 0;
    n->valid = 0;
}
static void cleanup(Session *s) {
    cleanup_cursors(s);
    /* Select and pin under nodes; a raw async handle can still be dispatching
     * callbacks that sweep this list. Never hold nodes while draining clingo. */
    const int kinds[] = {2, 3, 1};
    for (unsigned i = 0; i < LEN(kinds); i++) {
        for (;;) {
            pthread_mutex_lock(&s->nodes);
            Node *n = s->memory;
            while (n && (native_object(n->type) != kinds[i] || !valid(n) || !n->refs))
                n = n->next;
            if (n)
                atomic_fetch_add(&n->pointers, 1);
            pthread_mutex_unlock(&s->nodes);
            if (!n)
                break;
            cleanup_object(n);
            atomic_fetch_sub(&n->pointers, 1);
        }
    }
}
static void dispose_buffers(Session *s) {
    if (s->pinned)
        return;
    for (Node *n = s->memory; n; n = n->next) {
        n->valid = 0;
        if (n->allocated) {
            free(n->data);
            n->data = NULL;
            n->allocated = 0;
        }
    }
}
static void dispose_session(Session *s) {
    cleanup(s);
    Node *n = s->memory;
    while (n) {
        Node *next = n->next;
        if (n->allocated)
            free(n->data);
        free(n);
        n = next;
    }
    Closure *c = s->closures;
    while (c) {
        Closure *next = c->next;
        free(c);
        c = next;
    }
    pthread_mutex_destroy(&s->nodes);
    pthread_mutex_destroy(&s->calls);
    Scope *sc = s->scopes;
    while (sc) {
        Scope *next = sc->next;
        if (sc->notifications)
            enif_free_env(sc->notifications);
        free(sc);
        sc = next;
    }
    Slot *slot = s->slots;
    while (slot) {
        Slot *next = slot->next;
        free(slot);
        slot = next;
    }
    free(s);
}
static void *cleanup_loop(void *unused) {
    (void)unused;
    pthread_mutex_lock(&cleanup_mutex);
    for (;;) {
        while (!cleanup_head && !cleanup_stopping)
            pthread_cond_wait(&cleanup_cond, &cleanup_mutex);
        if (!cleanup_head && cleanup_stopping)
            break;
        Session *s = cleanup_head;
        cleanup_head = s->cleanup_next;
        if (!cleanup_head)
            cleanup_tail = NULL;
        cleanup_active = 1;
        pthread_mutex_unlock(&cleanup_mutex);
        dispose_session(s);
        pthread_mutex_lock(&cleanup_mutex);
        cleanup_active = 0;
        pthread_cond_broadcast(&cleanup_cond);
    }
    pthread_mutex_unlock(&cleanup_mutex);
    return NULL;
}
/* The heap session already contains its queue link: no allocation, native
 * cleanup or new thread is needed on the resource destructor's scheduler. */
static void session_destroy(ErlNifEnv *e, void *v) {
    (void)e;
    Session *s = ((SessionHandle *)v)->session;
    if (!s)
        return;
    atomic_store(&s->closed, 1);
    pthread_mutex_lock(&cleanup_mutex);
    if (cleanup_tail)
        cleanup_tail->cleanup_next = s;
    else
        cleanup_head = s;
    cleanup_tail = s;
    pthread_cond_signal(&cleanup_cond);
    pthread_mutex_unlock(&cleanup_mutex);
}

static ERL_NIF_TERM create_closure(ErlNifEnv *, Session *, int, int);
static ERL_NIF_TERM execute(ErlNifEnv *, Session *, ERL_NIF_TERM, ERL_NIF_TERM, Request *, Scope *);
static int put(ErlNifEnv *, Session *, int, void *, ERL_NIF_TERM);
static ERL_NIF_TERM get(ErlNifEnv *, Session *, int, const void *, Node *, Scope *, unsigned);

static void callback(Closure *c, void *result, void **args) {
    Type *t = &types[resolve(c->type)];
    Type *rtype = &types[resolve(t->result)];
    Session *s = c->session;
    if (atomic_load(&shutting_down) || atomic_load(&s->closed)) {
        if (rtype->kind != K_VOID)
            memset(result, 0, rtype->size);
        return;
    }
    sweep(s);
    Request *r = enif_alloc_resource(request_rt, sizeof(*r));
    if (!r) {
        if (rtype->kind != K_VOID)
            memset(result, 0, rtype->size);
        clingo_set_error(clingo_error_bad_alloc, "cannot allocate callback request");
        return;
    }
    memset(r, 0, sizeof(*r));
    r->session = s;
    enif_keep_resource(s->resource);
    pthread_mutex_init(&r->mutex, NULL);
    pthread_cond_init(&r->cond, NULL);
    r->active = 1;
    r->scope = scope_new(s, 0);
    if (!r->scope) {
        enif_release_resource(r);
        if (rtype->kind != K_VOID)
            memset(result, 0, rtype->size);
        clingo_set_error(clingo_error_bad_alloc, "cannot allocate callback scope");
        return;
    }
    ErlNifEnv *e = enif_alloc_env();
    if (!e) {
        retire_scope(s, r->scope);
        enif_release_resource(r);
        if (rtype->kind != K_VOID)
            memset(result, 0, rtype->size);
        clingo_set_error(clingo_error_bad_alloc, "cannot allocate callback environment");
        return;
    }
    int previous_error = conversion_error;
    conversion_error = 0;
    ERL_NIF_TERM values[MAX_ARGS];
    for (int i = 0; i < t->count; i++)
        values[i] = get(e, s, t->args[i], args[i], NULL, r->scope, t->qualifiers[i]);
    if (conversion_error) {
        enif_free_env(e);
        retire_scope(s, r->scope);
        enif_release_resource(r);
        if (rtype->kind != K_VOID)
            memset(result, 0, rtype->size);
        clingo_set_error(conversion_error == 2 ? clingo_error_bad_alloc : clingo_error_runtime,
                         "cannot convert callback arguments");
        conversion_error = previous_error;
        return;
    }
    ERL_NIF_TERM msg =
        enif_make_tuple4(e, a_callback, enif_make_int(e, c->id), enif_make_resource(e, r),
                         enif_make_list_from_array(e, values, t->count));
    int sent = enif_send(NULL, &s->dispatcher, e, msg);
    enif_free_env(e);
    pthread_mutex_lock(&r->mutex);
    while (sent && !atomic_load(&r->done)) {
        if (r->jobs) {
            Job *j = r->jobs;
            r->jobs = j->next;
            pthread_mutex_unlock(&r->mutex);
            ERL_NIF_TERM value = execute(j->env, s, j->operation, j->args, r, j->region);
            enif_send(NULL, &j->caller, j->env,
                      enif_make_tuple3(j->env, atom(j->env, "clingo_reply"), j->reference, value));
            enif_free_env(j->env);
            free(j);
            enif_release_resource(r);
            pthread_mutex_lock(&r->mutex);
            continue;
        }
        struct timespec until;
        clock_gettime(CLOCK_REALTIME, &until);
        until.tv_sec++;
        pthread_cond_timedwait(&r->cond, &r->mutex, &until);
        if (atomic_load(&r->done) || r->jobs)
            continue;
        ErlNifEnv *check = enif_alloc_env();
        if (!check)
            r->allocation_failed = 1;
        sent = check && enif_is_process_alive(check, &s->dispatcher);
        if (check)
            enif_free_env(check);
    }
    if (rtype->kind != K_VOID) {
        memset(result, 0, rtype->size);
        if (sent && r->reply_env) {
            const ERL_NIF_TERM *tuple;
            int arity = 0;
            if (enif_get_tuple(r->reply_env, r->reply, &arity, &tuple) && arity == 2 &&
                enif_is_identical(tuple[0], a_ok)) {
                if (!put(r->reply_env, s, t->result, result, tuple[1]))
                    clingo_set_error(clingo_error_unknown, "invalid callback return value");
            } else {
                ErlNifBinary b;
                ERL_NIF_TERM message = arity == 2 ? tuple[1] : a_nil;
                int code = clingo_error_unknown, nested_arity;
                const ERL_NIF_TERM *nested;
                if (enif_get_tuple(r->reply_env, message, &nested_arity, &nested) &&
                    nested_arity == 2) {
                    int provided;
                    if (enif_get_int(r->reply_env, nested[0], &provided) && provided > 0 &&
                        provided <= clingo_error_unknown)
                        code = provided;
                    message = nested[1];
                }
                if (enif_inspect_binary(r->reply_env, message, &b) && b.size <= MAX_ALLOC) {
                    char *msg = malloc(b.size + 1);
                    if (msg) {
                        memcpy(msg, b.data, b.size);
                        msg[b.size] = 0;
                        clingo_set_error(code, msg);
                        free(msg);
                    } else
                        clingo_set_error(clingo_error_bad_alloc, "cannot copy callback error");
                } else
                    clingo_set_error(clingo_error_unknown, "Elixir callback failed");
            }
        } else
            clingo_set_error(r->allocation_failed ? clingo_error_bad_alloc : clingo_error_unknown,
                             r->allocation_failed ? "cannot allocate callback reply"
                                                  : "callback dispatcher exited");
    }
    if (rtype->kind == K_VOID && r->reply_env) {
        const ERL_NIF_TERM *reply;
        int count;
        if (enif_get_tuple(r->reply_env, r->reply, &count, &reply) && count == 2 &&
            enif_is_identical(reply[0], a_error))
            enif_send(NULL, &s->dispatcher, r->reply_env,
                      enif_make_tuple3(r->reply_env, atom(r->reply_env, "clingo_diagnostic"),
                                       binary(r->reply_env, types[c->type].name), r->reply));
    }
    while (r->jobs) {
        Job *j = r->jobs;
        r->jobs = j->next;
        enif_send(NULL, &j->caller, j->env,
                  enif_make_tuple3(j->env, atom(j->env, "clingo_reply"), j->reference,
                                   failure(j->env, a_closed)));
        enif_free_env(j->env);
        free(j);
        enif_release_resource(r);
    }
    r->active = 0;
    atomic_store(&r->done, 1);
    pthread_cond_broadcast(&r->cond);
    pthread_mutex_unlock(&r->mutex);
    /* Closing a borrowed cursor may dispatch its finish hook. Never hold the
     * parent request mutex: worker-DOWN replies also acquire it and must not
     * block the dispatcher from admitting that nested callback. */
    cleanup_cursor_scope(s, r->scope);
    if (r->reply_env) {
        enif_free_env(r->reply_env);
        r->reply_env = NULL;
    }
    retire_scope(s, r->scope);
    enif_release_resource(r);
    if (conversion_error == 2)
        clingo_set_error(clingo_error_bad_alloc, "cannot allocate callback result");
    conversion_error = previous_error;
}

typedef struct {
    void *data;
    Closure *callbacks[32];
    void (*native[32])(void);
} CallbackBundle;
static Closure *find_closure(Session *s, void *address) {
    pthread_mutex_lock(&s->nodes);
    Closure *c = s->closures;
    while (c && c->code != address)
        c = c->next;
    pthread_mutex_unlock(&s->nodes);
    return c;
}
static void *retain_bytes(Session *s, size_t size) {
    int byte = -1;
    for (unsigned i = 0; i < LEN(types); i++)
        if (!strcmp(types[i].name, "char")) {
            byte = (int)i;
            break;
        }
    if (byte < 0)
        return NULL;
    void *memory = arena_alloc(s, size, 1);
    if (!memory)
        return NULL;
    if (!node_new(s, memory, byte, size, 1, NULL,
                  execution_scope && execution_scope->session == s && execution_scope->managed
                      ? execution_scope
                      : NULL,
                  NULL)) {
        arena_free(s, memory, size);
        return NULL;
    }
    return memory;
}
static CallbackBundle *bundle_new(Session *s, void *data) {
    CallbackBundle *b = retain_bytes(s, sizeof(*b));
    if (b)
        b->data = data;
    return b;
}
#include "adapters.inc"

static int put(ErlNifEnv *e, Session *s, int ti, void *dst, ERL_NIF_TERM value) {
    Type *t = &types[resolve(ti)];
    ErlNifSInt64 sv;
    ErlNifUInt64 uv;
    double dv;
    Pointer *p;
    switch (t->kind) {
    case K_VOID:
        return enif_is_identical(value, a_nil) || enif_is_identical(value, a_ok);
    case K_BOOL:
        if (!enif_is_identical(value, a_true) && !enif_is_identical(value, a_false))
            return 0;
        *(bool *)dst = enif_is_identical(value, a_true);
        return 1;
    case K_SIGNED:
        if (!enif_get_int64(e, value, &sv))
            return 0;
        if (t->size < 8 &&
            (sv < -(1LL << (t->size * 8 - 1)) || sv > ((1LL << (t->size * 8 - 1)) - 1)))
            return 0;
        memcpy(dst, &sv, t->size);
        return 1;
    case K_UNSIGNED:
        if (!enif_get_uint64(e, value, &uv))
            return 0;
        if (t->size < 8 && uv > (((uint64_t)1 << (t->size * 8)) - 1))
            return 0;
        memcpy(dst, &uv, t->size);
        return 1;
    case K_DOUBLE:
        if (!enif_get_double(e, value, &dv)) {
            if (!enif_get_int64(e, value, &sv))
                return 0;
            dv = (double)sv;
        }
        memcpy(dst, &dv, sizeof(dv));
        return 1;
    case K_POINTER:
    case K_CALLBACK:
        if (enif_is_identical(value, a_nil)) {
            if (!slot_set(s, dst, NULL, 0))
                return 0;
            *(void **)dst = NULL;
            return 1;
        }
        if (get_pointer(e, value, s, &p)) {
            int expected = t->kind == K_CALLBACK ? resolve(ti) : resolve(t->target);
            if (types[expected].kind != K_VOID && expected != resolve(p->node->type))
                return 0;
            if (!slot_set(s, dst, p->node, p->offset))
                return 0;
            *(void **)dst = (char *)p->node->data + p->offset;
            return 1;
        }
        if (t->kind == K_POINTER && types[resolve(t->target)].kind == K_SIGNED &&
            types[resolve(t->target)].size == 1) {
            ErlNifBinary b;
            if (!enif_inspect_binary(e, value, &b) || memchr(b.data, 0, b.size) ||
                b.size > MAX_ALLOC)
                return 0;
            char *str = arena_alloc(s, b.size + 1, 1);
            if (!str) {
                conversion_error = 2;
                return 0;
            }
            memcpy(str, b.data, b.size);
            str[b.size] = 0;
            Node *n = node_new(s, str, t->target, b.size + 1, 1, NULL, execution_scope, NULL);
            if (!n) {
                arena_free(s, str, b.size + 1);
                return 0;
            }
            if (!slot_set(s, dst, n, 0))
                return 0;
            *(void **)dst = str;
            return 1;
        }
        return 0;
    case K_RECORD:
        for (int i = 0; i < t->count; i++) {
            ERL_NIF_TERM field;
            if (!enif_get_map_value(e, value, atom(e, t->fields[i].name), &field) ||
                !put(e, s, t->fields[i].type, (char *)dst + t->fields[i].offset, field))
                return 0;
        }
        return 1;
    default:
        return 0;
    }
}
static ERL_NIF_TERM get(ErlNifEnv *e, Session *s, int ti, const void *src, Node *parent,
                        Scope *scope, unsigned qualifiers) {
    Type *t = &types[resolve(ti)];
    int64_t sv = 0;
    uint64_t uv = 0;
    double dv;
    void *ptr;
    switch (t->kind) {
    case K_VOID:
        return a_ok;
    case K_BOOL:
        return *(const bool *)src ? a_true : a_false;
    case K_SIGNED:
        memcpy(&sv, src, t->size);
        if (t->size < 8 && ((uint64_t)sv & (1ULL << (t->size * 8 - 1))))
            sv |= (int64_t)(~0ULL << (t->size * 8));
        return enif_make_int64(e, sv);
    case K_UNSIGNED:
        memcpy(&uv, src, t->size);
        return enif_make_uint64(e, uv);
    case K_DOUBLE:
        memcpy(&dv, src, sizeof(dv));
        return enif_make_double(e, dv);
    case K_POINTER:
    case K_CALLBACK:
        memcpy(&ptr, src, sizeof(ptr));
        {
            int target = t->kind == K_CALLBACK ? ti : t->target;
            Node *n = NULL;
            size_t offset = 0;
            if (slot_get(s, src, &n, &offset)) {
                if ((n &&
                     (!valid(n) || !scope_allowed(n->scope) ||
                      resolve(n->type) != resolve(target) || (char *)n->data + offset != ptr)) ||
                    (!n && ptr)) {
                    conversion_error = 1;
                    return a_nil;
                }
            } else if (ptr) {
                n = borrow(s, ptr, target, parent, scope, qualifiers);
            }
            if (!ptr || !n)
                return a_nil;
            if (t->kind == K_POINTER && !strcmp(types[resolve(t->target)].name, "char"))
                return binary(e, ptr);
            return pointer(e, s, n, offset);
        }
    case K_RECORD: {
        ERL_NIF_TERM map = enif_make_new_map(e);
        for (int i = 0; i < t->count; i++) {
            Field *f = &t->fields[i];
            enif_make_map_put(
                e, map, atom(e, f->name),
                get(e, s, f->type, (const char *)src + f->offset, parent, scope, f->qualifiers),
                &map);
        }
        return map;
    }
    default:
        return a_nil;
    }
}
static ERL_NIF_TERM native_error(ErlNifEnv *e) {
    return failure(e, enif_make_tuple2(e, enif_make_int(e, clingo_error_code()),
                                       binary(e, clingo_error_message())));
}
static void invalidate_children(Session *s, Node *parent, int models_only) {
    pthread_mutex_lock(&s->nodes);
    for (Node *n = s->memory; n; n = n->next)
        if (n->parent == parent && (!models_only || native_object(n->type) == 4))
            n->valid = 0;
    pthread_mutex_unlock(&s->nodes);
}
/* clingo retains scripts globally and has no unregister operation. Keep its
 * registry valid; run user cleanup once during explicit/application shutdown. */
static bool script_active(ScriptRegistration *r) {
    atomic_fetch_add(&r->users, 1);
    if (!atomic_load(&r->finalized))
        return true;
    atomic_fetch_sub(&r->users, 1);
    clingo_set_error(clingo_error_runtime, "scripting has been finalized");
    return false;
}
static bool script_execute(clingo_location_t const *loc, char const *code, void *data) {
    ScriptRegistration *r = data;
    if (!script_active(r))
        return false;
    bool result = r->api.execute && r->api.execute(loc, code, r->data);
    atomic_fetch_sub(&r->users, 1);
    return result;
}
static bool script_call(clingo_location_t const *loc, char const *name, clingo_symbol_t const *args,
                        size_t count, clingo_symbol_callback_t cb, void *cbdata, void *data) {
    ScriptRegistration *r = data;
    if (!script_active(r))
        return false;
    bool result = r->api.call && r->api.call(loc, name, args, count, cb, cbdata, r->data);
    atomic_fetch_sub(&r->users, 1);
    return result;
}
static bool script_callable(char const *name, bool *result, void *data) {
    ScriptRegistration *r = data;
    if (!script_active(r)) {
        *result = false;
        return true;
    }
    bool success = r->api.callable && r->api.callable(name, result, r->data);
    atomic_fetch_sub(&r->users, 1);
    return success;
}
static bool script_main(clingo_control_t *control, void *data) {
    ScriptRegistration *r = data;
    if (!script_active(r))
        return false;
    bool result = r->api.main && r->api.main(control, r->data);
    atomic_fetch_sub(&r->users, 1);
    return result;
}
static void script_free(void *data) {
    ScriptRegistration *r = data;
    if (!atomic_exchange(&r->finalized, 1) && !atomic_load(&shutting_down)) {
        while (atomic_load(&r->users)) {
            struct timespec pause = {0, 1000000};
            nanosleep(&pause, NULL);
        }
        if (r->api.free)
            r->api.free(r->data);
    }
}
static ERL_NIF_TERM invoke(ErlNifEnv *e, Session *s, Function *fn, ERL_NIF_TERM arguments,
                           Request *scope) {
    (void)scope;
    unsigned count;
    if (!enif_get_list_length(e, arguments, &count) || count > MAX_ARGS ||
        count < (unsigned)fn->count || (!fn->variadic && count != (unsigned)fn->count))
        return failure(e, a_badarg);
    union {
        uint64_t u;
        int64_t i;
        double d;
        void *p;
    } storage[MAX_ARGS], ret = {0};
    void *values[MAX_ARGS];
    int tids[MAX_ARGS];
    ERL_NIF_TERM terms[MAX_ARGS], head, tail = arguments;
    Node *parent = NULL, *first_node = NULL;
    for (unsigned i = 0; i < count; i++) {
        enif_get_list_cell(e, tail, &head, &tail);
        terms[i] = head;
        Argument *arg = i < (unsigned)fn->count ? &fn->args[i] : NULL;
        tids[i] = arg ? arg->type : -1;
        if (tids[i] < 0) {
            const ERL_NIF_TERM *tuple;
            int arity = 0;
            if (!enif_get_tuple(e, head, &arity, &tuple) || arity != 2 ||
                (tids[i] = type_id(e, tuple[0])) < 0)
                return failure(e, a_badarg);
            terms[i] = tuple[1];
        }
        if (arg && !arg->string && types[resolve(tids[i])].kind == K_POINTER &&
            enif_is_binary(e, terms[i]))
            return failure(e, a_badarg);
        if (!scalar_abi(tids[i]) || !put(e, s, tids[i], &storage[i], terms[i]))
            return failure(e, a_badarg);
        values[i] = &storage[i];
        Pointer *p;
        if (arg && get_pointer(e, terms[i], s, &p) && p->node->readonly && !(arg->qualifiers & 1) &&
            types[resolve(tids[i])].kind == K_POINTER &&
            types[resolve(types[resolve(tids[i])].target)].kind != K_VOID)
            return failure(e, a_badarg);
        if (i == 0 && get_pointer(e, terms[i], s, &p)) {
            first_node = p->node;
            parent = native_object(p->node->type) ? p->node->identity : p->node;
        }
    }
    /* Refuse NULL required pointers and arrays larger than our owned buffers. */
    for (unsigned i = 0; i < count; i++) {
        Type *t = &types[resolve(tids[i])];
        if (i >= (unsigned)fn->count)
            continue;
        if (t->kind != K_POINTER && t->kind != K_CALLBACK)
            continue;
        Argument *arg = &fn->args[i];
        int array = arg->size >= 0 && types[resolve(tids[arg->size])].kind == K_UNSIGNED &&
                    types[resolve(tids[arg->size])].size == sizeof(size_t);
        if (!storage[i].p) {
            int optional = arg->nullable || (array && storage[arg->size].u == 0);
            if (!optional)
                return failure(e, a_badarg);
        } else if (array) {
            Pointer *p;
            if (get_pointer(e, terms[i], s, &p) && p->node->bytes != SIZE_MAX) {
                size_t item = types[resolve(t->target)].size;
                if (item && storage[arg->size].u > (p->node->bytes - p->offset) / item)
                    return failure(e, a_badarg);
            }
        }
    }
    if (parent && (fn->flags & (F_FREE_CONTROL | F_RELEASE_AST | F_CLOSE_HANDLE)) && !parent->refs)
        return failure(e, a_badarg);
    if (parent && (fn->flags & F_FREE_CONTROL)) {
        pthread_mutex_lock(&s->nodes);
        int has_handle = 0;
        for (Node *n = s->memory; n; n = n->next)
            if (n->parent == parent && valid(n) && native_object(n->type) == 2 && n->refs) {
                has_handle = 1;
                break;
            }
        pthread_mutex_unlock(&s->nodes);
        if (has_handle)
            return failure(e, a_badarg);
    }
    /* Validate variadic AST constructor contracts against
       clingo's own exported constructor table before invoking the variadic API. */
    if (fn->variadic) {
        int kind = (int)storage[0].i;
        if (kind < 0 || (size_t)kind >= g_clingo_ast_constructors.size)
            return failure(e, a_badarg);
        clingo_ast_constructor_t const *ctor = &g_clingo_ast_constructors.constructors[kind];
        unsigned at = 2;
        for (size_t j = 0; j < ctor->size; j++) {
            int attr = ctor->arguments[j].type;
            int expected = -1;
            for (unsigned k = 0; k < LEN(types); k++) {
                const char *n = types[k].name;
                if ((attr == clingo_ast_attribute_type_number && !strcmp(n, "int")) ||
                    (attr == clingo_ast_attribute_type_symbol && !strcmp(n, "clingo_symbol_t")) ||
                    (attr == clingo_ast_attribute_type_location &&
                     !strcmp(n, "clingo_location_t*")) ||
                    (attr == clingo_ast_attribute_type_string && !strcmp(n, "char*")) ||
                    ((attr == clingo_ast_attribute_type_ast ||
                      attr == clingo_ast_attribute_type_optional_ast) &&
                     !strcmp(n, "clingo_ast_t*")) ||
                    (attr == clingo_ast_attribute_type_string_array && !strcmp(n, "char**")) ||
                    (attr == clingo_ast_attribute_type_ast_array && !strcmp(n, "clingo_ast_t**")))
                    expected = k;
            }
            if (at >= count || expected < 0 || resolve(tids[at]) != resolve(expected))
                return failure(e, a_badarg);
            unsigned index = at++;
            if (attr == clingo_ast_attribute_type_string_array ||
                attr == clingo_ast_attribute_type_ast_array) {
                if (at >= count || types[resolve(tids[at])].kind != K_UNSIGNED ||
                    types[resolve(tids[at])].size != sizeof(size_t))
                    return failure(e, a_badarg);
                uint64_t length = storage[at++].u;
                Pointer *p;
                if (!storage[index].p && length)
                    return failure(e, a_badarg);
                if (get_pointer(e, terms[index], s, &p) && p->node->bytes != SIZE_MAX &&
                    length > (p->node->bytes - p->offset) / sizeof(void *))
                    return failure(e, a_badarg);
            } else if ((types[resolve(tids[index])].kind == K_POINTER ||
                        types[resolve(tids[index])].kind == K_CALLBACK) &&
                       !storage[index].p && attr != clingo_ast_attribute_type_optional_ast)
                return failure(e, a_badarg);
        }
        if (at != count)
            return failure(e, a_badarg);
    }
    if (parent && ((fn->flags & F_FREE_CONTROL) || (fn->flags & F_CLOSE_HANDLE))) {
        if ((fn->flags & F_FREE_CONTROL) && control_has_cursor(s, parent))
            return failure(e, atom(e, "solve_active"));
        drain(parent);
    }
    if (conversion_error)
        return conversion_error == 2 ? out_of_memory(e) : failure(e, a_badarg);
    if (!adapt_callbacks(s, fn, values))
        return out_of_memory(e);

    /* Each call owns its diagnostics. A predicate's false return must not
     * inherit an earlier native error on this dirty scheduler thread. */
    clingo_set_error(clingo_error_success, NULL);
    ScriptRegistration *registration = NULL;
    clingo_script_t adapted;
    if ((fn->flags & F_REGISTER_SCRIPT)) {
        if (!storage[1].p)
            return failure(e, a_closed);
        registration = calloc(1, sizeof(*registration));
        if (!registration)
            return out_of_memory(e);
        registration->api = *(clingo_script_t *)storage[1].p;
        registration->data = storage[2].p;
        registration->session = s;
        adapted = (clingo_script_t){script_execute, script_call, script_callable,
                                    script_main,    script_free, registration->api.version};
        storage[1].p = &adapted;
        storage[2].p = registration;
        /* Registration makes no user callbacks. Publish it atomically with the
         * finalization transition, always taking calls before scripts_mutex. */
        pthread_mutex_lock(&scripts_mutex);
        if (atomic_load(&scripts_finalized)) {
            pthread_mutex_unlock(&scripts_mutex);
            free(registration);
            return failure(e, a_closed);
        }
    }
    counted(fn->name);
    if (fn->direct)
        fn->direct(values, &ret);
    else if (fn->variadic)
        call_ast(values, &ret);
    else {
        Closure *c = find_closure(s, (void *)fn->address);
        if (c)
            callback(c, &ret, values);
        else if (!call_typed(fn->callback_type, fn->address, values, &ret))
            return failure(e, a_badarg);
    }
    if (registration) {
        if (ret.u) {
            registration->next = scripts;
            scripts = registration;
            if (!s->pinned) {
                s->pinned = 1;
                enif_keep_resource(s->resource);
                atexit(mark_shutdown);
            }
        } else
            free(registration);
        pthread_mutex_unlock(&scripts_mutex);
    }
    if (types[resolve(fn->result)].kind == K_BOOL && !ret.u &&
        clingo_error_code() != clingo_error_success)
        return native_error(e);
    /* Bind each output cell to this generation before the caller can read it. */
    for (unsigned i = 0; i < count; i++) {
        Type *a = &types[resolve(tids[i])];
        Pointer *p;
        if (a->kind == K_POINTER && get_pointer(e, terms[i], s, &p)) {
            if (i > 0 && parent && p->node->allocated)
                p->node->origin = parent;
            Type *b = &types[resolve(a->target)];
            Argument *arg = i < (unsigned)fn->count ? &fn->args[i] : NULL;
            if (arg && arg->output && b->kind == K_POINTER && storage[i].p) {
                void *obj = *(void **)storage[i].p;
                if (obj) {
                    int owned = arg->owned;
                    Node *n = borrow(s, obj, b->target,
                                     owned && native_object(b->target) == 3 ? NULL : parent,
                                     owned ? NULL : execution_scope, arg->qualifiers >> 1);
                    if (n && owned) {
                        n->identity->refs++;
                        if (native_object(b->target) == 3) {
                            n->scope = NULL;
                            n->parent = NULL;
                            n->identity->scope = NULL;
                            n->identity->parent = NULL;
                        }
                    }
                    tracking_slots = 1;
                    if (!n || !slot_set(s, storage[i].p, n, 0)) {
                        /* Rollback needs no allocation, even when a previous slot
                         * identity exists. Never leave a freed address in a cell. */
                        *(void **)storage[i].p = NULL;
                        pthread_mutex_lock(&s->nodes);
                        Slot *slot = s->slot_index[address_hash(storage[i].p)];
                        while (slot && slot->address != storage[i].p)
                            slot = slot->hash_next;
                        if (slot) {
                            slot->target = NULL;
                            slot->offset = 0;
                        }
                        pthread_mutex_unlock(&s->nodes);
                        if (owned) {
                            if (n) {
                                n->identity->refs--;
                                if (!n->identity->refs)
                                    drain(n->identity);
                            }
                            int kind = native_object(b->target);
                            if (kind == 1)
                                clingo_control_free(obj);
                            else if (kind == 2)
                                clingo_solve_handle_close(obj);
                            else
                                clingo_ast_release(obj);
                        }
                    }
                } else {
                    tracking_slots = 1;
                    slot_set(s, storage[i].p, NULL, 0);
                }
                tracking_slots = 0;
            }
        }
    }
    if (parent) {
        if ((fn->flags & F_FREE_CONTROL) || (fn->flags & F_CLOSE_HANDLE)) {
            parent->refs = 0;
            parent->valid = 0;
            invalidate_children(s, parent, 0);
        }
        if ((fn->flags & F_RELEASE_AST)) {
            if (parent->refs > 0)
                parent->refs--;
            if (!parent->refs)
                parent->valid = 0;
        }
        if ((fn->flags & F_ACQUIRE_AST)) {
            first_node->scope = NULL;
            first_node->parent = NULL;
            parent->scope = NULL;
            parent->parent = NULL;
            parent->refs++;
        }
        if ((fn->flags & F_RESUME))
            invalidate_children(s, parent, 1);
        if ((fn->flags & F_ATOMS_EPOCH)) {
            pthread_mutex_lock(&s->nodes);
            for (Node *n = s->memory; n; n = n->next)
                if (n->parent == parent &&
                    (native_object(n->type) == 5 || native_object(n->type) == 6))
                    n->valid = 0;
            pthread_mutex_unlock(&s->nodes);
        }
    }
    return enif_make_tuple2(
        e, a_ok, get(e, s, fn->result, &ret, parent, execution_scope, fn->result_qualifiers));
}

#include "values.inc"

static ERL_NIF_TERM execute_impl(ErlNifEnv *, Session *, ERL_NIF_TERM, ERL_NIF_TERM, Request *);
static ERL_NIF_TERM execute(ErlNifEnv *e, Session *s, ERL_NIF_TERM operation,
                            ERL_NIF_TERM arguments, Request *scope, Scope *region) {
    Scope *previous = execution_scope;
    int previous_error = conversion_error;
    int previous_tracking = tracking_slots;
    conversion_error = 0;
    tracking_slots = 0;
    execution_scope = region ? region : scope ? scope->scope : NULL;
    ERL_NIF_TERM result = region && !atomic_load(&region->active)
                              ? failure(e, a_closed)
                              : execute_impl(e, s, operation, arguments, scope);
    if (conversion_error)
        result = conversion_error == 2 ? out_of_memory(e) : failure(e, a_badarg);
    conversion_error = previous_error;
    tracking_slots = previous_tracking;
    execution_scope = previous;
    return result;
}
static ERL_NIF_TERM execute_impl(ErlNifEnv *e, Session *s, ERL_NIF_TERM operation,
                                 ERL_NIF_TERM arguments, Request *scope) {
    if (atomic_load(&s->closed))
        return failure(e, a_closed);
    char op[128];
    if (!name(e, operation, op, sizeof(op)))
        return failure(e, a_badarg);
    for (unsigned i = 0; i < LEN(functions); i++)
        if (!strcmp(op, functions[i].name))
            return invoke(e, s, &functions[i], arguments, scope);
    const ERL_NIF_TERM *args;
    int argc;
    if (!enif_get_tuple(e, arguments, &argc, &args))
        return failure(e, a_badarg);
    if (!strcmp(op, "scope_open") && argc == 0) {
        ScopeHandle *handle = enif_alloc_resource(scope_rt, sizeof(*handle));
        if (!handle)
            return out_of_memory(e);
        Scope *region = scope_new(s, 1);
        if (!region) {
            /* An uninitialized resource must not run the regular destructor. */
            handle->session = NULL;
            enif_release_resource(handle);
            return out_of_memory(e);
        }
        region->handles = 1;
        handle->session = s;
        handle->scope = region;
        enif_keep_resource(s->resource);
        ERL_NIF_TERM term = enif_make_resource(e, handle);
        enif_release_resource(handle);
        return enif_make_tuple2(e, a_ok, term);
    }
    if (!strcmp(op, "scope_close") && argc == 1) {
        ScopeHandle *handle;
        if (!enif_get_resource(e, args[0], scope_rt, (void **)&handle) || handle->session != s)
            return failure(e, a_badarg);
        if (!atomic_load(&handle->scope->retained))
            retire_scope(s, handle->scope);
        return enif_make_tuple2(e, a_ok, a_ok);
    }
    if (!strncmp(op, "values_", 7))
        return values(e, s, op, argc, args);
    if (!strcmp(op, "callback_new") && argc == 2) {
        int ti = type_id(e, args[0]), id;
        if (ti < 0 || !enif_get_int(e, args[1], &id) || types[resolve(ti)].kind != K_CALLBACK)
            return failure(e, a_badarg);
        return create_closure(e, s, ti, id);
    }
    if (!strcmp(op, "alloc") && argc == 2) {
        int ti = type_id(e, args[0]);
        ErlNifUInt64 count;
        if (ti < 0 || !types[resolve(ti)].size || !enif_get_uint64(e, args[1], &count) ||
            count > MAX_ALLOC / types[resolve(ti)].size)
            return failure(e, a_badarg);
        void *mem = arena_alloc(s, count ? count : 1, types[resolve(ti)].size);
        if (!mem)
            return out_of_memory(e);
        Node *n = node_new(s, mem, ti, count, 1, NULL, execution_scope, NULL);
        if (!n) {
            arena_free(s, mem, (count ? count : 1) * types[resolve(ti)].size);
            return out_of_memory(e);
        }
        return enif_make_tuple2(e, a_ok, pointer(e, s, n, 0));
    }
    if (!strcmp(op, "array_new") && argc == 2) {
        unsigned count;
        if (!enif_get_list_length(e, args[1], &count))
            return failure(e, a_badarg);
        ERL_NIF_TERM allocation = execute_impl(
            e, s, atom(e, "alloc"), enif_make_tuple2(e, args[0], enif_make_uint(e, count)), scope);
        const ERL_NIF_TERM *tuple;
        int arity;
        if (!enif_get_tuple(e, allocation, &arity, &tuple) || arity != 2 ||
            !enif_is_identical(tuple[0], a_ok))
            return allocation;
        Pointer *p;
        if (!get_pointer(e, tuple[1], s, &p))
            return failure(e, a_badarg);
        size_t size = types[resolve(p->node->type)].size;
        ERL_NIF_TERM head, tail = args[1];
        tracking_slots = 1;
        for (unsigned i = 0; i < count; i++) {
            enif_get_list_cell(e, tail, &head, &tail);
            if (!put(e, s, p->node->type, (char *)p->node->data + i * size, head))
                return failure(e, a_badarg);
        }
        return allocation;
    }
    if (!strcmp(op, "global") && argc == 1) {
        char g[128];
        if (!name(e, args[0], g, sizeof(g)))
            return failure(e, a_badarg);
        for (unsigned i = 0; i < LEN(globals); i++)
            if (!strcmp(g, globals[i].name)) {
                Node *n = node_new(s, globals[i].address, globals[i].type, 1, 0, NULL, NULL, NULL);
                if (!n)
                    return out_of_memory(e);
                n->readonly = 1;
                return enif_make_tuple2(e, a_ok, pointer(e, s, n, 0));
            }
        return failure(e, a_badarg);
    }
    if (!strcmp(op, "memory") && argc == 0)
        return enif_make_tuple2(e, a_ok,
                                enif_make_tuple2(e,
                                                 enif_make_uint64(e, atomic_load(&s->arena_used)),
                                                 enif_make_uint64(e, s->arena_limit)));
    Pointer *p;
    if (argc < 1 || !get_pointer(e, args[0], s, &p))
        return failure(e, a_badarg);
    Node *n = p->node;
    if (!strcmp(op, "read_array") && argc == 2) {
        ErlNifUInt64 count;
        size_t size = types[resolve(n->type)].size;
        if (!size || !enif_get_uint64(e, args[1], &count) || count > n->count ||
            count > MAX_ALLOC / size)
            return failure(e, a_badarg);
        ERL_NIF_TERM values = enif_make_list(e, 0);
        for (size_t i = count; i > 0; i--) {
            ERL_NIF_TERM value = get(e, s, n->type, (char *)n->data + p->offset + (i - 1) * size,
                                     n->allocated ? n->origin : n, n->scope, n->qualifiers);
            values = enif_make_list_cell(e, value, values);
        }
        return enif_make_tuple2(e, a_ok, values);
    }
    if (!strcmp(op, "write_array") && argc == 3) {
        unsigned count;
        ErlNifUInt64 index;
        size_t size = types[resolve(n->type)].size;
        if (n->readonly || !size || !enif_get_list_length(e, args[1], &count) ||
            !enif_get_uint64(e, args[2], &index) || index > n->count || count > n->count - index ||
            count > MAX_ALLOC / size)
            return failure(e, a_badarg);
        ERL_NIF_TERM head, tail = args[1];
        tracking_slots = 1;
        for (unsigned i = 0; i < count; i++) {
            enif_get_list_cell(e, tail, &head, &tail);
            if (!put(e, s, n->type, (char *)n->data + p->offset + (index + i) * size, head))
                return failure(e, a_badarg);
        }
        return enif_make_tuple2(e, a_ok, a_ok);
    }
    if (!strcmp(op, "read") && argc == 2) {
        ErlNifUInt64 index;
        size_t size = types[resolve(n->type)].size;
        if (!size || !enif_get_uint64(e, args[1], &index) || index >= n->count ||
            index > (SIZE_MAX - p->offset) / size)
            return failure(e, a_badarg);
        return enif_make_tuple2(e, a_ok,
                                get(e, s, n->type, (char *)n->data + p->offset + index * size,
                                    n->allocated ? n->origin : n, n->scope, n->qualifiers));
    }
    if (!strcmp(op, "write") && argc == 3) {
        if (n->readonly)
            return failure(e, a_badarg);
        ErlNifUInt64 index;
        size_t size = types[resolve(n->type)].size;
        tracking_slots = 1;
        if (!size || !enif_get_uint64(e, args[1], &index) || index >= n->count ||
            index > (SIZE_MAX - p->offset) / size ||
            !put(e, s, n->type, (char *)n->data + p->offset + index * size, args[2]))
            return failure(e, a_badarg);
        return enif_make_tuple2(e, a_ok, a_ok);
    }
    if (!strcmp(op, "cast") && argc == 3) {
        int ti = type_id(e, args[1]);
        ErlNifUInt64 count;
        if (ti < 0 || !enif_get_uint64(e, args[2], &count) ||
            (types[resolve(ti)].size ? count > MAX_ALLOC / types[resolve(ti)].size : count != 1) ||
            (n->bytes != SIZE_MAX &&
             (p->offset > n->bytes || count * types[resolve(ti)].size > n->bytes - p->offset)))
            return failure(e, a_badarg);
        Node *view =
            node_new(s, (char *)n->data + p->offset, ti, count, 0, n, n->scope, n->identity);
        if (!view)
            return out_of_memory(e);
        view->readonly = n->readonly;
        view->qualifiers = n->qualifiers;
        return enif_make_tuple2(e, a_ok, pointer(e, s, view, 0));
    }
    if (!strcmp(op, "string") && argc == 2) {
        ErlNifUInt64 max;
        if (!enif_get_uint64(e, args[1], &max) || max > MAX_ALLOC ||
            (n->bytes != SIZE_MAX && max > n->bytes - p->offset))
            return failure(e, a_badarg);
        size_t len = strnlen((char *)n->data + p->offset, max);
        ERL_NIF_TERM value;
        unsigned char *data = enif_make_new_binary(e, len, &value);
        if (!data && len)
            return out_of_memory(e);
        memcpy(data, (char *)n->data + p->offset, len);
        return enif_make_tuple2(e, a_ok, value);
    }
    if (!strcmp(op, "call_pointer") && argc == 2) {
        Type *t = &types[resolve(n->type)];
        if (t->kind != K_CALLBACK)
            return failure(e, a_badarg);
        Argument arguments[MAX_ARGS];
        for (int i = 0; i < t->count; i++) {
            Type *arg = &types[resolve(t->args[i])];
            arguments[i] = (Argument){
                .type = t->args[i],
                .size = -1,
                .string = 1,
                .qualifiers = t->qualifiers[i],
                .nullable = arg->kind == K_CALLBACK ||
                            (arg->kind == K_POINTER && types[resolve(arg->target)].kind == K_VOID)};
        }
        Function f = {.name = "native_callback",
                      .address = (void (*)(void))n->data,
                      .result = t->result,
                      .count = t->count,
                      .args = arguments,
                      .result_qualifiers = t->result_qualifiers,
                      .callback_type = resolve(n->type)};
        return invoke(e, s, &f, args[1], scope);
    }
    return failure(e, a_badarg);
}

static ERL_NIF_TERM open_nif(ErlNifEnv *e, int argc, const ERL_NIF_TERM args[]) {
    (void)argc;
    ErlNifPid pid;
    if (!enif_get_local_pid(e, args[0], &pid))
        return enif_make_badarg(e);
    SessionHandle *handle = enif_alloc_resource(session_rt, sizeof(*handle));
    if (!handle)
        return enif_raise_exception(e, atom(e, "enomem"));
    handle->session = NULL;
    Session *s = calloc(1, sizeof(*s));
    if (!s) {
        enif_release_resource(handle);
        return enif_raise_exception(e, atom(e, "enomem"));
    }
    handle->session = s;
    s->resource = handle;
    ErlNifUInt64 limit = 256u * 1024u * 1024u;
    if (argc == 2 && (!enif_get_uint64(e, args[1], &limit) || limit < sizeof(*s))) {
        handle->session = NULL;
        free(s);
        enif_release_resource(handle);
        return enif_make_badarg(e);
    }
    s->arena_limit = limit;
    atomic_store(&s->arena_used, sizeof(*s));
    s->dispatcher = pid;
    pthread_mutex_init(&s->calls, NULL);
    pthread_mutex_init(&s->nodes, NULL);
    ERL_NIF_TERM term = enif_make_resource(e, handle);
    enif_release_resource(handle);
    return term;
}
static ERL_NIF_TERM run_nif(ErlNifEnv *e, int argc, const ERL_NIF_TERM args[]) {
    Session *s;
    if (!get_session(e, args[0], &s))
        return failure(e, a_badarg);
    pthread_mutex_lock(&s->calls);
    char operation[128];
    if (name(e, args[1], operation, sizeof(operation)) &&
        (!strcmp(operation, "memory") || !strcmp(operation, "scope_open")))
        sweep(s);
    Scope *region = NULL;
    ERL_NIF_TERM ret = argc == 4 && !scope_get(e, args[3], s, &region)
                           ? failure(e, a_closed)
                           : execute(e, s, args[1], args[2], NULL, region);
    pthread_mutex_unlock(&s->calls);
    return ret;
}
/* Ordinary schedulers only transport bounded terms. Refcounted binaries are
 * shared by enif_make_copy; large bulk lists are chunked in Elixir instead. */
static int transport_term(ErlNifEnv *e, ERL_NIF_TERM term, unsigned *left, unsigned depth) {
    if (!*left || depth > 32)
        return 0;
    --*left;
    ERL_NIF_TERM head, tail;
    const ERL_NIF_TERM *tuple;
    int arity;
    ErlNifSInt64 integer;
    ErlNifUInt64 unsigned_integer;
    double real;
    if (enif_get_list_cell(e, term, &head, &tail)) {
        do {
            if (!transport_term(e, head, left, depth + 1) || !*left)
                return 0;
            --*left;
            term = tail;
        } while (enif_get_list_cell(e, term, &head, &tail));
        return enif_is_empty_list(e, term);
    }
    if (enif_get_tuple(e, term, &arity, &tuple)) {
        if ((unsigned)arity > *left)
            return 0;
        for (int i = 0; i < arity; i++)
            if (!transport_term(e, tuple[i], left, depth + 1))
                return 0;
        return 1;
    }
    if (enif_is_map(e, term)) {
        size_t size;
        if (!enif_get_map_size(e, term, &size) || size > *left / 2)
            return 0;
        ErlNifMapIterator iterator;
        if (!enif_map_iterator_create(e, term, &iterator, ERL_NIF_MAP_ITERATOR_FIRST))
            return 0;
        int valid = 1;
        while (enif_map_iterator_get_pair(e, &iterator, &head, &tail)) {
            if (!transport_term(e, head, left, depth + 1) ||
                !transport_term(e, tail, left, depth + 1)) {
                valid = 0;
                break;
            }
            enif_map_iterator_next(e, &iterator);
        }
        enif_map_iterator_destroy(e, &iterator);
        return valid;
    }
    return enif_is_atom(e, term) || enif_is_binary(e, term) || enif_is_ref(e, term) ||
           enif_is_pid(e, term) || enif_is_empty_list(e, term) ||
           enif_get_int64(e, term, &integer) || enif_get_uint64(e, term, &unsigned_integer) ||
           enif_get_double(e, term, &real);
}
static int transport_allowed(ErlNifEnv *e, ERL_NIF_TERM term) {
    unsigned budget = 4096;
    return transport_term(e, term, &budget, 0);
}
static ERL_NIF_TERM nested_nif(ErlNifEnv *e, int argc, const ERL_NIF_TERM args[]) {
    (void)argc;
    Request *r;
    Session *s;
    if (!get_session(e, args[0], &s) || !enif_get_resource(e, args[1], request_rt, (void **)&r) ||
        r->session != s)
        return failure(e, a_badarg);
    if (!transport_allowed(e, args[2]) || !transport_allowed(e, args[3]))
        return failure(e, atom(e, "transport_limit"));
    Scope *region = NULL;
    if (argc == 5 && !scope_get(e, args[4], s, &region))
        return failure(e, a_closed);
    Job *j = calloc(1, sizeof(*j));
    if (!j)
        return out_of_memory(e);
    j->env = enif_alloc_env();
    if (!j->env) {
        free(j);
        return out_of_memory(e);
    }
    j->region = region;
    if (argc == 5)
        enif_make_copy(j->env, args[4]);
    j->operation = enif_make_copy(j->env, args[2]);
    j->args = enif_make_copy(j->env, args[3]);
    ERL_NIF_TERM ref = enif_make_ref(e);
    j->reference = enif_make_copy(j->env, ref);
    enif_self(e, &j->caller);
    pthread_mutex_lock(&r->mutex);
    if (!r->active || atomic_load(&r->done)) {
        pthread_mutex_unlock(&r->mutex);
        enif_free_env(j->env);
        free(j);
        return failure(e, a_closed);
    }
    enif_keep_resource(r);
    Job **tail = &r->jobs;
    while (*tail)
        tail = &(*tail)->next;
    *tail = j;
    pthread_cond_broadcast(&r->cond);
    pthread_mutex_unlock(&r->mutex);
    return enif_make_tuple2(e, atom(e, "pending"), ref);
}
static ERL_NIF_TERM reply_nif(ErlNifEnv *e, int argc, const ERL_NIF_TERM args[]) {
    (void)argc;
    Request *r;
    if (!enif_get_resource(e, args[0], request_rt, (void **)&r))
        return enif_make_badarg(e);
    pthread_mutex_lock(&r->mutex);
    if (r->active && !atomic_load(&r->done)) {
        r->reply_env = enif_alloc_env();
        if (!r->reply_env) {
            r->allocation_failed = 1;
            atomic_store(&r->done, 1);
            pthread_cond_broadcast(&r->cond);
            pthread_mutex_unlock(&r->mutex);
            return out_of_memory(e);
        }
        r->reply =
            transport_allowed(e, args[1])
                ? enif_make_copy(r->reply_env, args[1])
                : enif_make_tuple2(r->reply_env, a_error,
                                   binary(r->reply_env, "callback transport limit exceeded"));
        atomic_store(&r->done, 1);
        pthread_cond_broadcast(&r->cond);
    }
    pthread_mutex_unlock(&r->mutex);
    return a_ok;
}
static ERL_NIF_TERM close_nif(ErlNifEnv *e, int argc, const ERL_NIF_TERM args[]) {
    (void)argc;
    Session *s;
    if (!get_session(e, args[0], &s))
        return enif_make_badarg(e);
    pthread_mutex_lock(&s->calls);
    if (s->pinned && !atomic_load(&s->closed)) {
        pthread_mutex_unlock(&s->calls);
        return failure(e, atom(e, "global_lifetime"));
    }
    if (!atomic_load(&s->closed)) {
        cleanup(s);
        atomic_store(&s->closed, 1);
        dispose_buffers(s);
    }
    pthread_mutex_unlock(&s->calls);
    return a_ok;
}
static ERL_NIF_TERM create_closure(ErlNifEnv *e, Session *s, int ti, int id) {
    Closure *c = arena_alloc(s, 1, sizeof(*c));
    if (!c)
        return out_of_memory(e);
    c->type = ti;
    c->id = id;
    c->session = s;
    c->scope = execution_scope && execution_scope->session == s && execution_scope->managed
                   ? execution_scope
                   : NULL;
    c->code = c; /* Typed descriptor; registration supplies a static C trampoline. */
    pthread_mutex_lock(&s->nodes);
    c->next = s->closures;
    s->closures = c;
    pthread_mutex_unlock(&s->nodes);
    Node *n = node_new(s, c->code, ti, 1, 0, NULL, c->scope, NULL);
    ERL_NIF_TERM result = enif_make_tuple2(e, a_ok, pointer(e, s, n, 0));
    return result;
}
/* Interrupt is documented thread-safe by clingo, and must bypass the call lock. */
static ERL_NIF_TERM asynchronous(ErlNifEnv *e, ERL_NIF_TERM term, int cancel) {
    Pointer *p;
    if (!enif_get_resource(e, term, pointer_rt, (void **)&p))
        return failure(e, a_badarg);
    Node *view = p->node;
    Node *n = view->identity;
    atomic_fetch_add(&n->users, 1);
    if (view->scope || n->scope || !valid(view) || atomic_load(&p->session->closed) ||
        strcmp(types[resolve(n->type)].name,
               cancel ? "struct clingo_solve_handle" : "struct clingo_control")) {
        atomic_fetch_sub(&n->users, 1);
        return failure(e, a_badarg);
    }
    counted(cancel ? "clingo_solve_handle_cancel" : "clingo_control_interrupt");
    bool success = true;
    if (cancel)
        success = clingo_solve_handle_cancel(n->data);
    else
        clingo_control_interrupt(n->data);
    ERL_NIF_TERM result =
        success ? enif_make_tuple2(e, a_ok, cancel ? a_true : a_ok) : native_error(e);
    atomic_fetch_sub(&n->users, 1);
    return result;
}
static ERL_NIF_TERM interrupt_nif(ErlNifEnv *e, int argc, const ERL_NIF_TERM args[]) {
    Pointer *p;
    Session *s;
    if (argc == 2 && (!get_session(e, args[0], &s) ||
                      !enif_get_resource(e, args[1], pointer_rt, (void **)&p) || p->session != s))
        return failure(e, a_badarg);
    return asynchronous(e, args[argc - 1], 0);
}
/* Signal through the thread-safe control API, then serialize handle draining
 * with model copying and close. Never wait for calls while retaining a user
 * count: close holds calls while draining those users. */
static ERL_NIF_TERM cancel_nif(ErlNifEnv *e, int argc, const ERL_NIF_TERM args[]) {
    Pointer *p;
    Session *s;
    Cursor *cursor;
    (void)argc;
    if (!get_session(e, args[0], &s))
        return failure(e, a_badarg);
    if (enif_get_resource(e, args[1], cursor_rt, (void **)&cursor)) {
        if (cursor->session != s)
            return failure(e, a_badarg);
        atomic_fetch_add(&cursor->users, 1);
        if (atomic_load(&cursor->closed) || atomic_load(&s->closed)) {
            atomic_fetch_sub(&cursor->users, 1);
            return failure(e, a_closed);
        }
        clingo_control_interrupt(cursor->control->data);
        atomic_fetch_sub(&cursor->users, 1);
        pthread_mutex_lock(&s->calls);
        ERL_NIF_TERM result;
        if (atomic_load(&cursor->closed) || atomic_load(&s->closed))
            result = failure(e, a_closed);
        else
            result =
                clingo_solve_handle_cancel(cursor->handle) ? value_ok(e, a_ok) : native_error(e);
        pthread_mutex_unlock(&s->calls);
        return result;
    }
    if (!enif_get_resource(e, args[1], pointer_rt, (void **)&p) || p->session != s)
        return failure(e, a_badarg);
    Node *view = p->node, *n = view->identity;
    atomic_fetch_add(&n->users, 1);
    Node *control = atomic_load(&n->parent);
    if (view->scope || n->scope || !valid(view) || atomic_load(&s->closed) ||
        strcmp(types[resolve(n->type)].name, "struct clingo_solve_handle") || !control ||
        native_object(control->type) != 1 || !valid(control)) {
        atomic_fetch_sub(&n->users, 1);
        return failure(e, a_badarg);
    }
    clingo_control_interrupt(control->data);
    atomic_fetch_sub(&n->users, 1);
    pthread_mutex_lock(&s->calls);
    ERL_NIF_TERM result = asynchronous(e, args[1], 1);
    pthread_mutex_unlock(&s->calls);
    return result;
}
static ERL_NIF_TERM finalize_nif(ErlNifEnv *e, int argc, const ERL_NIF_TERM args[]) {
    (void)argc;
    (void)args;
    ERL_NIF_TERM pids = enif_make_list(e, 0);
    pthread_mutex_lock(&scripts_mutex);
    atomic_store(&scripts_finalized, 1);
    ScriptRegistration *snapshot = scripts;
    /* Registrations are immutable after this transition. Never wait for a
     * session or an Elixir callback while holding the registry mutex. */
    pthread_mutex_unlock(&scripts_mutex);
    for (ScriptRegistration *r = snapshot; r; r = r->next) {
        Session *s = r->session;
        pthread_mutex_lock(&s->calls);
        script_free(r);
        pthread_mutex_unlock(&s->calls);
    }
    for (ScriptRegistration *r = snapshot; r; r = r->next) {
        Session *s = r->session;
        pthread_mutex_lock(&s->calls);
        if (!atomic_load(&s->closed)) {
            cleanup(s);
            atomic_store(&s->closed, 1);
            pids = enif_make_list_cell(e, enif_make_pid(e, &s->dispatcher), pids);
        }
        pthread_mutex_unlock(&s->calls);
    }
    return pids;
}
static ERL_NIF_TERM abort_nif(ErlNifEnv *e, int argc, const ERL_NIF_TERM args[]) {
    (void)argc;
    Session *s;
    if (!get_session(e, args[0], &s))
        return failure(e, a_badarg);
    pthread_mutex_lock(&s->nodes);
    for (Node *n = s->memory; n; n = n->next)
        if (native_object(n->type) == 1 && n->refs) {
            atomic_fetch_add(&n->users, 1);
            if (valid(n) && !atomic_load(&s->closed))
                clingo_control_interrupt(n->data);
            atomic_fetch_sub(&n->users, 1);
        }
    pthread_mutex_unlock(&s->nodes);
    return a_ok;
}
static ERL_NIF_TERM coverage_nif(ErlNifEnv *e, int argc, const ERL_NIF_TERM args[]) {
    (void)argc;
    (void)args;
    ERL_NIF_TERM map = enif_make_new_map(e);
    for (unsigned i = 0; i < LEN(functions); i++)
        enif_make_map_put(e, map, atom(e, functions[i].name),
                          enif_make_uint64(e, atomic_load(&call_counts[i])), &map);
    return map;
}
static ERL_NIF_TERM constants_nif(ErlNifEnv *e, int argc, const ERL_NIF_TERM args[]) {
    (void)argc;
    (void)args;
    ERL_NIF_TERM map = enif_make_new_map(e);
    for (unsigned i = 0; i < LEN(constants); i++)
        enif_make_map_put(e, map, atom(e, constants[i].name),
                          enif_make_int64(e, constants[i].value), &map);
    enif_make_map_put(e, map, atom(e, "CLINGO_VERSION"), binary(e, CLINGO_VERSION), &map);
    return map;
}
static ERL_NIF_TERM types_nif(ErlNifEnv *e, int argc, const ERL_NIF_TERM args[]) {
    (void)argc;
    (void)args;
    ERL_NIF_TERM map = enif_make_new_map(e);
    for (unsigned i = 0; i < LEN(types); i++) {
        Type *t = &types[resolve(i)];
        ERL_NIF_TERM fields = enif_make_new_map(e);
        for (int j = 0; t->kind == K_RECORD && j < t->count; j++)
            enif_make_map_put(e, fields, atom(e, t->fields[j].name),
                              enif_make_tuple2(e, binary(e, types[t->fields[j].type].name),
                                               enif_make_uint64(e, t->fields[j].offset)),
                              &fields);
        ERL_NIF_TERM value =
            enif_make_tuple3(e, enif_make_uint64(e, t->size), enif_make_int(e, t->kind), fields);
        enif_make_map_put(e, map, binary(e, types[i].name), value, &map);
    }
    return map;
}
static ERL_NIF_TERM callback_arity_nif(ErlNifEnv *e, int argc, const ERL_NIF_TERM args[]) {
    (void)argc;
    int id = type_id(e, args[0]);
    return id >= 0 && types[resolve(id)].kind == K_CALLBACK
               ? enif_make_int(e, types[resolve(id)].count)
               : a_nil;
}
RESOURCE_DESTRUCTOR(scope_destroy, ScopeHandle)
RESOURCE_DESTRUCTOR(cursor_destroy, Cursor)
RESOURCE_DESTRUCTOR(session_destroy, SessionHandle)
RESOURCE_DESTRUCTOR(pointer_destroy, Pointer)
RESOURCE_DESTRUCTOR(request_destroy, Request)
static int load(ErlNifEnv *e, void **priv, ERL_NIF_TERM info) {
    (void)priv;
    (void)info;
    int major, minor, revision;
    clingo_version(&major, &minor, &revision);
    if (major != 5 || minor != 8 || revision != 2 || !ast_metadata_matches())
        return -1;
    scope_rt = enif_open_resource_type(e, NULL, "clingo_scope", DESTRUCTOR(scope_destroy),
                                       ERL_NIF_RT_CREATE, NULL);
    cursor_rt = enif_open_resource_type(e, NULL, "clingo_cursor", DESTRUCTOR(cursor_destroy),
                                        ERL_NIF_RT_CREATE, NULL);
    session_rt = enif_open_resource_type(e, NULL, "clingo_session", DESTRUCTOR(session_destroy),
                                         ERL_NIF_RT_CREATE, NULL);
    pointer_rt = enif_open_resource_type(e, NULL, "clingo_pointer", DESTRUCTOR(pointer_destroy),
                                         ERL_NIF_RT_CREATE, NULL);
    request_rt = enif_open_resource_type(e, NULL, "clingo_request", DESTRUCTOR(request_destroy),
                                         ERL_NIF_RT_CREATE, NULL);
    a_nil = atom(e, "nil");
    a_true = atom(e, "true");
    a_false = atom(e, "false");
    a_ok = atom(e, "ok");
    a_error = atom(e, "error");
    a_badarg = atom(e, "badarg");
    a_closed = atom(e, "closed");
    a_callback = atom(e, "clingo_callback");
    if (!session_rt || !pointer_rt || !request_rt || !cursor_rt || !scope_rt)
        return -1;
    return pthread_create(&cleanup_worker, NULL, cleanup_loop, NULL) ? -1 : 0;
}
static void unload(ErlNifEnv *e, void *priv) {
    (void)e;
    (void)priv;
    pthread_mutex_lock(&cleanup_mutex);
    cleanup_stopping = 1;
    pthread_cond_broadcast(&cleanup_cond);
    pthread_mutex_unlock(&cleanup_mutex);
    pthread_join(cleanup_worker, NULL);
}
static ERL_NIF_TERM cleanup_wait_nif(ErlNifEnv *e, int argc, const ERL_NIF_TERM args[]) {
    (void)e;
    (void)argc;
    (void)args;
    pthread_mutex_lock(&cleanup_mutex);
    while (cleanup_head || cleanup_active)
        pthread_cond_wait(&cleanup_cond, &cleanup_mutex);
    pthread_mutex_unlock(&cleanup_mutex);
    return a_ok;
}
static ErlNifFunc nifs[] = {{"callback_arity", 1, callback_arity_nif, 0},
                            {"cleanup_wait", 0, cleanup_wait_nif, ERL_NIF_DIRTY_JOB_IO_BOUND},
                            {"open", 1, open_nif, 0},
                            {"open", 2, open_nif, 0},
                            {"run", 3, run_nif, ERL_NIF_DIRTY_JOB_CPU_BOUND},
                            {"run", 4, run_nif, ERL_NIF_DIRTY_JOB_CPU_BOUND},
                            {"nested", 4, nested_nif, 0},
                            {"nested", 5, nested_nif, 0},
                            {"reply", 2, reply_nif, 0},
                            {"close", 1, close_nif, ERL_NIF_DIRTY_JOB_CPU_BOUND},
                            {"interrupt", 1, interrupt_nif, ERL_NIF_DIRTY_JOB_IO_BOUND},
                            {"interrupt", 2, interrupt_nif, ERL_NIF_DIRTY_JOB_IO_BOUND},
                            {"finalize_scripts", 0, finalize_nif, ERL_NIF_DIRTY_JOB_CPU_BOUND},
                            {"cancel", 2, cancel_nif, ERL_NIF_DIRTY_JOB_IO_BOUND},
                            {"abort", 1, abort_nif, ERL_NIF_DIRTY_JOB_IO_BOUND},
                            {"coverage", 0, coverage_nif, 0},
                            {"constants", 0, constants_nif, 0},
                            {"types", 0, types_nif, 0}};
ERL_NIF_INIT(Elixir.Clingo.Native, nifs, load, NULL, NULL, unload)
