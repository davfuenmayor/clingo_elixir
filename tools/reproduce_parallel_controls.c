/* Race regression: independent controls must not share mutable preprocessing state. */
#include "clingo.h"
#include <pthread.h>
#include <stdatomic.h>
#include <stdio.h>
static pthread_barrier_t barrier;
static atomic_int failed;
static void *solve(void *unused) {
    (void)unused;
    for (int i = 0; i < 100; i++) {
        clingo_control_t *control = NULL;
        clingo_solve_handle_t *handle = NULL;
        clingo_part_t part = {"base", NULL, 0};
        clingo_solve_result_bitset_t result = 0;
        bool ok = clingo_control_new(NULL, 0, NULL, NULL, 20, &control) &&
                  clingo_control_add(control, "base", NULL, 0, "a. {b}.") &&
                  clingo_control_ground(control, &part, 1, NULL, NULL);
        pthread_barrier_wait(&barrier);
        ok = ok && clingo_control_solve(control, 0, NULL, 0, NULL, NULL, &handle) &&
             clingo_solve_handle_get(handle, &result) && (result & clingo_solve_result_satisfiable);
        if (handle && !clingo_solve_handle_close(handle))
            ok = false;
        if (control)
            clingo_control_free(control);
        if (!ok)
            atomic_store(&failed, 1);
    }
    return NULL;
}
int main(void) {
    pthread_t threads[2];
    if (pthread_barrier_init(&barrier, NULL, 2))
        return 1;
    if (pthread_create(&threads[0], NULL, solve, NULL) ||
        pthread_create(&threads[1], NULL, solve, NULL))
        return 1;
    pthread_join(threads[0], NULL);
    pthread_join(threads[1], NULL);
    pthread_barrier_destroy(&barrier);
    if (atomic_load(&failed))
        return 1;
    puts("PARALLEL_CONTROLS_PASS");
    return 0;
}
