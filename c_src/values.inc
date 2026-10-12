/* High-level solve values. Scratch arrays never enter the session arena.
 * Cursors retain their session; its active list owns a reference until close. */
struct Cursor {
    Session *session;
    Node *control;
    clingo_solve_handle_t *handle;
    _Atomic int closed, users;
    Cursor *next;
    Scope *scope, *registration;
    clingo_solve_event_callback_t notify;
    void *notify_data;
    _Atomic int error;
    char message[4096];
};
/* clingo terminates the process on false from statistics/finish/unsat hooks.
 * Capture managed hook failures, stop search through goon, and report at the
 * next handle boundary instead. No allocation is needed on this error path. */
static bool cursor_notify(clingo_solve_event_type_t type, void *event, void *data, bool *goon) {
    Cursor *c = data;
    if (atomic_load(&c->error)) {
        *goon = false;
        return true;
    }
    if (!c->notify(type, event, c->notify_data, goon)) {
        int expected = 0;
        if (atomic_compare_exchange_strong(&c->error, &expected, -1)) {
            int code = clingo_error_code();
            const char *message = clingo_error_message();
            if (!message)
                message = "native solve callback failed";
            size_t size = strnlen(message, sizeof(c->message) - 1);
            memcpy(c->message, message, size);
            c->message[size] = 0;
            atomic_store(&c->error, code ? code : clingo_error_runtime);
        }
        *goon = false;
        clingo_set_error(clingo_error_success, NULL);
    }
    return true;
}
static int cursor_failed(Cursor *c) {
    int code;
    while ((code = atomic_load(&c->error)) == -1) {
    }
    return code;
}
static ERL_NIF_TERM cursor_error(ErlNifEnv *e, Cursor *c) {
    return failure(e,
                   enif_make_tuple2(e, enif_make_int(e, cursor_failed(c)), binary(e, c->message)));
}
static void cursor_destroy(ErlNifEnv *e, void *value) {
    (void)e;
    Cursor *cursor = value;
    enif_release_resource(cursor->session->resource);
}
static int cursor_close(Session *s, Cursor *c) {
    if (atomic_exchange(&c->closed, 1))
        return 1;
    while (atomic_load(&c->users)) {
        struct timespec pause = {0, 1000000};
        nanosleep(&pause, NULL);
    }
    bool success = clingo_solve_handle_close(c->handle);
    pthread_mutex_lock(&s->nodes);
    Cursor **at = &s->cursors;
    while (*at && *at != c)
        at = &(*at)->next;
    if (*at)
        *at = c->next;
    pthread_mutex_unlock(&s->nodes);
    if (c->registration) {
        atomic_store(&c->registration->retained, 0);
        retire_scope(s, c->registration);
        c->registration = NULL;
    }
    enif_release_resource(c);
    return success;
}
/* Callback threads also visit this list. Keep a selected resource alive after
 * unlocking; never hold nodes while closing a handle (close can invoke hooks). */
static Cursor *cursor_for_cleanup(Session *s, Scope *scope) {
    pthread_mutex_lock(&s->nodes);
    Cursor *c = s->cursors;
    while (c && (atomic_load(&c->closed) || (scope && c->scope != scope)))
        c = c->next;
    if (c)
        enif_keep_resource(c);
    pthread_mutex_unlock(&s->nodes);
    return c;
}
static void cleanup_cursors(Session *s) {
    Cursor *c;
    while ((c = cursor_for_cleanup(s, NULL))) {
        cursor_close(s, c);
        enif_release_resource(c);
    }
}
static int control_has_cursor(Session *s, Node *control) {
    pthread_mutex_lock(&s->nodes);
    Cursor *c = s->cursors;
    while (c && c->control != control->identity)
        c = c->next;
    int active = c != NULL;
    pthread_mutex_unlock(&s->nodes);
    return active;
}
static void cleanup_cursor_scope(Session *s, Scope *scope) {
    Scope *previous = execution_scope;
    execution_scope = scope;
    Cursor *c;
    while ((c = cursor_for_cleanup(s, scope))) {
        cursor_close(s, c);
        enif_release_resource(c);
    }
    execution_scope = previous;
}
static ERL_NIF_TERM value_ok(ErlNifEnv *e, ERL_NIF_TERM value) {
    return enif_make_tuple2(e, a_ok, value);
}
static int value_field(ErlNifEnv *e, ERL_NIF_TERM *map, const char *key, ERL_NIF_TERM value) {
    return enif_make_map_put(e, *map, atom(e, key), value, map);
}
static char *value_string(ErlNifEnv *e, ERL_NIF_TERM term) {
    ErlNifBinary b;
    if (!enif_inspect_binary(e, term, &b) || b.size >= MAX_ALLOC || memchr(b.data, 0, b.size))
        return NULL;
    char *text = malloc(b.size + 1);
    if (text) {
        memcpy(text, b.data, b.size);
        text[b.size] = 0;
    } else
        conversion_error = 2;
    return text;
}
/* Both model snapshots and explicit formatting use clingo's canonical printer. */
static bool symbol_text(ErlNifEnv *e, clingo_symbol_t symbol, ERL_NIF_TERM *result) {
    size_t size;
    if (!clingo_symbol_to_string_size(symbol, &size))
        return false;
    char *text = size <= MAX_ALLOC ? malloc(size ? size : 1) : NULL;
    if (!text) {
        clingo_set_error(clingo_error_bad_alloc, "cannot allocate symbol text");
        return false;
    }
    bool success = clingo_symbol_to_string(symbol, text, size);
    if (success)
        *result = binary(e, text);
    free(text);
    return success;
}
static ERL_NIF_TERM symbol_value(ErlNifEnv *e, const char *op, int argc, const ERL_NIF_TERM *args) {
    clingo_symbol_t symbol;
    if (!strcmp(op, "values_symbol_number") && argc == 1) {
        int n;
        if (!enif_get_int(e, args[0], &n))
            return failure(e, a_badarg);
        clingo_symbol_create_number(n, &symbol);
        return value_ok(e, enif_make_uint64(e, symbol));
    }
    if ((!strcmp(op, "values_symbol_parse") || !strcmp(op, "values_symbol_string")) && argc == 1) {
        char *text = value_string(e, args[0]);
        if (!text)
            return conversion_error == 2 ? out_of_memory(e) : failure(e, a_badarg);
        bool success = !strcmp(op, "values_symbol_parse")
                           ? clingo_parse_term(text, NULL, NULL, 20, &symbol)
                           : clingo_symbol_create_string(text, &symbol);
        free(text);
        return success ? value_ok(e, enif_make_uint64(e, symbol)) : native_error(e);
    }
    if (!strcmp(op, "values_symbol_function") && argc == 3) {
        unsigned count;
        if (!enif_get_list_length(e, args[1], &count) ||
            count > MAX_ALLOC / sizeof(clingo_symbol_t) ||
            (!enif_is_identical(args[2], a_true) && !enif_is_identical(args[2], a_false)))
            return failure(e, a_badarg);
        char *text = value_string(e, args[0]);
        if (!text)
            return conversion_error == 2 ? out_of_memory(e) : failure(e, a_badarg);
        clingo_symbol_t *children = malloc((count ? count : 1) * sizeof(*children));
        if (!children) {
            free(text);
            return out_of_memory(e);
        }
        ERL_NIF_TERM head, tail = args[1];
        for (unsigned i = 0; i < count; i++) {
            enif_get_list_cell(e, tail, &head, &tail);
            if (!enif_get_uint64(e, head, &children[i])) {
                free(text);
                free(children);
                return failure(e, a_badarg);
            }
        }
        bool success = clingo_symbol_create_function(text, children, count,
                                                     enif_is_identical(args[2], a_true), &symbol);
        free(text);
        free(children);
        return success ? value_ok(e, enif_make_uint64(e, symbol)) : native_error(e);
    }
    if (!strcmp(op, "values_symbol_format") && argc == 1) {
        if (!enif_get_uint64(e, args[0], &symbol))
            return failure(e, a_badarg);
        ERL_NIF_TERM text;
        return symbol_text(e, symbol, &text) ? value_ok(e, text) : native_error(e);
    }
    if (!strcmp(op, "values_symbol_data") && argc == 1) {
        if (!enif_get_uint64(e, args[0], &symbol))
            return failure(e, a_badarg);
        clingo_symbol_type_t type = clingo_symbol_type(symbol);
        ERL_NIF_TERM map = enif_make_new_map(e), list = enif_make_list(e, 0);
        value_field(e, &map, "value", a_nil);
        value_field(e, &map, "name", a_nil);
        value_field(e, &map, "arguments", list);
        value_field(e, &map, "positive", a_true);
        switch (type) {
        case clingo_symbol_type_number: {
            int n;
            if (!clingo_symbol_number(symbol, &n))
                return native_error(e);
            value_field(e, &map, "type", atom(e, "number"));
            value_field(e, &map, "value", enif_make_int(e, n));
            break;
        }
        case clingo_symbol_type_string: {
            char const *str;
            if (!clingo_symbol_string(symbol, &str))
                return native_error(e);
            value_field(e, &map, "type", atom(e, "string"));
            value_field(e, &map, "value", binary(e, str));
            break;
        }
        case clingo_symbol_type_function: {
            char const *name;
            clingo_symbol_t const *children;
            size_t count;
            bool sign;
            if (!clingo_symbol_name(symbol, &name) ||
                !clingo_symbol_arguments(symbol, &children, &count) ||
                !clingo_symbol_is_positive(symbol, &sign))
                return native_error(e);
            for (size_t i = count; i-- > 0;)
                list = enif_make_list_cell(e, enif_make_uint64(e, children[i]), list);
            value_field(e, &map, "type", atom(e, "function"));
            value_field(e, &map, "name", binary(e, name));
            value_field(e, &map, "arguments", list);
            value_field(e, &map, "positive", sign ? a_true : a_false);
            break;
        }
        case clingo_symbol_type_infimum:
            value_field(e, &map, "type", atom(e, "infimum"));
            break;
        case clingo_symbol_type_supremum:
            value_field(e, &map, "type", atom(e, "supremum"));
            break;
        default:
            return failure(e, a_badarg);
        }
        return value_ok(e, map);
    }
    return failure(e, a_badarg);
}
static ERL_NIF_TERM model_value(ErlNifEnv *e, clingo_model_t const *model, unsigned show,
                                int structured) {
    size_t size = 0, cost_size = 0;
    clingo_symbol_t *symbols = NULL;
    int64_t *cost = NULL;
    ERL_NIF_TERM texts = enif_make_list(e, 0), packed = texts, costs = texts;
    uint64_t number;
    bool optimal;
    clingo_model_type_t type;
    if (!clingo_model_symbols_size(model, show, &size) ||
        !clingo_model_cost_size(model, &cost_size))
        goto error;
    if (size > MAX_ALLOC / sizeof(*symbols) || cost_size > MAX_ALLOC / sizeof(*cost))
        goto oom;
    symbols = malloc((size ? size : 1) * sizeof(*symbols));
    cost = malloc((cost_size ? cost_size : 1) * sizeof(*cost));
    if (!symbols || !cost)
        goto oom;
    if (!clingo_model_symbols(model, show, symbols, size) ||
        !clingo_model_cost(model, cost, cost_size) || !clingo_model_number(model, &number) ||
        !clingo_model_optimality_proven(model, &optimal) || !clingo_model_type(model, &type))
        goto error;
    for (size_t i = size; i-- > 0;) {
        ERL_NIF_TERM text;
        if (!symbol_text(e, symbols[i], &text))
            goto error;
        texts = enif_make_list_cell(e, text, texts);
        if (structured)
            packed = enif_make_list_cell(e, enif_make_uint64(e, symbols[i]), packed);
    }
    for (size_t i = cost_size; i-- > 0;)
        costs = enif_make_list_cell(e, enif_make_int64(e, cost[i]), costs);
    free(symbols);
    free(cost);
    ERL_NIF_TERM map = enif_make_new_map(e);
    value_field(e, &map, "shown", texts);
    value_field(e, &map, "symbols", structured ? packed : a_nil);
    value_field(e, &map, "cost", costs);
    value_field(e, &map, "number", enif_make_uint64(e, number));
    value_field(e, &map, "optimality_proven", optimal ? a_true : a_false);
    value_field(e, &map, "type",
                atom(e, type == clingo_model_type_stable_model         ? "stable_model"
                        : type == clingo_model_type_brave_consequences ? "brave_consequences"
                                                                       : "cautious_consequences"));
    return value_ok(e, map);
oom:
    clingo_set_error(clingo_error_bad_alloc, "cannot allocate model snapshot");
error:
    free(symbols);
    free(cost);
    return native_error(e);
}
static ERL_NIF_TERM values(ErlNifEnv *e, Session *s, const char *op, int argc,
                           const ERL_NIF_TERM *args) {
    if (!strncmp(op, "values_symbol_", 14))
        return symbol_value(e, op, argc, args);
    if (!strcmp(op, "values_snapshot") && argc == 3) {
        Pointer *p;
        unsigned show;
        if (!get_pointer(e, args[0], s, &p) || native_object(p->node->type) != 4 || p->offset ||
            !enif_get_uint(e, args[1], &show))
            return failure(e, a_badarg);
        return model_value(e, p->node->data, show, enif_is_identical(args[2], a_true));
    }
    if (!strcmp(op, "values_emit") && argc == 3) {
        Pointer *cb_pointer, *data;
        unsigned count;
        if (!get_pointer(e, args[0], s, &cb_pointer) ||
            resolve(cb_pointer->node->type) !=
                resolve(type_id(e, atom(e, "clingo_symbol_callback_t"))) ||
            !enif_get_list_length(e, args[2], &count) ||
            count > MAX_ALLOC / sizeof(clingo_symbol_t))
            return failure(e, a_badarg);
        void *userdata = NULL;
        if (!enif_is_identical(args[1], a_nil)) {
            if (!get_pointer(e, args[1], s, &data))
                return failure(e, a_badarg);
            userdata = (char *)data->node->data + data->offset;
        }
        clingo_symbol_t *symbols = malloc((count ? count : 1) * sizeof(*symbols));
        if (!symbols)
            return out_of_memory(e);
        ERL_NIF_TERM head, tail = args[2];
        for (unsigned i = 0; i < count; i++) {
            enif_get_list_cell(e, tail, &head, &tail);
            if (!enif_get_uint64(e, head, &symbols[i])) {
                free(symbols);
                return failure(e, a_badarg);
            }
        }
        size_t size = count;
        bool success = false;
        void *args[] = {&symbols, &size, &userdata};
        Closure *descriptor = find_closure(s, cb_pointer->node->data);
        if (descriptor)
            callback(descriptor, &success, args);
        else
            success = ((clingo_symbol_callback_t)cb_pointer->node->data)(symbols, count, userdata);
        free(symbols);
        return success ? value_ok(e, a_true) : native_error(e);
    }
    if ((!strcmp(op, "values_literal") || !strcmp(op, "values_assumption")) && argc >= 2) {
        Pointer *p;
        clingo_symbol_t symbol;
        if (!get_pointer(e, args[0], s, &p) || native_object(p->node->type) != 1 ||
            !enif_get_uint64(e, args[1], &symbol))
            return failure(e, a_badarg);
        clingo_symbolic_atoms_t const *atoms;
        clingo_symbolic_atom_iterator_t iterator;
        bool valid_atom;
        clingo_literal_t literal;
        if (!clingo_control_symbolic_atoms(p->node->data, &atoms) ||
            !clingo_symbolic_atoms_find(atoms, symbol, &iterator) ||
            !clingo_symbolic_atoms_is_valid(atoms, iterator, &valid_atom))
            return native_error(e);
        if (valid_atom) {
            if (!clingo_symbolic_atoms_literal(atoms, iterator, &literal))
                return native_error(e);
            if (argc == 3 && enif_is_identical(args[2], a_false))
                literal = -literal;
            return value_ok(e, enif_make_int(e, literal));
        }
        if (argc != 3 || enif_is_identical(args[2], a_false))
            return value_ok(e, a_nil);
        Node *identity = p->node->identity;
        if (!identity->false_literal) {
            clingo_backend_t *backend;
            clingo_atom_t atom;
            if (!clingo_control_backend(p->node->data, &backend) || !clingo_backend_begin(backend))
                return native_error(e);
            bool success = clingo_backend_add_atom(backend, NULL, &atom) &&
                           clingo_backend_external(backend, atom, clingo_external_type_false);
            bool ended = clingo_backend_end(backend);
            if (!success || !ended)
                return native_error(e);
            identity->false_literal = (clingo_literal_t)atom;
        }
        return value_ok(e, enif_make_int(e, identity->false_literal));
    }
    if (!strcmp(op, "values_open") && argc == 4) {
        Pointer *control, *notify = NULL;
        unsigned count, mode;
        if (!get_pointer(e, args[0], s, &control) || native_object(control->node->type) != 1 ||
            !enif_get_list_length(e, args[1], &count) ||
            count > MAX_ALLOC / sizeof(clingo_literal_t) || !enif_get_uint(e, args[2], &mode) ||
            mode > 3 ||
            (!enif_is_identical(args[3], a_nil) &&
             (!get_pointer(e, args[3], s, &notify) ||
              types[resolve(notify->node->type)].kind != K_CALLBACK)))
            return failure(e, a_badarg);
        if (control_has_cursor(s, control->node))
            return failure(e, atom(e, "solve_active"));
        clingo_literal_t *assumptions = malloc((count ? count : 1) * sizeof(*assumptions));
        if (!assumptions)
            return out_of_memory(e);
        ERL_NIF_TERM head, tail = args[1];
        for (unsigned i = 0; i < count; i++) {
            enif_get_list_cell(e, tail, &head, &tail);
            if (!enif_get_int(e, head, &assumptions[i])) {
                free(assumptions);
                return failure(e, a_badarg);
            }
        }
        Cursor *cursor = enif_alloc_resource(cursor_rt, sizeof(*cursor));
        if (!cursor) {
            free(assumptions);
            return out_of_memory(e);
        }
        memset(cursor, 0, sizeof(*cursor));
        cursor->session = s;
        cursor->control = control->node->identity;
        cursor->scope = execution_scope;
        while (cursor->scope && cursor->scope->managed)
            cursor->scope = cursor->scope->parent;
        cursor->registration = execution_scope && execution_scope->managed ? execution_scope : NULL;
        enif_keep_resource(s->resource);
        clingo_solve_event_callback_t cb =
            notify ? (clingo_solve_event_callback_t)notify->node->data : NULL;
        void *data = NULL;
        void *converted[6] = {NULL, NULL, NULL, NULL, &cb, &data};
        Function fn = {.name = "clingo_control_solve"};
        if (!adapt_callbacks(s, &fn, converted)) {
            free(assumptions);
            enif_release_resource(cursor);
            return out_of_memory(e);
        }
        cursor->notify = cb;
        cursor->notify_data = data;
        bool success = clingo_control_solve(control->node->data, mode, assumptions, count,
                                            cb ? cursor_notify : NULL, cursor, &cursor->handle);
        free(assumptions);
        if (!success) {
            enif_release_resource(cursor);
            return native_error(e);
        }
        if (cursor->registration)
            atomic_store(&cursor->registration->retained, 1);
        pthread_mutex_lock(&s->nodes);
        cursor->next = s->cursors;
        s->cursors = cursor;
        pthread_mutex_unlock(&s->nodes);
        ERL_NIF_TERM term = enif_make_resource(e, cursor);
        /* The initial resource reference belongs to the session active list. */
        return value_ok(e, term);
    }
    Cursor *c;
    if (argc < 1 || !enif_get_resource(e, args[0], cursor_rt, (void **)&c) || c->session != s)
        return failure(e, a_badarg);
    if (!strcmp(op, "values_close")) {
        int success = cursor_close(s, c);
        return cursor_failed(c) ? cursor_error(e, c)
               : success        ? value_ok(e, a_ok)
                                : native_error(e);
    }
    if (atomic_load(&c->closed) || !valid(c->control))
        return failure(e, a_closed);
    if (cursor_failed(c))
        return cursor_error(e, c);
    if (!strcmp(op, "values_resume") && argc == 1) {
        bool success = clingo_solve_handle_resume(c->handle);
        return cursor_failed(c) ? cursor_error(e, c)
               : success        ? value_ok(e, a_ok)
                                : native_error(e);
    }
    if ((!strcmp(op, "values_model") || !strcmp(op, "values_last")) && argc == 3) {
        unsigned show;
        if (!enif_get_uint(e, args[1], &show))
            return failure(e, a_badarg);
        clingo_model_t const *model = NULL;
        bool success;
        if (!strcmp(op, "values_last"))
            success = clingo_solve_handle_last(c->handle, &model);
        else {
            clingo_model_t const *m = NULL;
            success = clingo_solve_handle_model(c->handle, &m);
            model = m;
        }
        if (cursor_failed(c))
            return cursor_error(e, c);
        if (!success)
            return native_error(e);
        return model ? model_value(e, model, show, enif_is_identical(args[2], a_true))
                     : value_ok(e, a_nil);
    }
    if (!strcmp(op, "values_result") && argc == 1) {
        clingo_solve_result_bitset_t result;
        bool success = clingo_solve_handle_get(c->handle, &result);
        return cursor_failed(c) ? cursor_error(e, c)
               : success        ? value_ok(e, enif_make_uint(e, result))
                                : native_error(e);
    }
    if (!strcmp(op, "values_wait") && argc == 2) {
        double timeout;
        int integer;
        if (!enif_get_double(e, args[1], &timeout)) {
            if (!enif_get_int(e, args[1], &integer))
                return failure(e, a_badarg);
            timeout = integer;
        }
        bool ready;
        clingo_solve_handle_wait(c->handle, timeout, &ready);
        return cursor_failed(c) ? cursor_error(e, c) : value_ok(e, ready ? a_true : a_false);
    }
    if (!strcmp(op, "values_core") && argc == 1) {
        clingo_literal_t const *literals;
        size_t size;
        if (!clingo_solve_handle_core(c->handle, &literals, &size))
            return native_error(e);
        ERL_NIF_TERM list = enif_make_list(e, 0);
        for (size_t i = size; i-- > 0;)
            list = enif_make_list_cell(e, enif_make_int(e, literals[i]), list);
        return value_ok(e, list);
    }
    return failure(e, a_badarg);
}
