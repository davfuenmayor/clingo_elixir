/* Contributor tool: snapshot the pinned public constructor metadata. */
#include <stdio.h>
#include "clingo.h"
int main(void) {
    printf("[\n");
    for (size_t i = 0; i < g_clingo_ast_constructors.size; ++i) {
        clingo_ast_constructor_t const *c = &g_clingo_ast_constructors.constructors[i];
        printf("  {\"name\":\"%s\",\"arguments\":[", c->name);
        for (size_t j = 0; j < c->size; ++j) {
            clingo_ast_argument_t const *a = &c->arguments[j];
            printf("%s{\"attribute\":%d,\"name\":\"%s\",\"type\":%d}", j ? "," : "",
                   a->attribute, g_clingo_ast_attribute_names.names[a->attribute], a->type);
        }
        printf("]}%s\n", i + 1 == g_clingo_ast_constructors.size ? "" : ",");
    }
    printf("]\n");
}
