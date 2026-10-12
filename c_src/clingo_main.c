/* CLI output is isolated in a subprocess, linked to the packaged clingo. */
#include "clingo.h"
int main(int argc, char **argv) {
    clingo_application_t application = {0};
    return clingo_main(&application, (char const *const *)(argv + 1), (size_t)(argc - 1), NULL);
}
