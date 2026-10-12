/* Test-only glibc interposer: fail one allocation requested by the NIF.
 * ERTS's NIF function table is injected separately in the test-only build. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <link.h>
#include <stdatomic.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

extern void *__libc_malloc(size_t);
extern void *__libc_calloc(size_t, size_t);
static _Atomic long budget = -1;
static _Atomic uintptr_t text_start, text_end;
static const char *kind = "heap";

__attribute__((constructor)) static void configure(void) {
    const char *value = getenv("CLINGO_FAIL_ALLOCATION");
    if (value)
        atomic_store(&budget, strtol(value, NULL, 10));
    const char *selected = getenv("CLINGO_FAIL_KIND");
    if (selected) kind = selected;
}

static int fail(void *caller, const char *category) {
    uintptr_t address = (uintptr_t)caller;
    if (strcmp(kind, category) || atomic_load(&budget) < 0 || address < atomic_load(&text_start) ||
        address >= atomic_load(&text_end))
        return 0;
    if (atomic_fetch_sub(&budget, 1) == 0) {
        const char message[] = "ALLOCATION_INJECTED\n";
        write(2, message, sizeof(message) - 1);
        return 1;
    }
    return 0;
}

/* Inspect the loaded ELF once, rather than taking loader locks in malloc. */
void *dlopen(const char *filename, int flags) {
    void *(*load)(const char *, int) = dlsym(RTLD_NEXT, "dlopen");
    void *handle = load(filename, flags);
    if (handle && filename && strstr(filename, "clingo_elixir.so")) {
        struct link_map *map;
        if (dlinfo(handle, RTLD_DI_LINKMAP, &map) == 0) {
            ElfW(Ehdr) *header = (void *)map->l_addr;
            ElfW(Phdr) *segments = (void *)(map->l_addr + header->e_phoff);
            for (int i = 0; i < header->e_phnum; i++) {
                if (segments[i].p_type == PT_LOAD && (segments[i].p_flags & PF_X)) {
                    atomic_store(&text_start, map->l_addr + segments[i].p_vaddr);
                    atomic_store(&text_end,
                                 map->l_addr + segments[i].p_vaddr + segments[i].p_memsz);
                }
            }
        }
    }
    return handle;
}

void *malloc(size_t size) {
    return fail(__builtin_return_address(0), "heap") ? NULL : __libc_malloc(size);
}

void *calloc(size_t count, size_t size) {
    return fail(__builtin_return_address(0), "heap") ? NULL : __libc_calloc(count, size);
}

