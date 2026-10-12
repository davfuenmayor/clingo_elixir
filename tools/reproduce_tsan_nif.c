#include <erl_nif.h>
#include <pthread.h>
static int shared_value;
static pthread_barrier_t gate;
static void *write_value(void *unused) {
    (void)unused;
    pthread_barrier_wait(&gate);
    shared_value++;
    return NULL;
}
static ERL_NIF_TERM race(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]) {
    (void)argc;
    (void)argv;
    pthread_t a, b;
    pthread_barrier_init(&gate, NULL, 2);
    pthread_create(&a, NULL, write_value, NULL);
    pthread_create(&b, NULL, write_value, NULL);
    pthread_join(a, NULL);
    pthread_join(b, NULL);
    pthread_barrier_destroy(&gate);
    return enif_make_int(env, shared_value);
}
static ErlNifFunc funcs[] = {{"race", 0, race, ERL_NIF_DIRTY_JOB_CPU_BOUND}};
ERL_NIF_INIT(Elixir.ClingoTsanPositiveControl, funcs, NULL, NULL, NULL, NULL)
