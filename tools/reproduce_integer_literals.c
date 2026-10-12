/* Standalone upstream UBSan reproducer; link against the installation under test. */
#include "clingo.h"
#include <stdio.h>

int main(int argc, char **argv) {
    clingo_symbol_t symbol;
    int number;
    char const *text = argc > 1 ? argv[1] : "-2147483648";
    if (!clingo_parse_term(text, NULL, NULL, 0, &symbol) ||
        !clingo_symbol_number(symbol, &number)) {
        fprintf(stderr, "%s\n", clingo_error_message());
        return 1;
    }
    printf("%s -> %d\n", text, number);
    return 0;
}
