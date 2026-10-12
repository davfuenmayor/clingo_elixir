/* Test interposer: pause interrupt/cancel and detect premature object destruction.
 * Real asynchronous calls are deliberately omitted to avoid dereferencing a freed
 * address when this regression runs against the broken implementation. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdatomic.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <fcntl.h>
static _Atomic(void *) active;
static void mark(const char *name) {
    char path[1024];
    snprintf(path, sizeof(path), "%s/%s", getenv("CLINGO_PIN_DIR"), name);
    int fd = open(path, O_WRONLY | O_CREAT, 0600);
    if (fd >= 0) close(fd);
}
static void pause_call(void *object) {
    atomic_store(&active, object);
    mark("entered");
    char path[1024];
    snprintf(path, sizeof(path), "%s/release", getenv("CLINGO_PIN_DIR"));
    for (unsigned i = 0; access(path, F_OK) && i < 5000; i++) {
        struct timespec pause = {0, 1000000}; nanosleep(&pause, NULL);
    }
    atomic_store(&active, NULL);
}
void clingo_control_interrupt(void *object) { pause_call(object); }
bool clingo_solve_handle_cancel(void *object) { pause_call(object); return true; }
static void *symbol(const char *name) {
    void *handle = dlopen("libclingo.so.4", RTLD_NOW | RTLD_NOLOAD);
    void *address = dlsym(handle, name);
    dlclose(handle);
    return address;
}
void clingo_control_free(void *object) {
    if (atomic_load(&active) != NULL) mark("premature");
    void (*free_control)(void *) = symbol("clingo_control_free");
    free_control(object);
}
bool clingo_solve_handle_close(void *object) {
    if (atomic_load(&active) != NULL) mark("premature");
    bool (*close_handle)(void *) = symbol("clingo_solve_handle_close");
    return close_handle(object);
}
