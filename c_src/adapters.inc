/* Generated typed adapters; do not edit. */
typedef void (*cb_type_23)(clingo_warning_t, const char *, void *);
typedef bool (*cb_type_115)(const clingo_location_t *, const char *, const clingo_symbol_t *, size_t, void *, clingo_symbol_callback_t, void *);
typedef bool (*cb_type_120)(const clingo_symbol_t *, size_t, void *);
typedef bool (*cb_type_123)(clingo_solve_event_type_t, void *, void *, bool *);
typedef bool (*cb_type_129)(clingo_propagate_init_t *, void *);
typedef bool (*cb_type_130)(clingo_propagate_control_t *, const clingo_literal_t *, size_t, void *);
typedef void (*cb_type_131)(const clingo_propagate_control_t *, const clingo_literal_t *, size_t, void *);
typedef bool (*cb_type_132)(clingo_propagate_control_t *, void *);
typedef bool (*cb_type_133)(clingo_id_t, const clingo_assignment_t *, clingo_literal_t, void *, clingo_literal_t *);
typedef bool (*cb_type_140)(bool, void *);
typedef bool (*cb_type_141)(void *);
typedef bool (*cb_type_142)(bool, const clingo_atom_t *, size_t, const clingo_literal_t *, size_t, void *);
typedef bool (*cb_type_143)(bool, const clingo_atom_t *, size_t, clingo_weight_t, const clingo_weighted_literal_t *, size_t, void *);
typedef bool (*cb_type_144)(clingo_weight_t, const clingo_weighted_literal_t *, size_t, void *);
typedef bool (*cb_type_145)(const clingo_atom_t *, size_t, void *);
typedef bool (*cb_type_146)(clingo_symbol_t, clingo_atom_t, void *);
typedef bool (*cb_type_147)(clingo_symbol_t, const clingo_literal_t *, size_t, void *);
typedef bool (*cb_type_148)(clingo_atom_t, clingo_external_type_t, void *);
typedef bool (*cb_type_149)(const clingo_literal_t *, size_t, void *);
typedef bool (*cb_type_150)(clingo_atom_t, clingo_heuristic_type_t, int, unsigned int, const clingo_literal_t *, size_t, void *);
typedef bool (*cb_type_151)(int, int, const clingo_literal_t *, size_t, void *);
typedef bool (*cb_type_152)(clingo_id_t, int, void *);
typedef bool (*cb_type_153)(clingo_id_t, const char *, void *);
typedef bool (*cb_type_154)(clingo_id_t, int, const clingo_id_t *, size_t, void *);
typedef bool (*cb_type_155)(clingo_id_t, const clingo_id_t *, size_t, const clingo_literal_t *, size_t, void *);
typedef bool (*cb_type_156)(clingo_id_t, clingo_id_t, const clingo_id_t *, size_t, void *);
typedef bool (*cb_type_157)(clingo_id_t, clingo_id_t, const clingo_id_t *, size_t, clingo_id_t, clingo_id_t, void *);
typedef bool (*cb_type_170)(clingo_ast_t *, void *);
typedef bool (*cb_type_179)(const char *, void *);
typedef const char *(*cb_type_183)(void *);
typedef unsigned int (*cb_type_184)(void *);
typedef bool (*cb_type_186)(clingo_control_t *, const char *const *, size_t, void *);
typedef bool (*cb_type_188)(const clingo_model_t *, clingo_default_model_printer_t, void *, void *);
typedef bool (*cb_type_190)(clingo_options_t *, void *);
typedef bool (*cb_type_194)(const clingo_location_t *, const char *, void *);
typedef bool (*cb_type_195)(const clingo_location_t *, const char *, const clingo_symbol_t *, size_t, clingo_symbol_callback_t, void *, void *);
typedef bool (*cb_type_196)(const char *, bool *, void *);
typedef bool (*cb_type_197)(clingo_control_t *, void *);
typedef void (*cb_type_198)(void *);
static int call_typed(int type, void (*address)(void), void **values, void *result) {
  (void)values; (void)result;
  switch (resolve(type)) {
  case 23: {
    clingo_warning_t a0; memcpy(&a0, values[0], sizeof(a0));
    const char * a1; memcpy(&a1, values[1], sizeof(a1));
    void * a2; memcpy(&a2, values[2], sizeof(a2));
    ((cb_type_23)address)(a0, a1, a2);
    return 1;
  }
  case 115: {
    const clingo_location_t * a0; memcpy(&a0, values[0], sizeof(a0));
    const char * a1; memcpy(&a1, values[1], sizeof(a1));
    const clingo_symbol_t * a2; memcpy(&a2, values[2], sizeof(a2));
    size_t a3; memcpy(&a3, values[3], sizeof(a3));
    void * a4; memcpy(&a4, values[4], sizeof(a4));
    clingo_symbol_callback_t a5; memcpy(&a5, values[5], sizeof(a5));
    void * a6; memcpy(&a6, values[6], sizeof(a6));
    bool ret = ((cb_type_115)address)(a0, a1, a2, a3, a4, a5, a6); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 120: {
    const clingo_symbol_t * a0; memcpy(&a0, values[0], sizeof(a0));
    size_t a1; memcpy(&a1, values[1], sizeof(a1));
    void * a2; memcpy(&a2, values[2], sizeof(a2));
    bool ret = ((cb_type_120)address)(a0, a1, a2); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 123: {
    clingo_solve_event_type_t a0; memcpy(&a0, values[0], sizeof(a0));
    void * a1; memcpy(&a1, values[1], sizeof(a1));
    void * a2; memcpy(&a2, values[2], sizeof(a2));
    bool * a3; memcpy(&a3, values[3], sizeof(a3));
    bool ret = ((cb_type_123)address)(a0, a1, a2, a3); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 129: {
    clingo_propagate_init_t * a0; memcpy(&a0, values[0], sizeof(a0));
    void * a1; memcpy(&a1, values[1], sizeof(a1));
    bool ret = ((cb_type_129)address)(a0, a1); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 130: {
    clingo_propagate_control_t * a0; memcpy(&a0, values[0], sizeof(a0));
    const clingo_literal_t * a1; memcpy(&a1, values[1], sizeof(a1));
    size_t a2; memcpy(&a2, values[2], sizeof(a2));
    void * a3; memcpy(&a3, values[3], sizeof(a3));
    bool ret = ((cb_type_130)address)(a0, a1, a2, a3); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 131: {
    const clingo_propagate_control_t * a0; memcpy(&a0, values[0], sizeof(a0));
    const clingo_literal_t * a1; memcpy(&a1, values[1], sizeof(a1));
    size_t a2; memcpy(&a2, values[2], sizeof(a2));
    void * a3; memcpy(&a3, values[3], sizeof(a3));
    ((cb_type_131)address)(a0, a1, a2, a3);
    return 1;
  }
  case 132: {
    clingo_propagate_control_t * a0; memcpy(&a0, values[0], sizeof(a0));
    void * a1; memcpy(&a1, values[1], sizeof(a1));
    bool ret = ((cb_type_132)address)(a0, a1); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 133: {
    clingo_id_t a0; memcpy(&a0, values[0], sizeof(a0));
    const clingo_assignment_t * a1; memcpy(&a1, values[1], sizeof(a1));
    clingo_literal_t a2; memcpy(&a2, values[2], sizeof(a2));
    void * a3; memcpy(&a3, values[3], sizeof(a3));
    clingo_literal_t * a4; memcpy(&a4, values[4], sizeof(a4));
    bool ret = ((cb_type_133)address)(a0, a1, a2, a3, a4); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 140: {
    bool a0; memcpy(&a0, values[0], sizeof(a0));
    void * a1; memcpy(&a1, values[1], sizeof(a1));
    bool ret = ((cb_type_140)address)(a0, a1); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 141: {
    void * a0; memcpy(&a0, values[0], sizeof(a0));
    bool ret = ((cb_type_141)address)(a0); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 142: {
    bool a0; memcpy(&a0, values[0], sizeof(a0));
    const clingo_atom_t * a1; memcpy(&a1, values[1], sizeof(a1));
    size_t a2; memcpy(&a2, values[2], sizeof(a2));
    const clingo_literal_t * a3; memcpy(&a3, values[3], sizeof(a3));
    size_t a4; memcpy(&a4, values[4], sizeof(a4));
    void * a5; memcpy(&a5, values[5], sizeof(a5));
    bool ret = ((cb_type_142)address)(a0, a1, a2, a3, a4, a5); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 143: {
    bool a0; memcpy(&a0, values[0], sizeof(a0));
    const clingo_atom_t * a1; memcpy(&a1, values[1], sizeof(a1));
    size_t a2; memcpy(&a2, values[2], sizeof(a2));
    clingo_weight_t a3; memcpy(&a3, values[3], sizeof(a3));
    const clingo_weighted_literal_t * a4; memcpy(&a4, values[4], sizeof(a4));
    size_t a5; memcpy(&a5, values[5], sizeof(a5));
    void * a6; memcpy(&a6, values[6], sizeof(a6));
    bool ret = ((cb_type_143)address)(a0, a1, a2, a3, a4, a5, a6); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 144: {
    clingo_weight_t a0; memcpy(&a0, values[0], sizeof(a0));
    const clingo_weighted_literal_t * a1; memcpy(&a1, values[1], sizeof(a1));
    size_t a2; memcpy(&a2, values[2], sizeof(a2));
    void * a3; memcpy(&a3, values[3], sizeof(a3));
    bool ret = ((cb_type_144)address)(a0, a1, a2, a3); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 145: {
    const clingo_atom_t * a0; memcpy(&a0, values[0], sizeof(a0));
    size_t a1; memcpy(&a1, values[1], sizeof(a1));
    void * a2; memcpy(&a2, values[2], sizeof(a2));
    bool ret = ((cb_type_145)address)(a0, a1, a2); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 146: {
    clingo_symbol_t a0; memcpy(&a0, values[0], sizeof(a0));
    clingo_atom_t a1; memcpy(&a1, values[1], sizeof(a1));
    void * a2; memcpy(&a2, values[2], sizeof(a2));
    bool ret = ((cb_type_146)address)(a0, a1, a2); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 147: {
    clingo_symbol_t a0; memcpy(&a0, values[0], sizeof(a0));
    const clingo_literal_t * a1; memcpy(&a1, values[1], sizeof(a1));
    size_t a2; memcpy(&a2, values[2], sizeof(a2));
    void * a3; memcpy(&a3, values[3], sizeof(a3));
    bool ret = ((cb_type_147)address)(a0, a1, a2, a3); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 148: {
    clingo_atom_t a0; memcpy(&a0, values[0], sizeof(a0));
    clingo_external_type_t a1; memcpy(&a1, values[1], sizeof(a1));
    void * a2; memcpy(&a2, values[2], sizeof(a2));
    bool ret = ((cb_type_148)address)(a0, a1, a2); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 149: {
    const clingo_literal_t * a0; memcpy(&a0, values[0], sizeof(a0));
    size_t a1; memcpy(&a1, values[1], sizeof(a1));
    void * a2; memcpy(&a2, values[2], sizeof(a2));
    bool ret = ((cb_type_149)address)(a0, a1, a2); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 150: {
    clingo_atom_t a0; memcpy(&a0, values[0], sizeof(a0));
    clingo_heuristic_type_t a1; memcpy(&a1, values[1], sizeof(a1));
    int a2; memcpy(&a2, values[2], sizeof(a2));
    unsigned int a3; memcpy(&a3, values[3], sizeof(a3));
    const clingo_literal_t * a4; memcpy(&a4, values[4], sizeof(a4));
    size_t a5; memcpy(&a5, values[5], sizeof(a5));
    void * a6; memcpy(&a6, values[6], sizeof(a6));
    bool ret = ((cb_type_150)address)(a0, a1, a2, a3, a4, a5, a6); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 151: {
    int a0; memcpy(&a0, values[0], sizeof(a0));
    int a1; memcpy(&a1, values[1], sizeof(a1));
    const clingo_literal_t * a2; memcpy(&a2, values[2], sizeof(a2));
    size_t a3; memcpy(&a3, values[3], sizeof(a3));
    void * a4; memcpy(&a4, values[4], sizeof(a4));
    bool ret = ((cb_type_151)address)(a0, a1, a2, a3, a4); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 152: {
    clingo_id_t a0; memcpy(&a0, values[0], sizeof(a0));
    int a1; memcpy(&a1, values[1], sizeof(a1));
    void * a2; memcpy(&a2, values[2], sizeof(a2));
    bool ret = ((cb_type_152)address)(a0, a1, a2); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 153: {
    clingo_id_t a0; memcpy(&a0, values[0], sizeof(a0));
    const char * a1; memcpy(&a1, values[1], sizeof(a1));
    void * a2; memcpy(&a2, values[2], sizeof(a2));
    bool ret = ((cb_type_153)address)(a0, a1, a2); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 154: {
    clingo_id_t a0; memcpy(&a0, values[0], sizeof(a0));
    int a1; memcpy(&a1, values[1], sizeof(a1));
    const clingo_id_t * a2; memcpy(&a2, values[2], sizeof(a2));
    size_t a3; memcpy(&a3, values[3], sizeof(a3));
    void * a4; memcpy(&a4, values[4], sizeof(a4));
    bool ret = ((cb_type_154)address)(a0, a1, a2, a3, a4); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 155: {
    clingo_id_t a0; memcpy(&a0, values[0], sizeof(a0));
    const clingo_id_t * a1; memcpy(&a1, values[1], sizeof(a1));
    size_t a2; memcpy(&a2, values[2], sizeof(a2));
    const clingo_literal_t * a3; memcpy(&a3, values[3], sizeof(a3));
    size_t a4; memcpy(&a4, values[4], sizeof(a4));
    void * a5; memcpy(&a5, values[5], sizeof(a5));
    bool ret = ((cb_type_155)address)(a0, a1, a2, a3, a4, a5); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 156: {
    clingo_id_t a0; memcpy(&a0, values[0], sizeof(a0));
    clingo_id_t a1; memcpy(&a1, values[1], sizeof(a1));
    const clingo_id_t * a2; memcpy(&a2, values[2], sizeof(a2));
    size_t a3; memcpy(&a3, values[3], sizeof(a3));
    void * a4; memcpy(&a4, values[4], sizeof(a4));
    bool ret = ((cb_type_156)address)(a0, a1, a2, a3, a4); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 157: {
    clingo_id_t a0; memcpy(&a0, values[0], sizeof(a0));
    clingo_id_t a1; memcpy(&a1, values[1], sizeof(a1));
    const clingo_id_t * a2; memcpy(&a2, values[2], sizeof(a2));
    size_t a3; memcpy(&a3, values[3], sizeof(a3));
    clingo_id_t a4; memcpy(&a4, values[4], sizeof(a4));
    clingo_id_t a5; memcpy(&a5, values[5], sizeof(a5));
    void * a6; memcpy(&a6, values[6], sizeof(a6));
    bool ret = ((cb_type_157)address)(a0, a1, a2, a3, a4, a5, a6); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 170: {
    clingo_ast_t * a0; memcpy(&a0, values[0], sizeof(a0));
    void * a1; memcpy(&a1, values[1], sizeof(a1));
    bool ret = ((cb_type_170)address)(a0, a1); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 179: {
    const char * a0; memcpy(&a0, values[0], sizeof(a0));
    void * a1; memcpy(&a1, values[1], sizeof(a1));
    bool ret = ((cb_type_179)address)(a0, a1); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 183: {
    void * a0; memcpy(&a0, values[0], sizeof(a0));
    const char * ret = ((cb_type_183)address)(a0); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 184: {
    void * a0; memcpy(&a0, values[0], sizeof(a0));
    unsigned int ret = ((cb_type_184)address)(a0); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 186: {
    clingo_control_t * a0; memcpy(&a0, values[0], sizeof(a0));
    const char *const * a1; memcpy(&a1, values[1], sizeof(a1));
    size_t a2; memcpy(&a2, values[2], sizeof(a2));
    void * a3; memcpy(&a3, values[3], sizeof(a3));
    bool ret = ((cb_type_186)address)(a0, a1, a2, a3); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 188: {
    const clingo_model_t * a0; memcpy(&a0, values[0], sizeof(a0));
    clingo_default_model_printer_t a1; memcpy(&a1, values[1], sizeof(a1));
    void * a2; memcpy(&a2, values[2], sizeof(a2));
    void * a3; memcpy(&a3, values[3], sizeof(a3));
    bool ret = ((cb_type_188)address)(a0, a1, a2, a3); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 190: {
    clingo_options_t * a0; memcpy(&a0, values[0], sizeof(a0));
    void * a1; memcpy(&a1, values[1], sizeof(a1));
    bool ret = ((cb_type_190)address)(a0, a1); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 194: {
    const clingo_location_t * a0; memcpy(&a0, values[0], sizeof(a0));
    const char * a1; memcpy(&a1, values[1], sizeof(a1));
    void * a2; memcpy(&a2, values[2], sizeof(a2));
    bool ret = ((cb_type_194)address)(a0, a1, a2); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 195: {
    const clingo_location_t * a0; memcpy(&a0, values[0], sizeof(a0));
    const char * a1; memcpy(&a1, values[1], sizeof(a1));
    const clingo_symbol_t * a2; memcpy(&a2, values[2], sizeof(a2));
    size_t a3; memcpy(&a3, values[3], sizeof(a3));
    clingo_symbol_callback_t a4; memcpy(&a4, values[4], sizeof(a4));
    void * a5; memcpy(&a5, values[5], sizeof(a5));
    void * a6; memcpy(&a6, values[6], sizeof(a6));
    bool ret = ((cb_type_195)address)(a0, a1, a2, a3, a4, a5, a6); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 196: {
    const char * a0; memcpy(&a0, values[0], sizeof(a0));
    bool * a1; memcpy(&a1, values[1], sizeof(a1));
    void * a2; memcpy(&a2, values[2], sizeof(a2));
    bool ret = ((cb_type_196)address)(a0, a1, a2); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 197: {
    clingo_control_t * a0; memcpy(&a0, values[0], sizeof(a0));
    void * a1; memcpy(&a1, values[1], sizeof(a1));
    bool ret = ((cb_type_197)address)(a0, a1); memcpy(result, &ret, sizeof(ret));
    return 1;
  }
  case 198: {
    void * a0; memcpy(&a0, values[0], sizeof(a0));
    ((cb_type_198)address)(a0);
    return 1;
  }
  default: return 0;
  }
}
static void callback_0_0(clingo_warning_t a0, const char * a1, void * a2) {
  CallbackBundle *bundle = a2;
  a2 = bundle->data;
  void *values[] = {&a0, &a1, &a2};
  unsigned char unused = 0;
  if (bundle->callbacks[0]) callback(bundle->callbacks[0], &unused, values);
  else call_typed(23, bundle->native[0], values, &unused);
}
static void callback_1_0(clingo_warning_t a0, const char * a1, void * a2) {
  CallbackBundle *bundle = a2;
  a2 = bundle->data;
  void *values[] = {&a0, &a1, &a2};
  unsigned char unused = 0;
  if (bundle->callbacks[0]) callback(bundle->callbacks[0], &unused, values);
  else call_typed(23, bundle->native[0], values, &unused);
}
static bool callback_2_0(const clingo_location_t * a0, const char * a1, const clingo_symbol_t * a2, size_t a3, void * a4, clingo_symbol_callback_t a5, void * a6) {
  CallbackBundle *bundle = a4;
  a4 = bundle->data;
  void *values[] = {&a0, &a1, &a2, &a3, &a4, &a5, &a6};
  bool ret = {0};
  if (bundle->callbacks[0]) callback(bundle->callbacks[0], &ret, values);
  else call_typed(115, bundle->native[0], values, &ret);
  return ret;
}
static bool callback_3_0(clingo_solve_event_type_t a0, void * a1, void * a2, bool * a3) {
  CallbackBundle *bundle = a2;
  a2 = bundle->data;
  void *values[] = {&a0, &a1, &a2, &a3};
  bool ret = {0};
  if (bundle->callbacks[0]) callback(bundle->callbacks[0], &ret, values);
  else call_typed(123, bundle->native[0], values, &ret);
  return ret;
}
static bool callback_4_0(clingo_propagate_init_t * a0, void * a1) {
  CallbackBundle *bundle = a1;
  a1 = bundle->data;
  void *values[] = {&a0, &a1};
  bool ret = {0};
  if (bundle->callbacks[0]) callback(bundle->callbacks[0], &ret, values);
  else call_typed(129, bundle->native[0], values, &ret);
  return ret;
}
static bool callback_4_1(clingo_propagate_control_t * a0, const clingo_literal_t * a1, size_t a2, void * a3) {
  CallbackBundle *bundle = a3;
  a3 = bundle->data;
  void *values[] = {&a0, &a1, &a2, &a3};
  bool ret = {0};
  if (bundle->callbacks[1]) callback(bundle->callbacks[1], &ret, values);
  else call_typed(130, bundle->native[1], values, &ret);
  return ret;
}
static void callback_4_2(const clingo_propagate_control_t * a0, const clingo_literal_t * a1, size_t a2, void * a3) {
  CallbackBundle *bundle = a3;
  a3 = bundle->data;
  void *values[] = {&a0, &a1, &a2, &a3};
  unsigned char unused = 0;
  if (bundle->callbacks[2]) callback(bundle->callbacks[2], &unused, values);
  else call_typed(131, bundle->native[2], values, &unused);
}
static bool callback_4_3(clingo_propagate_control_t * a0, void * a1) {
  CallbackBundle *bundle = a1;
  a1 = bundle->data;
  void *values[] = {&a0, &a1};
  bool ret = {0};
  if (bundle->callbacks[3]) callback(bundle->callbacks[3], &ret, values);
  else call_typed(132, bundle->native[3], values, &ret);
  return ret;
}
static bool callback_4_4(clingo_id_t a0, const clingo_assignment_t * a1, clingo_literal_t a2, void * a3, clingo_literal_t * a4) {
  CallbackBundle *bundle = a3;
  a3 = bundle->data;
  void *values[] = {&a0, &a1, &a2, &a3, &a4};
  bool ret = {0};
  if (bundle->callbacks[4]) callback(bundle->callbacks[4], &ret, values);
  else call_typed(133, bundle->native[4], values, &ret);
  return ret;
}
static bool callback_5_0(bool a0, void * a1) {
  CallbackBundle *bundle = a1;
  a1 = bundle->data;
  void *values[] = {&a0, &a1};
  bool ret = {0};
  if (bundle->callbacks[0]) callback(bundle->callbacks[0], &ret, values);
  else call_typed(140, bundle->native[0], values, &ret);
  return ret;
}
static bool callback_5_1(void * a0) {
  CallbackBundle *bundle = a0;
  a0 = bundle->data;
  void *values[] = {&a0};
  bool ret = {0};
  if (bundle->callbacks[1]) callback(bundle->callbacks[1], &ret, values);
  else call_typed(141, bundle->native[1], values, &ret);
  return ret;
}
static bool callback_5_2(void * a0) {
  CallbackBundle *bundle = a0;
  a0 = bundle->data;
  void *values[] = {&a0};
  bool ret = {0};
  if (bundle->callbacks[2]) callback(bundle->callbacks[2], &ret, values);
  else call_typed(141, bundle->native[2], values, &ret);
  return ret;
}
static bool callback_5_3(bool a0, const clingo_atom_t * a1, size_t a2, const clingo_literal_t * a3, size_t a4, void * a5) {
  CallbackBundle *bundle = a5;
  a5 = bundle->data;
  void *values[] = {&a0, &a1, &a2, &a3, &a4, &a5};
  bool ret = {0};
  if (bundle->callbacks[3]) callback(bundle->callbacks[3], &ret, values);
  else call_typed(142, bundle->native[3], values, &ret);
  return ret;
}
static bool callback_5_4(bool a0, const clingo_atom_t * a1, size_t a2, clingo_weight_t a3, const clingo_weighted_literal_t * a4, size_t a5, void * a6) {
  CallbackBundle *bundle = a6;
  a6 = bundle->data;
  void *values[] = {&a0, &a1, &a2, &a3, &a4, &a5, &a6};
  bool ret = {0};
  if (bundle->callbacks[4]) callback(bundle->callbacks[4], &ret, values);
  else call_typed(143, bundle->native[4], values, &ret);
  return ret;
}
static bool callback_5_5(clingo_weight_t a0, const clingo_weighted_literal_t * a1, size_t a2, void * a3) {
  CallbackBundle *bundle = a3;
  a3 = bundle->data;
  void *values[] = {&a0, &a1, &a2, &a3};
  bool ret = {0};
  if (bundle->callbacks[5]) callback(bundle->callbacks[5], &ret, values);
  else call_typed(144, bundle->native[5], values, &ret);
  return ret;
}
static bool callback_5_6(const clingo_atom_t * a0, size_t a1, void * a2) {
  CallbackBundle *bundle = a2;
  a2 = bundle->data;
  void *values[] = {&a0, &a1, &a2};
  bool ret = {0};
  if (bundle->callbacks[6]) callback(bundle->callbacks[6], &ret, values);
  else call_typed(145, bundle->native[6], values, &ret);
  return ret;
}
static bool callback_5_7(clingo_symbol_t a0, clingo_atom_t a1, void * a2) {
  CallbackBundle *bundle = a2;
  a2 = bundle->data;
  void *values[] = {&a0, &a1, &a2};
  bool ret = {0};
  if (bundle->callbacks[7]) callback(bundle->callbacks[7], &ret, values);
  else call_typed(146, bundle->native[7], values, &ret);
  return ret;
}
static bool callback_5_8(clingo_symbol_t a0, const clingo_literal_t * a1, size_t a2, void * a3) {
  CallbackBundle *bundle = a3;
  a3 = bundle->data;
  void *values[] = {&a0, &a1, &a2, &a3};
  bool ret = {0};
  if (bundle->callbacks[8]) callback(bundle->callbacks[8], &ret, values);
  else call_typed(147, bundle->native[8], values, &ret);
  return ret;
}
static bool callback_5_9(clingo_atom_t a0, clingo_external_type_t a1, void * a2) {
  CallbackBundle *bundle = a2;
  a2 = bundle->data;
  void *values[] = {&a0, &a1, &a2};
  bool ret = {0};
  if (bundle->callbacks[9]) callback(bundle->callbacks[9], &ret, values);
  else call_typed(148, bundle->native[9], values, &ret);
  return ret;
}
static bool callback_5_10(const clingo_literal_t * a0, size_t a1, void * a2) {
  CallbackBundle *bundle = a2;
  a2 = bundle->data;
  void *values[] = {&a0, &a1, &a2};
  bool ret = {0};
  if (bundle->callbacks[10]) callback(bundle->callbacks[10], &ret, values);
  else call_typed(149, bundle->native[10], values, &ret);
  return ret;
}
static bool callback_5_11(clingo_atom_t a0, clingo_heuristic_type_t a1, int a2, unsigned int a3, const clingo_literal_t * a4, size_t a5, void * a6) {
  CallbackBundle *bundle = a6;
  a6 = bundle->data;
  void *values[] = {&a0, &a1, &a2, &a3, &a4, &a5, &a6};
  bool ret = {0};
  if (bundle->callbacks[11]) callback(bundle->callbacks[11], &ret, values);
  else call_typed(150, bundle->native[11], values, &ret);
  return ret;
}
static bool callback_5_12(int a0, int a1, const clingo_literal_t * a2, size_t a3, void * a4) {
  CallbackBundle *bundle = a4;
  a4 = bundle->data;
  void *values[] = {&a0, &a1, &a2, &a3, &a4};
  bool ret = {0};
  if (bundle->callbacks[12]) callback(bundle->callbacks[12], &ret, values);
  else call_typed(151, bundle->native[12], values, &ret);
  return ret;
}
static bool callback_5_13(clingo_id_t a0, int a1, void * a2) {
  CallbackBundle *bundle = a2;
  a2 = bundle->data;
  void *values[] = {&a0, &a1, &a2};
  bool ret = {0};
  if (bundle->callbacks[13]) callback(bundle->callbacks[13], &ret, values);
  else call_typed(152, bundle->native[13], values, &ret);
  return ret;
}
static bool callback_5_14(clingo_id_t a0, const char * a1, void * a2) {
  CallbackBundle *bundle = a2;
  a2 = bundle->data;
  void *values[] = {&a0, &a1, &a2};
  bool ret = {0};
  if (bundle->callbacks[14]) callback(bundle->callbacks[14], &ret, values);
  else call_typed(153, bundle->native[14], values, &ret);
  return ret;
}
static bool callback_5_15(clingo_id_t a0, int a1, const clingo_id_t * a2, size_t a3, void * a4) {
  CallbackBundle *bundle = a4;
  a4 = bundle->data;
  void *values[] = {&a0, &a1, &a2, &a3, &a4};
  bool ret = {0};
  if (bundle->callbacks[15]) callback(bundle->callbacks[15], &ret, values);
  else call_typed(154, bundle->native[15], values, &ret);
  return ret;
}
static bool callback_5_16(clingo_id_t a0, const clingo_id_t * a1, size_t a2, const clingo_literal_t * a3, size_t a4, void * a5) {
  CallbackBundle *bundle = a5;
  a5 = bundle->data;
  void *values[] = {&a0, &a1, &a2, &a3, &a4, &a5};
  bool ret = {0};
  if (bundle->callbacks[16]) callback(bundle->callbacks[16], &ret, values);
  else call_typed(155, bundle->native[16], values, &ret);
  return ret;
}
static bool callback_5_17(clingo_id_t a0, clingo_id_t a1, const clingo_id_t * a2, size_t a3, void * a4) {
  CallbackBundle *bundle = a4;
  a4 = bundle->data;
  void *values[] = {&a0, &a1, &a2, &a3, &a4};
  bool ret = {0};
  if (bundle->callbacks[17]) callback(bundle->callbacks[17], &ret, values);
  else call_typed(156, bundle->native[17], values, &ret);
  return ret;
}
static bool callback_5_18(clingo_id_t a0, clingo_id_t a1, const clingo_id_t * a2, size_t a3, clingo_id_t a4, clingo_id_t a5, void * a6) {
  CallbackBundle *bundle = a6;
  a6 = bundle->data;
  void *values[] = {&a0, &a1, &a2, &a3, &a4, &a5, &a6};
  bool ret = {0};
  if (bundle->callbacks[18]) callback(bundle->callbacks[18], &ret, values);
  else call_typed(157, bundle->native[18], values, &ret);
  return ret;
}
static bool callback_6_0(clingo_ast_t * a0, void * a1) {
  CallbackBundle *bundle = a1;
  a1 = bundle->data;
  void *values[] = {&a0, &a1};
  bool ret = {0};
  if (bundle->callbacks[0]) callback(bundle->callbacks[0], &ret, values);
  else call_typed(170, bundle->native[0], values, &ret);
  return ret;
}
static void callback_7_0(clingo_warning_t a0, const char * a1, void * a2) {
  CallbackBundle *bundle = a2;
  a2 = bundle->data;
  void *values[] = {&a0, &a1, &a2};
  unsigned char unused = 0;
  if (bundle->callbacks[0]) callback(bundle->callbacks[0], &unused, values);
  else call_typed(23, bundle->native[0], values, &unused);
}
static bool callback_8_0(clingo_ast_t * a0, void * a1) {
  CallbackBundle *bundle = a1;
  a1 = bundle->data;
  void *values[] = {&a0, &a1};
  bool ret = {0};
  if (bundle->callbacks[0]) callback(bundle->callbacks[0], &ret, values);
  else call_typed(170, bundle->native[0], values, &ret);
  return ret;
}
static void callback_9_0(clingo_warning_t a0, const char * a1, void * a2) {
  CallbackBundle *bundle = a2;
  a2 = bundle->data;
  void *values[] = {&a0, &a1, &a2};
  unsigned char unused = 0;
  if (bundle->callbacks[0]) callback(bundle->callbacks[0], &unused, values);
  else call_typed(23, bundle->native[0], values, &unused);
}
static bool callback_10_0(clingo_ast_t * a0, void * a1) {
  CallbackBundle *bundle = a1;
  a1 = bundle->data;
  void *values[] = {&a0, &a1};
  bool ret = {0};
  if (bundle->callbacks[0]) callback(bundle->callbacks[0], &ret, values);
  else call_typed(170, bundle->native[0], values, &ret);
  return ret;
}
static bool callback_11_0(const char * a0, void * a1) {
  CallbackBundle *bundle = a1;
  a1 = bundle->data;
  void *values[] = {&a0, &a1};
  bool ret = {0};
  if (bundle->callbacks[0]) callback(bundle->callbacks[0], &ret, values);
  else call_typed(179, bundle->native[0], values, &ret);
  return ret;
}
static const char * callback_12_0(void * a0) {
  CallbackBundle *bundle = a0;
  a0 = bundle->data;
  void *values[] = {&a0};
  const char * ret = {0};
  if (bundle->callbacks[0]) callback(bundle->callbacks[0], &ret, values);
  else call_typed(183, bundle->native[0], values, &ret);
  return ret;
}
static const char * callback_12_1(void * a0) {
  CallbackBundle *bundle = a0;
  a0 = bundle->data;
  void *values[] = {&a0};
  const char * ret = {0};
  if (bundle->callbacks[1]) callback(bundle->callbacks[1], &ret, values);
  else call_typed(183, bundle->native[1], values, &ret);
  return ret;
}
static unsigned int callback_12_2(void * a0) {
  CallbackBundle *bundle = a0;
  a0 = bundle->data;
  void *values[] = {&a0};
  unsigned int ret = {0};
  if (bundle->callbacks[2]) callback(bundle->callbacks[2], &ret, values);
  else call_typed(184, bundle->native[2], values, &ret);
  return ret;
}
static bool callback_12_3(clingo_control_t * a0, const char *const * a1, size_t a2, void * a3) {
  CallbackBundle *bundle = a3;
  a3 = bundle->data;
  void *values[] = {&a0, &a1, &a2, &a3};
  bool ret = {0};
  if (bundle->callbacks[3]) callback(bundle->callbacks[3], &ret, values);
  else call_typed(186, bundle->native[3], values, &ret);
  return ret;
}
static void callback_12_4(clingo_warning_t a0, const char * a1, void * a2) {
  CallbackBundle *bundle = a2;
  a2 = bundle->data;
  void *values[] = {&a0, &a1, &a2};
  unsigned char unused = 0;
  if (bundle->callbacks[4]) callback(bundle->callbacks[4], &unused, values);
  else call_typed(23, bundle->native[4], values, &unused);
}
static bool callback_12_5(const clingo_model_t * a0, clingo_default_model_printer_t a1, void * a2, void * a3) {
  CallbackBundle *bundle = a3;
  a3 = bundle->data;
  void *values[] = {&a0, &a1, &a2, &a3};
  bool ret = {0};
  if (bundle->callbacks[5]) callback(bundle->callbacks[5], &ret, values);
  else call_typed(188, bundle->native[5], values, &ret);
  return ret;
}
static bool callback_12_6(clingo_options_t * a0, void * a1) {
  CallbackBundle *bundle = a1;
  a1 = bundle->data;
  void *values[] = {&a0, &a1};
  bool ret = {0};
  if (bundle->callbacks[6]) callback(bundle->callbacks[6], &ret, values);
  else call_typed(190, bundle->native[6], values, &ret);
  return ret;
}
static bool callback_12_7(void * a0) {
  CallbackBundle *bundle = a0;
  a0 = bundle->data;
  void *values[] = {&a0};
  bool ret = {0};
  if (bundle->callbacks[7]) callback(bundle->callbacks[7], &ret, values);
  else call_typed(141, bundle->native[7], values, &ret);
  return ret;
}
static bool callback_13_0(const clingo_location_t * a0, const char * a1, void * a2) {
  CallbackBundle *bundle = a2;
  a2 = bundle->data;
  void *values[] = {&a0, &a1, &a2};
  bool ret = {0};
  if (bundle->callbacks[0]) callback(bundle->callbacks[0], &ret, values);
  else call_typed(194, bundle->native[0], values, &ret);
  return ret;
}
static bool callback_13_1(const clingo_location_t * a0, const char * a1, const clingo_symbol_t * a2, size_t a3, clingo_symbol_callback_t a4, void * a5, void * a6) {
  CallbackBundle *bundle = a6;
  a6 = bundle->data;
  void *values[] = {&a0, &a1, &a2, &a3, &a4, &a5, &a6};
  bool ret = {0};
  if (bundle->callbacks[1]) callback(bundle->callbacks[1], &ret, values);
  else call_typed(195, bundle->native[1], values, &ret);
  return ret;
}
static bool callback_13_2(const char * a0, bool * a1, void * a2) {
  CallbackBundle *bundle = a2;
  a2 = bundle->data;
  void *values[] = {&a0, &a1, &a2};
  bool ret = {0};
  if (bundle->callbacks[2]) callback(bundle->callbacks[2], &ret, values);
  else call_typed(196, bundle->native[2], values, &ret);
  return ret;
}
static bool callback_13_3(clingo_control_t * a0, void * a1) {
  CallbackBundle *bundle = a1;
  a1 = bundle->data;
  void *values[] = {&a0, &a1};
  bool ret = {0};
  if (bundle->callbacks[3]) callback(bundle->callbacks[3], &ret, values);
  else call_typed(197, bundle->native[3], values, &ret);
  return ret;
}
static void callback_13_4(void * a0) {
  CallbackBundle *bundle = a0;
  a0 = bundle->data;
  void *values[] = {&a0};
  unsigned char unused = 0;
  if (bundle->callbacks[4]) callback(bundle->callbacks[4], &unused, values);
  else call_typed(198, bundle->native[4], values, &unused);
}
static int adapt_callbacks(Session *s, Function *fn, void **values) {
  if (!strcmp(fn->name, "clingo_parse_term")) {
    if (*(void **)values[1]) {
      Closure *c = find_closure(s, *(void **)values[1]);
      if (c) {
        CallbackBundle *b = bundle_new(s, *(void **)values[2]);
        if (!b) return 0;
        b->callbacks[0] = c;
        *(void **)values[1] = (void *)callback_0_0;
        *(void **)values[2] = b;
      }
    }
  }
  if (!strcmp(fn->name, "clingo_control_new")) {
    if (*(void **)values[2]) {
      Closure *c = find_closure(s, *(void **)values[2]);
      if (c) {
        CallbackBundle *b = bundle_new(s, *(void **)values[3]);
        if (!b) return 0;
        b->callbacks[0] = c;
        *(void **)values[2] = (void *)callback_1_0;
        *(void **)values[3] = b;
      }
    }
  }
  if (!strcmp(fn->name, "clingo_control_ground")) {
    if (*(void **)values[3]) {
      Closure *c = find_closure(s, *(void **)values[3]);
      if (c) {
        CallbackBundle *b = bundle_new(s, *(void **)values[4]);
        if (!b) return 0;
        b->callbacks[0] = c;
        *(void **)values[3] = (void *)callback_2_0;
        *(void **)values[4] = b;
      }
    }
  }
  if (!strcmp(fn->name, "clingo_control_solve")) {
    if (*(void **)values[4]) {
      Closure *c = find_closure(s, *(void **)values[4]);
      if (c) {
        CallbackBundle *b = bundle_new(s, *(void **)values[5]);
        if (!b) return 0;
        b->callbacks[0] = c;
        *(void **)values[4] = (void *)callback_3_0;
        *(void **)values[5] = b;
      }
    }
  }
  if (!strcmp(fn->name, "clingo_control_register_propagator")) {
    if (*(void **)values[1]) {
      struct clingo_propagator *original = *(void **)values[1];
      int needed = 0;
      needed |= find_closure(s, (void *)original->init) != NULL;
      needed |= find_closure(s, (void *)original->propagate) != NULL;
      needed |= find_closure(s, (void *)original->undo) != NULL;
      needed |= find_closure(s, (void *)original->check) != NULL;
      needed |= find_closure(s, (void *)original->decide) != NULL;
      if (needed) {
        CallbackBundle *b = bundle_new(s, *(void **)values[2]);
        struct clingo_propagator *copy = retain_bytes(s, sizeof(*copy));
        if (!b || !copy) return 0;
        *copy = *original;
        b->callbacks[0] = find_closure(s, (void *)original->init);
        b->native[0] = (void (*)(void))original->init;
        if (original->init) copy->init = callback_4_0;
        b->callbacks[1] = find_closure(s, (void *)original->propagate);
        b->native[1] = (void (*)(void))original->propagate;
        if (original->propagate) copy->propagate = callback_4_1;
        b->callbacks[2] = find_closure(s, (void *)original->undo);
        b->native[2] = (void (*)(void))original->undo;
        if (original->undo) copy->undo = callback_4_2;
        b->callbacks[3] = find_closure(s, (void *)original->check);
        b->native[3] = (void (*)(void))original->check;
        if (original->check) copy->check = callback_4_3;
        b->callbacks[4] = find_closure(s, (void *)original->decide);
        b->native[4] = (void (*)(void))original->decide;
        if (original->decide) copy->decide = callback_4_4;
        *(void **)values[1] = copy;
        *(void **)values[2] = b;
      }
    }
  }
  if (!strcmp(fn->name, "clingo_control_register_observer")) {
    if (*(void **)values[1]) {
      struct clingo_ground_program_observer *original = *(void **)values[1];
      int needed = 0;
      needed |= find_closure(s, (void *)original->init_program) != NULL;
      needed |= find_closure(s, (void *)original->begin_step) != NULL;
      needed |= find_closure(s, (void *)original->end_step) != NULL;
      needed |= find_closure(s, (void *)original->rule) != NULL;
      needed |= find_closure(s, (void *)original->weight_rule) != NULL;
      needed |= find_closure(s, (void *)original->minimize) != NULL;
      needed |= find_closure(s, (void *)original->project) != NULL;
      needed |= find_closure(s, (void *)original->output_atom) != NULL;
      needed |= find_closure(s, (void *)original->output_term) != NULL;
      needed |= find_closure(s, (void *)original->external) != NULL;
      needed |= find_closure(s, (void *)original->assume) != NULL;
      needed |= find_closure(s, (void *)original->heuristic) != NULL;
      needed |= find_closure(s, (void *)original->acyc_edge) != NULL;
      needed |= find_closure(s, (void *)original->theory_term_number) != NULL;
      needed |= find_closure(s, (void *)original->theory_term_string) != NULL;
      needed |= find_closure(s, (void *)original->theory_term_compound) != NULL;
      needed |= find_closure(s, (void *)original->theory_element) != NULL;
      needed |= find_closure(s, (void *)original->theory_atom) != NULL;
      needed |= find_closure(s, (void *)original->theory_atom_with_guard) != NULL;
      if (needed) {
        CallbackBundle *b = bundle_new(s, *(void **)values[3]);
        struct clingo_ground_program_observer *copy = retain_bytes(s, sizeof(*copy));
        if (!b || !copy) return 0;
        *copy = *original;
        b->callbacks[0] = find_closure(s, (void *)original->init_program);
        b->native[0] = (void (*)(void))original->init_program;
        if (original->init_program) copy->init_program = callback_5_0;
        b->callbacks[1] = find_closure(s, (void *)original->begin_step);
        b->native[1] = (void (*)(void))original->begin_step;
        if (original->begin_step) copy->begin_step = callback_5_1;
        b->callbacks[2] = find_closure(s, (void *)original->end_step);
        b->native[2] = (void (*)(void))original->end_step;
        if (original->end_step) copy->end_step = callback_5_2;
        b->callbacks[3] = find_closure(s, (void *)original->rule);
        b->native[3] = (void (*)(void))original->rule;
        if (original->rule) copy->rule = callback_5_3;
        b->callbacks[4] = find_closure(s, (void *)original->weight_rule);
        b->native[4] = (void (*)(void))original->weight_rule;
        if (original->weight_rule) copy->weight_rule = callback_5_4;
        b->callbacks[5] = find_closure(s, (void *)original->minimize);
        b->native[5] = (void (*)(void))original->minimize;
        if (original->minimize) copy->minimize = callback_5_5;
        b->callbacks[6] = find_closure(s, (void *)original->project);
        b->native[6] = (void (*)(void))original->project;
        if (original->project) copy->project = callback_5_6;
        b->callbacks[7] = find_closure(s, (void *)original->output_atom);
        b->native[7] = (void (*)(void))original->output_atom;
        if (original->output_atom) copy->output_atom = callback_5_7;
        b->callbacks[8] = find_closure(s, (void *)original->output_term);
        b->native[8] = (void (*)(void))original->output_term;
        if (original->output_term) copy->output_term = callback_5_8;
        b->callbacks[9] = find_closure(s, (void *)original->external);
        b->native[9] = (void (*)(void))original->external;
        if (original->external) copy->external = callback_5_9;
        b->callbacks[10] = find_closure(s, (void *)original->assume);
        b->native[10] = (void (*)(void))original->assume;
        if (original->assume) copy->assume = callback_5_10;
        b->callbacks[11] = find_closure(s, (void *)original->heuristic);
        b->native[11] = (void (*)(void))original->heuristic;
        if (original->heuristic) copy->heuristic = callback_5_11;
        b->callbacks[12] = find_closure(s, (void *)original->acyc_edge);
        b->native[12] = (void (*)(void))original->acyc_edge;
        if (original->acyc_edge) copy->acyc_edge = callback_5_12;
        b->callbacks[13] = find_closure(s, (void *)original->theory_term_number);
        b->native[13] = (void (*)(void))original->theory_term_number;
        if (original->theory_term_number) copy->theory_term_number = callback_5_13;
        b->callbacks[14] = find_closure(s, (void *)original->theory_term_string);
        b->native[14] = (void (*)(void))original->theory_term_string;
        if (original->theory_term_string) copy->theory_term_string = callback_5_14;
        b->callbacks[15] = find_closure(s, (void *)original->theory_term_compound);
        b->native[15] = (void (*)(void))original->theory_term_compound;
        if (original->theory_term_compound) copy->theory_term_compound = callback_5_15;
        b->callbacks[16] = find_closure(s, (void *)original->theory_element);
        b->native[16] = (void (*)(void))original->theory_element;
        if (original->theory_element) copy->theory_element = callback_5_16;
        b->callbacks[17] = find_closure(s, (void *)original->theory_atom);
        b->native[17] = (void (*)(void))original->theory_atom;
        if (original->theory_atom) copy->theory_atom = callback_5_17;
        b->callbacks[18] = find_closure(s, (void *)original->theory_atom_with_guard);
        b->native[18] = (void (*)(void))original->theory_atom_with_guard;
        if (original->theory_atom_with_guard) copy->theory_atom_with_guard = callback_5_18;
        *(void **)values[1] = copy;
        *(void **)values[3] = b;
      }
    }
  }
  if (!strcmp(fn->name, "clingo_ast_parse_string")) {
    if (*(void **)values[1]) {
      Closure *c = find_closure(s, *(void **)values[1]);
      if (c) {
        CallbackBundle *b = bundle_new(s, *(void **)values[2]);
        if (!b) return 0;
        b->callbacks[0] = c;
        *(void **)values[1] = (void *)callback_6_0;
        *(void **)values[2] = b;
      }
    }
  }
  if (!strcmp(fn->name, "clingo_ast_parse_string")) {
    if (*(void **)values[4]) {
      Closure *c = find_closure(s, *(void **)values[4]);
      if (c) {
        CallbackBundle *b = bundle_new(s, *(void **)values[5]);
        if (!b) return 0;
        b->callbacks[0] = c;
        *(void **)values[4] = (void *)callback_7_0;
        *(void **)values[5] = b;
      }
    }
  }
  if (!strcmp(fn->name, "clingo_ast_parse_files")) {
    if (*(void **)values[2]) {
      Closure *c = find_closure(s, *(void **)values[2]);
      if (c) {
        CallbackBundle *b = bundle_new(s, *(void **)values[3]);
        if (!b) return 0;
        b->callbacks[0] = c;
        *(void **)values[2] = (void *)callback_8_0;
        *(void **)values[3] = b;
      }
    }
  }
  if (!strcmp(fn->name, "clingo_ast_parse_files")) {
    if (*(void **)values[5]) {
      Closure *c = find_closure(s, *(void **)values[5]);
      if (c) {
        CallbackBundle *b = bundle_new(s, *(void **)values[6]);
        if (!b) return 0;
        b->callbacks[0] = c;
        *(void **)values[5] = (void *)callback_9_0;
        *(void **)values[6] = b;
      }
    }
  }
  if (!strcmp(fn->name, "clingo_ast_unpool")) {
    if (*(void **)values[2]) {
      Closure *c = find_closure(s, *(void **)values[2]);
      if (c) {
        CallbackBundle *b = bundle_new(s, *(void **)values[3]);
        if (!b) return 0;
        b->callbacks[0] = c;
        *(void **)values[2] = (void *)callback_10_0;
        *(void **)values[3] = b;
      }
    }
  }
  if (!strcmp(fn->name, "clingo_options_add")) {
    if (*(void **)values[4]) {
      Closure *c = find_closure(s, *(void **)values[4]);
      if (c) {
        CallbackBundle *b = bundle_new(s, *(void **)values[5]);
        if (!b) return 0;
        b->callbacks[0] = c;
        *(void **)values[4] = (void *)callback_11_0;
        *(void **)values[5] = b;
      }
    }
  }
  if (!strcmp(fn->name, "clingo_main")) {
    if (*(void **)values[0]) {
      struct clingo_application *original = *(void **)values[0];
      int needed = 0;
      needed |= find_closure(s, (void *)original->program_name) != NULL;
      needed |= find_closure(s, (void *)original->version) != NULL;
      needed |= find_closure(s, (void *)original->message_limit) != NULL;
      needed |= find_closure(s, (void *)original->main) != NULL;
      needed |= find_closure(s, (void *)original->logger) != NULL;
      needed |= find_closure(s, (void *)original->printer) != NULL;
      needed |= find_closure(s, (void *)original->register_options) != NULL;
      needed |= find_closure(s, (void *)original->validate_options) != NULL;
      if (needed) {
        CallbackBundle *b = bundle_new(s, *(void **)values[3]);
        struct clingo_application *copy = retain_bytes(s, sizeof(*copy));
        if (!b || !copy) return 0;
        *copy = *original;
        b->callbacks[0] = find_closure(s, (void *)original->program_name);
        b->native[0] = (void (*)(void))original->program_name;
        if (original->program_name) copy->program_name = callback_12_0;
        b->callbacks[1] = find_closure(s, (void *)original->version);
        b->native[1] = (void (*)(void))original->version;
        if (original->version) copy->version = callback_12_1;
        b->callbacks[2] = find_closure(s, (void *)original->message_limit);
        b->native[2] = (void (*)(void))original->message_limit;
        if (original->message_limit) copy->message_limit = callback_12_2;
        b->callbacks[3] = find_closure(s, (void *)original->main);
        b->native[3] = (void (*)(void))original->main;
        if (original->main) copy->main = callback_12_3;
        b->callbacks[4] = find_closure(s, (void *)original->logger);
        b->native[4] = (void (*)(void))original->logger;
        if (original->logger) copy->logger = callback_12_4;
        b->callbacks[5] = find_closure(s, (void *)original->printer);
        b->native[5] = (void (*)(void))original->printer;
        if (original->printer) copy->printer = callback_12_5;
        b->callbacks[6] = find_closure(s, (void *)original->register_options);
        b->native[6] = (void (*)(void))original->register_options;
        if (original->register_options) copy->register_options = callback_12_6;
        b->callbacks[7] = find_closure(s, (void *)original->validate_options);
        b->native[7] = (void (*)(void))original->validate_options;
        if (original->validate_options) copy->validate_options = callback_12_7;
        *(void **)values[0] = copy;
        *(void **)values[3] = b;
      }
    }
  }
  if (!strcmp(fn->name, "clingo_register_script")) {
    if (*(void **)values[1]) {
      struct clingo_script *original = *(void **)values[1];
      int needed = 0;
      needed |= find_closure(s, (void *)original->execute) != NULL;
      needed |= find_closure(s, (void *)original->call) != NULL;
      needed |= find_closure(s, (void *)original->callable) != NULL;
      needed |= find_closure(s, (void *)original->main) != NULL;
      needed |= find_closure(s, (void *)original->free) != NULL;
      if (needed) {
        CallbackBundle *b = bundle_new(s, *(void **)values[2]);
        struct clingo_script *copy = retain_bytes(s, sizeof(*copy));
        if (!b || !copy) return 0;
        *copy = *original;
        b->callbacks[0] = find_closure(s, (void *)original->execute);
        b->native[0] = (void (*)(void))original->execute;
        if (original->execute) copy->execute = callback_13_0;
        b->callbacks[1] = find_closure(s, (void *)original->call);
        b->native[1] = (void (*)(void))original->call;
        if (original->call) copy->call = callback_13_1;
        b->callbacks[2] = find_closure(s, (void *)original->callable);
        b->native[2] = (void (*)(void))original->callable;
        if (original->callable) copy->callable = callback_13_2;
        b->callbacks[3] = find_closure(s, (void *)original->main);
        b->native[3] = (void (*)(void))original->main;
        if (original->main) copy->main = callback_13_3;
        b->callbacks[4] = find_closure(s, (void *)original->free);
        b->native[4] = (void (*)(void))original->free;
        if (original->free) copy->free = callback_13_4;
        *(void **)values[1] = copy;
        *(void **)values[2] = b;
      }
    }
  }
  return 1;
}
static int ast_metadata_matches(void) {
  if (g_clingo_ast_constructors.size != 46) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[0].name, "id") || g_clingo_ast_constructors.constructors[0].size != 2) return 0;
  if (g_clingo_ast_constructors.constructors[0].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[0].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[0].arguments[1].attribute != 25 || g_clingo_ast_constructors.constructors[0].arguments[1].type != 3 || strcmp(g_clingo_ast_attribute_names.names[25], "name")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[1].name, "variable") || g_clingo_ast_constructors.constructors[1].size != 2) return 0;
  if (g_clingo_ast_constructors.constructors[1].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[1].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[1].arguments[1].attribute != 25 || g_clingo_ast_constructors.constructors[1].arguments[1].type != 3 || strcmp(g_clingo_ast_attribute_names.names[25], "name")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[2].name, "symbolic_term") || g_clingo_ast_constructors.constructors[2].size != 2) return 0;
  if (g_clingo_ast_constructors.constructors[2].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[2].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[2].arguments[1].attribute != 38 || g_clingo_ast_constructors.constructors[2].arguments[1].type != 1 || strcmp(g_clingo_ast_attribute_names.names[38], "symbol")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[3].name, "unary_operation") || g_clingo_ast_constructors.constructors[3].size != 3) return 0;
  if (g_clingo_ast_constructors.constructors[3].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[3].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[3].arguments[1].attribute != 29 || g_clingo_ast_constructors.constructors[3].arguments[1].type != 0 || strcmp(g_clingo_ast_attribute_names.names[29], "operator_type")) return 0;
  if (g_clingo_ast_constructors.constructors[3].arguments[2].attribute != 0 || g_clingo_ast_constructors.constructors[3].arguments[2].type != 4 || strcmp(g_clingo_ast_attribute_names.names[0], "argument")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[4].name, "binary_operation") || g_clingo_ast_constructors.constructors[4].size != 4) return 0;
  if (g_clingo_ast_constructors.constructors[4].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[4].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[4].arguments[1].attribute != 29 || g_clingo_ast_constructors.constructors[4].arguments[1].type != 0 || strcmp(g_clingo_ast_attribute_names.names[29], "operator_type")) return 0;
  if (g_clingo_ast_constructors.constructors[4].arguments[2].attribute != 20 || g_clingo_ast_constructors.constructors[4].arguments[2].type != 4 || strcmp(g_clingo_ast_attribute_names.names[20], "left")) return 0;
  if (g_clingo_ast_constructors.constructors[4].arguments[3].attribute != 34 || g_clingo_ast_constructors.constructors[4].arguments[3].type != 4 || strcmp(g_clingo_ast_attribute_names.names[34], "right")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[5].name, "interval") || g_clingo_ast_constructors.constructors[5].size != 3) return 0;
  if (g_clingo_ast_constructors.constructors[5].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[5].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[5].arguments[1].attribute != 20 || g_clingo_ast_constructors.constructors[5].arguments[1].type != 4 || strcmp(g_clingo_ast_attribute_names.names[20], "left")) return 0;
  if (g_clingo_ast_constructors.constructors[5].arguments[2].attribute != 34 || g_clingo_ast_constructors.constructors[5].arguments[2].type != 4 || strcmp(g_clingo_ast_attribute_names.names[34], "right")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[6].name, "function") || g_clingo_ast_constructors.constructors[6].size != 4) return 0;
  if (g_clingo_ast_constructors.constructors[6].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[6].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[6].arguments[1].attribute != 25 || g_clingo_ast_constructors.constructors[6].arguments[1].type != 3 || strcmp(g_clingo_ast_attribute_names.names[25], "name")) return 0;
  if (g_clingo_ast_constructors.constructors[6].arguments[2].attribute != 1 || g_clingo_ast_constructors.constructors[6].arguments[2].type != 7 || strcmp(g_clingo_ast_attribute_names.names[1], "arguments")) return 0;
  if (g_clingo_ast_constructors.constructors[6].arguments[3].attribute != 13 || g_clingo_ast_constructors.constructors[6].arguments[3].type != 0 || strcmp(g_clingo_ast_attribute_names.names[13], "external")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[7].name, "pool") || g_clingo_ast_constructors.constructors[7].size != 2) return 0;
  if (g_clingo_ast_constructors.constructors[7].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[7].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[7].arguments[1].attribute != 1 || g_clingo_ast_constructors.constructors[7].arguments[1].type != 7 || strcmp(g_clingo_ast_attribute_names.names[1], "arguments")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[8].name, "boolean_constant") || g_clingo_ast_constructors.constructors[8].size != 1) return 0;
  if (g_clingo_ast_constructors.constructors[8].arguments[0].attribute != 41 || g_clingo_ast_constructors.constructors[8].arguments[0].type != 0 || strcmp(g_clingo_ast_attribute_names.names[41], "value")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[9].name, "symbolic_atom") || g_clingo_ast_constructors.constructors[9].size != 1) return 0;
  if (g_clingo_ast_constructors.constructors[9].arguments[0].attribute != 38 || g_clingo_ast_constructors.constructors[9].arguments[0].type != 4 || strcmp(g_clingo_ast_attribute_names.names[38], "symbol")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[10].name, "comparison") || g_clingo_ast_constructors.constructors[10].size != 2) return 0;
  if (g_clingo_ast_constructors.constructors[10].arguments[0].attribute != 39 || g_clingo_ast_constructors.constructors[10].arguments[0].type != 4 || strcmp(g_clingo_ast_attribute_names.names[39], "term")) return 0;
  if (g_clingo_ast_constructors.constructors[10].arguments[1].attribute != 17 || g_clingo_ast_constructors.constructors[10].arguments[1].type != 7 || strcmp(g_clingo_ast_attribute_names.names[17], "guards")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[11].name, "guard") || g_clingo_ast_constructors.constructors[11].size != 2) return 0;
  if (g_clingo_ast_constructors.constructors[11].arguments[0].attribute != 10 || g_clingo_ast_constructors.constructors[11].arguments[0].type != 0 || strcmp(g_clingo_ast_attribute_names.names[10], "comparison")) return 0;
  if (g_clingo_ast_constructors.constructors[11].arguments[1].attribute != 39 || g_clingo_ast_constructors.constructors[11].arguments[1].type != 4 || strcmp(g_clingo_ast_attribute_names.names[39], "term")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[12].name, "conditional_literal") || g_clingo_ast_constructors.constructors[12].size != 3) return 0;
  if (g_clingo_ast_constructors.constructors[12].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[12].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[12].arguments[1].attribute != 22 || g_clingo_ast_constructors.constructors[12].arguments[1].type != 4 || strcmp(g_clingo_ast_attribute_names.names[22], "literal")) return 0;
  if (g_clingo_ast_constructors.constructors[12].arguments[2].attribute != 11 || g_clingo_ast_constructors.constructors[12].arguments[2].type != 7 || strcmp(g_clingo_ast_attribute_names.names[11], "condition")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[13].name, "aggregate") || g_clingo_ast_constructors.constructors[13].size != 4) return 0;
  if (g_clingo_ast_constructors.constructors[13].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[13].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[13].arguments[1].attribute != 21 || g_clingo_ast_constructors.constructors[13].arguments[1].type != 5 || strcmp(g_clingo_ast_attribute_names.names[21], "left_guard")) return 0;
  if (g_clingo_ast_constructors.constructors[13].arguments[2].attribute != 12 || g_clingo_ast_constructors.constructors[13].arguments[2].type != 7 || strcmp(g_clingo_ast_attribute_names.names[12], "elements")) return 0;
  if (g_clingo_ast_constructors.constructors[13].arguments[3].attribute != 35 || g_clingo_ast_constructors.constructors[13].arguments[3].type != 5 || strcmp(g_clingo_ast_attribute_names.names[35], "right_guard")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[14].name, "body_aggregate_element") || g_clingo_ast_constructors.constructors[14].size != 2) return 0;
  if (g_clingo_ast_constructors.constructors[14].arguments[0].attribute != 40 || g_clingo_ast_constructors.constructors[14].arguments[0].type != 7 || strcmp(g_clingo_ast_attribute_names.names[40], "terms")) return 0;
  if (g_clingo_ast_constructors.constructors[14].arguments[1].attribute != 11 || g_clingo_ast_constructors.constructors[14].arguments[1].type != 7 || strcmp(g_clingo_ast_attribute_names.names[11], "condition")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[15].name, "body_aggregate") || g_clingo_ast_constructors.constructors[15].size != 5) return 0;
  if (g_clingo_ast_constructors.constructors[15].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[15].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[15].arguments[1].attribute != 21 || g_clingo_ast_constructors.constructors[15].arguments[1].type != 5 || strcmp(g_clingo_ast_attribute_names.names[21], "left_guard")) return 0;
  if (g_clingo_ast_constructors.constructors[15].arguments[2].attribute != 15 || g_clingo_ast_constructors.constructors[15].arguments[2].type != 0 || strcmp(g_clingo_ast_attribute_names.names[15], "function")) return 0;
  if (g_clingo_ast_constructors.constructors[15].arguments[3].attribute != 12 || g_clingo_ast_constructors.constructors[15].arguments[3].type != 7 || strcmp(g_clingo_ast_attribute_names.names[12], "elements")) return 0;
  if (g_clingo_ast_constructors.constructors[15].arguments[4].attribute != 35 || g_clingo_ast_constructors.constructors[15].arguments[4].type != 5 || strcmp(g_clingo_ast_attribute_names.names[35], "right_guard")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[16].name, "head_aggregate_element") || g_clingo_ast_constructors.constructors[16].size != 2) return 0;
  if (g_clingo_ast_constructors.constructors[16].arguments[0].attribute != 40 || g_clingo_ast_constructors.constructors[16].arguments[0].type != 7 || strcmp(g_clingo_ast_attribute_names.names[40], "terms")) return 0;
  if (g_clingo_ast_constructors.constructors[16].arguments[1].attribute != 11 || g_clingo_ast_constructors.constructors[16].arguments[1].type != 4 || strcmp(g_clingo_ast_attribute_names.names[11], "condition")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[17].name, "head_aggregate") || g_clingo_ast_constructors.constructors[17].size != 5) return 0;
  if (g_clingo_ast_constructors.constructors[17].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[17].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[17].arguments[1].attribute != 21 || g_clingo_ast_constructors.constructors[17].arguments[1].type != 5 || strcmp(g_clingo_ast_attribute_names.names[21], "left_guard")) return 0;
  if (g_clingo_ast_constructors.constructors[17].arguments[2].attribute != 15 || g_clingo_ast_constructors.constructors[17].arguments[2].type != 0 || strcmp(g_clingo_ast_attribute_names.names[15], "function")) return 0;
  if (g_clingo_ast_constructors.constructors[17].arguments[3].attribute != 12 || g_clingo_ast_constructors.constructors[17].arguments[3].type != 7 || strcmp(g_clingo_ast_attribute_names.names[12], "elements")) return 0;
  if (g_clingo_ast_constructors.constructors[17].arguments[4].attribute != 35 || g_clingo_ast_constructors.constructors[17].arguments[4].type != 5 || strcmp(g_clingo_ast_attribute_names.names[35], "right_guard")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[18].name, "disjunction") || g_clingo_ast_constructors.constructors[18].size != 2) return 0;
  if (g_clingo_ast_constructors.constructors[18].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[18].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[18].arguments[1].attribute != 12 || g_clingo_ast_constructors.constructors[18].arguments[1].type != 7 || strcmp(g_clingo_ast_attribute_names.names[12], "elements")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[19].name, "theory_sequence") || g_clingo_ast_constructors.constructors[19].size != 3) return 0;
  if (g_clingo_ast_constructors.constructors[19].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[19].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[19].arguments[1].attribute != 36 || g_clingo_ast_constructors.constructors[19].arguments[1].type != 0 || strcmp(g_clingo_ast_attribute_names.names[36], "sequence_type")) return 0;
  if (g_clingo_ast_constructors.constructors[19].arguments[2].attribute != 40 || g_clingo_ast_constructors.constructors[19].arguments[2].type != 7 || strcmp(g_clingo_ast_attribute_names.names[40], "terms")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[20].name, "theory_function") || g_clingo_ast_constructors.constructors[20].size != 3) return 0;
  if (g_clingo_ast_constructors.constructors[20].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[20].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[20].arguments[1].attribute != 25 || g_clingo_ast_constructors.constructors[20].arguments[1].type != 3 || strcmp(g_clingo_ast_attribute_names.names[25], "name")) return 0;
  if (g_clingo_ast_constructors.constructors[20].arguments[2].attribute != 1 || g_clingo_ast_constructors.constructors[20].arguments[2].type != 7 || strcmp(g_clingo_ast_attribute_names.names[1], "arguments")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[21].name, "theory_unparsed_term_element") || g_clingo_ast_constructors.constructors[21].size != 2) return 0;
  if (g_clingo_ast_constructors.constructors[21].arguments[0].attribute != 30 || g_clingo_ast_constructors.constructors[21].arguments[0].type != 6 || strcmp(g_clingo_ast_attribute_names.names[30], "operators")) return 0;
  if (g_clingo_ast_constructors.constructors[21].arguments[1].attribute != 39 || g_clingo_ast_constructors.constructors[21].arguments[1].type != 4 || strcmp(g_clingo_ast_attribute_names.names[39], "term")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[22].name, "theory_unparsed_term") || g_clingo_ast_constructors.constructors[22].size != 2) return 0;
  if (g_clingo_ast_constructors.constructors[22].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[22].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[22].arguments[1].attribute != 12 || g_clingo_ast_constructors.constructors[22].arguments[1].type != 7 || strcmp(g_clingo_ast_attribute_names.names[12], "elements")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[23].name, "theory_guard") || g_clingo_ast_constructors.constructors[23].size != 2) return 0;
  if (g_clingo_ast_constructors.constructors[23].arguments[0].attribute != 28 || g_clingo_ast_constructors.constructors[23].arguments[0].type != 3 || strcmp(g_clingo_ast_attribute_names.names[28], "operator_name")) return 0;
  if (g_clingo_ast_constructors.constructors[23].arguments[1].attribute != 39 || g_clingo_ast_constructors.constructors[23].arguments[1].type != 4 || strcmp(g_clingo_ast_attribute_names.names[39], "term")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[24].name, "theory_atom_element") || g_clingo_ast_constructors.constructors[24].size != 2) return 0;
  if (g_clingo_ast_constructors.constructors[24].arguments[0].attribute != 40 || g_clingo_ast_constructors.constructors[24].arguments[0].type != 7 || strcmp(g_clingo_ast_attribute_names.names[40], "terms")) return 0;
  if (g_clingo_ast_constructors.constructors[24].arguments[1].attribute != 11 || g_clingo_ast_constructors.constructors[24].arguments[1].type != 7 || strcmp(g_clingo_ast_attribute_names.names[11], "condition")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[25].name, "theory_atom") || g_clingo_ast_constructors.constructors[25].size != 4) return 0;
  if (g_clingo_ast_constructors.constructors[25].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[25].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[25].arguments[1].attribute != 39 || g_clingo_ast_constructors.constructors[25].arguments[1].type != 4 || strcmp(g_clingo_ast_attribute_names.names[39], "term")) return 0;
  if (g_clingo_ast_constructors.constructors[25].arguments[2].attribute != 12 || g_clingo_ast_constructors.constructors[25].arguments[2].type != 7 || strcmp(g_clingo_ast_attribute_names.names[12], "elements")) return 0;
  if (g_clingo_ast_constructors.constructors[25].arguments[3].attribute != 16 || g_clingo_ast_constructors.constructors[25].arguments[3].type != 5 || strcmp(g_clingo_ast_attribute_names.names[16], "guard")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[26].name, "literal") || g_clingo_ast_constructors.constructors[26].size != 3) return 0;
  if (g_clingo_ast_constructors.constructors[26].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[26].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[26].arguments[1].attribute != 37 || g_clingo_ast_constructors.constructors[26].arguments[1].type != 0 || strcmp(g_clingo_ast_attribute_names.names[37], "sign")) return 0;
  if (g_clingo_ast_constructors.constructors[26].arguments[2].attribute != 3 || g_clingo_ast_constructors.constructors[26].arguments[2].type != 4 || strcmp(g_clingo_ast_attribute_names.names[3], "atom")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[27].name, "theory_operator_definition") || g_clingo_ast_constructors.constructors[27].size != 4) return 0;
  if (g_clingo_ast_constructors.constructors[27].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[27].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[27].arguments[1].attribute != 25 || g_clingo_ast_constructors.constructors[27].arguments[1].type != 3 || strcmp(g_clingo_ast_attribute_names.names[25], "name")) return 0;
  if (g_clingo_ast_constructors.constructors[27].arguments[2].attribute != 33 || g_clingo_ast_constructors.constructors[27].arguments[2].type != 0 || strcmp(g_clingo_ast_attribute_names.names[33], "priority")) return 0;
  if (g_clingo_ast_constructors.constructors[27].arguments[3].attribute != 29 || g_clingo_ast_constructors.constructors[27].arguments[3].type != 0 || strcmp(g_clingo_ast_attribute_names.names[29], "operator_type")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[28].name, "theory_term_definition") || g_clingo_ast_constructors.constructors[28].size != 3) return 0;
  if (g_clingo_ast_constructors.constructors[28].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[28].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[28].arguments[1].attribute != 25 || g_clingo_ast_constructors.constructors[28].arguments[1].type != 3 || strcmp(g_clingo_ast_attribute_names.names[25], "name")) return 0;
  if (g_clingo_ast_constructors.constructors[28].arguments[2].attribute != 30 || g_clingo_ast_constructors.constructors[28].arguments[2].type != 7 || strcmp(g_clingo_ast_attribute_names.names[30], "operators")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[29].name, "theory_guard_definition") || g_clingo_ast_constructors.constructors[29].size != 2) return 0;
  if (g_clingo_ast_constructors.constructors[29].arguments[0].attribute != 30 || g_clingo_ast_constructors.constructors[29].arguments[0].type != 6 || strcmp(g_clingo_ast_attribute_names.names[30], "operators")) return 0;
  if (g_clingo_ast_constructors.constructors[29].arguments[1].attribute != 39 || g_clingo_ast_constructors.constructors[29].arguments[1].type != 3 || strcmp(g_clingo_ast_attribute_names.names[39], "term")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[30].name, "theory_atom_definition") || g_clingo_ast_constructors.constructors[30].size != 6) return 0;
  if (g_clingo_ast_constructors.constructors[30].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[30].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[30].arguments[1].attribute != 5 || g_clingo_ast_constructors.constructors[30].arguments[1].type != 0 || strcmp(g_clingo_ast_attribute_names.names[5], "atom_type")) return 0;
  if (g_clingo_ast_constructors.constructors[30].arguments[2].attribute != 25 || g_clingo_ast_constructors.constructors[30].arguments[2].type != 3 || strcmp(g_clingo_ast_attribute_names.names[25], "name")) return 0;
  if (g_clingo_ast_constructors.constructors[30].arguments[3].attribute != 2 || g_clingo_ast_constructors.constructors[30].arguments[3].type != 0 || strcmp(g_clingo_ast_attribute_names.names[2], "arity")) return 0;
  if (g_clingo_ast_constructors.constructors[30].arguments[4].attribute != 39 || g_clingo_ast_constructors.constructors[30].arguments[4].type != 3 || strcmp(g_clingo_ast_attribute_names.names[39], "term")) return 0;
  if (g_clingo_ast_constructors.constructors[30].arguments[5].attribute != 16 || g_clingo_ast_constructors.constructors[30].arguments[5].type != 5 || strcmp(g_clingo_ast_attribute_names.names[16], "guard")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[31].name, "rule") || g_clingo_ast_constructors.constructors[31].size != 3) return 0;
  if (g_clingo_ast_constructors.constructors[31].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[31].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[31].arguments[1].attribute != 18 || g_clingo_ast_constructors.constructors[31].arguments[1].type != 4 || strcmp(g_clingo_ast_attribute_names.names[18], "head")) return 0;
  if (g_clingo_ast_constructors.constructors[31].arguments[2].attribute != 7 || g_clingo_ast_constructors.constructors[31].arguments[2].type != 7 || strcmp(g_clingo_ast_attribute_names.names[7], "body")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[32].name, "definition") || g_clingo_ast_constructors.constructors[32].size != 4) return 0;
  if (g_clingo_ast_constructors.constructors[32].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[32].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[32].arguments[1].attribute != 25 || g_clingo_ast_constructors.constructors[32].arguments[1].type != 3 || strcmp(g_clingo_ast_attribute_names.names[25], "name")) return 0;
  if (g_clingo_ast_constructors.constructors[32].arguments[2].attribute != 41 || g_clingo_ast_constructors.constructors[32].arguments[2].type != 4 || strcmp(g_clingo_ast_attribute_names.names[41], "value")) return 0;
  if (g_clingo_ast_constructors.constructors[32].arguments[3].attribute != 19 || g_clingo_ast_constructors.constructors[32].arguments[3].type != 0 || strcmp(g_clingo_ast_attribute_names.names[19], "is_default")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[33].name, "show_signature") || g_clingo_ast_constructors.constructors[33].size != 4) return 0;
  if (g_clingo_ast_constructors.constructors[33].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[33].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[33].arguments[1].attribute != 25 || g_clingo_ast_constructors.constructors[33].arguments[1].type != 3 || strcmp(g_clingo_ast_attribute_names.names[25], "name")) return 0;
  if (g_clingo_ast_constructors.constructors[33].arguments[2].attribute != 2 || g_clingo_ast_constructors.constructors[33].arguments[2].type != 0 || strcmp(g_clingo_ast_attribute_names.names[2], "arity")) return 0;
  if (g_clingo_ast_constructors.constructors[33].arguments[3].attribute != 32 || g_clingo_ast_constructors.constructors[33].arguments[3].type != 0 || strcmp(g_clingo_ast_attribute_names.names[32], "positive")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[34].name, "show_term") || g_clingo_ast_constructors.constructors[34].size != 3) return 0;
  if (g_clingo_ast_constructors.constructors[34].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[34].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[34].arguments[1].attribute != 39 || g_clingo_ast_constructors.constructors[34].arguments[1].type != 4 || strcmp(g_clingo_ast_attribute_names.names[39], "term")) return 0;
  if (g_clingo_ast_constructors.constructors[34].arguments[2].attribute != 7 || g_clingo_ast_constructors.constructors[34].arguments[2].type != 7 || strcmp(g_clingo_ast_attribute_names.names[7], "body")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[35].name, "minimize") || g_clingo_ast_constructors.constructors[35].size != 5) return 0;
  if (g_clingo_ast_constructors.constructors[35].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[35].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[35].arguments[1].attribute != 43 || g_clingo_ast_constructors.constructors[35].arguments[1].type != 4 || strcmp(g_clingo_ast_attribute_names.names[43], "weight")) return 0;
  if (g_clingo_ast_constructors.constructors[35].arguments[2].attribute != 33 || g_clingo_ast_constructors.constructors[35].arguments[2].type != 4 || strcmp(g_clingo_ast_attribute_names.names[33], "priority")) return 0;
  if (g_clingo_ast_constructors.constructors[35].arguments[3].attribute != 40 || g_clingo_ast_constructors.constructors[35].arguments[3].type != 7 || strcmp(g_clingo_ast_attribute_names.names[40], "terms")) return 0;
  if (g_clingo_ast_constructors.constructors[35].arguments[4].attribute != 7 || g_clingo_ast_constructors.constructors[35].arguments[4].type != 7 || strcmp(g_clingo_ast_attribute_names.names[7], "body")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[36].name, "script") || g_clingo_ast_constructors.constructors[36].size != 3) return 0;
  if (g_clingo_ast_constructors.constructors[36].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[36].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[36].arguments[1].attribute != 25 || g_clingo_ast_constructors.constructors[36].arguments[1].type != 3 || strcmp(g_clingo_ast_attribute_names.names[25], "name")) return 0;
  if (g_clingo_ast_constructors.constructors[36].arguments[2].attribute != 8 || g_clingo_ast_constructors.constructors[36].arguments[2].type != 3 || strcmp(g_clingo_ast_attribute_names.names[8], "code")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[37].name, "program") || g_clingo_ast_constructors.constructors[37].size != 3) return 0;
  if (g_clingo_ast_constructors.constructors[37].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[37].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[37].arguments[1].attribute != 25 || g_clingo_ast_constructors.constructors[37].arguments[1].type != 3 || strcmp(g_clingo_ast_attribute_names.names[25], "name")) return 0;
  if (g_clingo_ast_constructors.constructors[37].arguments[2].attribute != 31 || g_clingo_ast_constructors.constructors[37].arguments[2].type != 7 || strcmp(g_clingo_ast_attribute_names.names[31], "parameters")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[38].name, "external") || g_clingo_ast_constructors.constructors[38].size != 4) return 0;
  if (g_clingo_ast_constructors.constructors[38].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[38].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[38].arguments[1].attribute != 3 || g_clingo_ast_constructors.constructors[38].arguments[1].type != 4 || strcmp(g_clingo_ast_attribute_names.names[3], "atom")) return 0;
  if (g_clingo_ast_constructors.constructors[38].arguments[2].attribute != 7 || g_clingo_ast_constructors.constructors[38].arguments[2].type != 7 || strcmp(g_clingo_ast_attribute_names.names[7], "body")) return 0;
  if (g_clingo_ast_constructors.constructors[38].arguments[3].attribute != 14 || g_clingo_ast_constructors.constructors[38].arguments[3].type != 4 || strcmp(g_clingo_ast_attribute_names.names[14], "external_type")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[39].name, "edge") || g_clingo_ast_constructors.constructors[39].size != 4) return 0;
  if (g_clingo_ast_constructors.constructors[39].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[39].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[39].arguments[1].attribute != 26 || g_clingo_ast_constructors.constructors[39].arguments[1].type != 4 || strcmp(g_clingo_ast_attribute_names.names[26], "node_u")) return 0;
  if (g_clingo_ast_constructors.constructors[39].arguments[2].attribute != 27 || g_clingo_ast_constructors.constructors[39].arguments[2].type != 4 || strcmp(g_clingo_ast_attribute_names.names[27], "node_v")) return 0;
  if (g_clingo_ast_constructors.constructors[39].arguments[3].attribute != 7 || g_clingo_ast_constructors.constructors[39].arguments[3].type != 7 || strcmp(g_clingo_ast_attribute_names.names[7], "body")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[40].name, "heuristic") || g_clingo_ast_constructors.constructors[40].size != 6) return 0;
  if (g_clingo_ast_constructors.constructors[40].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[40].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[40].arguments[1].attribute != 3 || g_clingo_ast_constructors.constructors[40].arguments[1].type != 4 || strcmp(g_clingo_ast_attribute_names.names[3], "atom")) return 0;
  if (g_clingo_ast_constructors.constructors[40].arguments[2].attribute != 7 || g_clingo_ast_constructors.constructors[40].arguments[2].type != 7 || strcmp(g_clingo_ast_attribute_names.names[7], "body")) return 0;
  if (g_clingo_ast_constructors.constructors[40].arguments[3].attribute != 6 || g_clingo_ast_constructors.constructors[40].arguments[3].type != 4 || strcmp(g_clingo_ast_attribute_names.names[6], "bias")) return 0;
  if (g_clingo_ast_constructors.constructors[40].arguments[4].attribute != 33 || g_clingo_ast_constructors.constructors[40].arguments[4].type != 4 || strcmp(g_clingo_ast_attribute_names.names[33], "priority")) return 0;
  if (g_clingo_ast_constructors.constructors[40].arguments[5].attribute != 24 || g_clingo_ast_constructors.constructors[40].arguments[5].type != 4 || strcmp(g_clingo_ast_attribute_names.names[24], "modifier")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[41].name, "project_atom") || g_clingo_ast_constructors.constructors[41].size != 3) return 0;
  if (g_clingo_ast_constructors.constructors[41].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[41].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[41].arguments[1].attribute != 3 || g_clingo_ast_constructors.constructors[41].arguments[1].type != 4 || strcmp(g_clingo_ast_attribute_names.names[3], "atom")) return 0;
  if (g_clingo_ast_constructors.constructors[41].arguments[2].attribute != 7 || g_clingo_ast_constructors.constructors[41].arguments[2].type != 7 || strcmp(g_clingo_ast_attribute_names.names[7], "body")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[42].name, "project_signature") || g_clingo_ast_constructors.constructors[42].size != 4) return 0;
  if (g_clingo_ast_constructors.constructors[42].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[42].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[42].arguments[1].attribute != 25 || g_clingo_ast_constructors.constructors[42].arguments[1].type != 3 || strcmp(g_clingo_ast_attribute_names.names[25], "name")) return 0;
  if (g_clingo_ast_constructors.constructors[42].arguments[2].attribute != 2 || g_clingo_ast_constructors.constructors[42].arguments[2].type != 0 || strcmp(g_clingo_ast_attribute_names.names[2], "arity")) return 0;
  if (g_clingo_ast_constructors.constructors[42].arguments[3].attribute != 32 || g_clingo_ast_constructors.constructors[42].arguments[3].type != 0 || strcmp(g_clingo_ast_attribute_names.names[32], "positive")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[43].name, "defined") || g_clingo_ast_constructors.constructors[43].size != 4) return 0;
  if (g_clingo_ast_constructors.constructors[43].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[43].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[43].arguments[1].attribute != 25 || g_clingo_ast_constructors.constructors[43].arguments[1].type != 3 || strcmp(g_clingo_ast_attribute_names.names[25], "name")) return 0;
  if (g_clingo_ast_constructors.constructors[43].arguments[2].attribute != 2 || g_clingo_ast_constructors.constructors[43].arguments[2].type != 0 || strcmp(g_clingo_ast_attribute_names.names[2], "arity")) return 0;
  if (g_clingo_ast_constructors.constructors[43].arguments[3].attribute != 32 || g_clingo_ast_constructors.constructors[43].arguments[3].type != 0 || strcmp(g_clingo_ast_attribute_names.names[32], "positive")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[44].name, "theory_definition") || g_clingo_ast_constructors.constructors[44].size != 4) return 0;
  if (g_clingo_ast_constructors.constructors[44].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[44].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[44].arguments[1].attribute != 25 || g_clingo_ast_constructors.constructors[44].arguments[1].type != 3 || strcmp(g_clingo_ast_attribute_names.names[25], "name")) return 0;
  if (g_clingo_ast_constructors.constructors[44].arguments[2].attribute != 40 || g_clingo_ast_constructors.constructors[44].arguments[2].type != 7 || strcmp(g_clingo_ast_attribute_names.names[40], "terms")) return 0;
  if (g_clingo_ast_constructors.constructors[44].arguments[3].attribute != 4 || g_clingo_ast_constructors.constructors[44].arguments[3].type != 7 || strcmp(g_clingo_ast_attribute_names.names[4], "atoms")) return 0;
  if (strcmp(g_clingo_ast_constructors.constructors[45].name, "comment") || g_clingo_ast_constructors.constructors[45].size != 3) return 0;
  if (g_clingo_ast_constructors.constructors[45].arguments[0].attribute != 23 || g_clingo_ast_constructors.constructors[45].arguments[0].type != 2 || strcmp(g_clingo_ast_attribute_names.names[23], "location")) return 0;
  if (g_clingo_ast_constructors.constructors[45].arguments[1].attribute != 41 || g_clingo_ast_constructors.constructors[45].arguments[1].type != 3 || strcmp(g_clingo_ast_attribute_names.names[41], "value")) return 0;
  if (g_clingo_ast_constructors.constructors[45].arguments[2].attribute != 44 || g_clingo_ast_constructors.constructors[45].arguments[2].type != 0 || strcmp(g_clingo_ast_attribute_names.names[44], "comment_type")) return 0;
  return 1;
}
static void call_ast(void **values, void *result) {
  clingo_ast_type_t type; clingo_ast_t **ast;
  memcpy(&type, values[0], sizeof(type)); memcpy(&ast, values[1], sizeof(ast));
  bool ret = false;
  switch (type) {
  case 0: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    char const* a1; memcpy(&a1, values[3], sizeof(a1));
    ret = clingo_ast_build(type, ast, a0, a1); break;
  }
  case 1: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    char const* a1; memcpy(&a1, values[3], sizeof(a1));
    ret = clingo_ast_build(type, ast, a0, a1); break;
  }
  case 2: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_symbol_t a1; memcpy(&a1, values[3], sizeof(a1));
    ret = clingo_ast_build(type, ast, a0, a1); break;
  }
  case 3: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    int a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t* a2; memcpy(&a2, values[4], sizeof(a2));
    ret = clingo_ast_build(type, ast, a0, a1, a2); break;
  }
  case 4: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    int a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t* a2; memcpy(&a2, values[4], sizeof(a2));
    clingo_ast_t* a3; memcpy(&a3, values[5], sizeof(a3));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3); break;
  }
  case 5: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t* a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t* a2; memcpy(&a2, values[4], sizeof(a2));
    ret = clingo_ast_build(type, ast, a0, a1, a2); break;
  }
  case 6: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    char const* a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t** a2; memcpy(&a2, values[4], sizeof(a2));
    size_t a3; memcpy(&a3, values[5], sizeof(a3));
    int a4; memcpy(&a4, values[6], sizeof(a4));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3, a4); break;
  }
  case 7: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t** a1; memcpy(&a1, values[3], sizeof(a1));
    size_t a2; memcpy(&a2, values[4], sizeof(a2));
    ret = clingo_ast_build(type, ast, a0, a1, a2); break;
  }
  case 8: {
    int a0; memcpy(&a0, values[2], sizeof(a0));
    ret = clingo_ast_build(type, ast, a0); break;
  }
  case 9: {
    clingo_ast_t* a0; memcpy(&a0, values[2], sizeof(a0));
    ret = clingo_ast_build(type, ast, a0); break;
  }
  case 10: {
    clingo_ast_t* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t** a1; memcpy(&a1, values[3], sizeof(a1));
    size_t a2; memcpy(&a2, values[4], sizeof(a2));
    ret = clingo_ast_build(type, ast, a0, a1, a2); break;
  }
  case 11: {
    int a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t* a1; memcpy(&a1, values[3], sizeof(a1));
    ret = clingo_ast_build(type, ast, a0, a1); break;
  }
  case 12: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t* a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t** a2; memcpy(&a2, values[4], sizeof(a2));
    size_t a3; memcpy(&a3, values[5], sizeof(a3));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3); break;
  }
  case 13: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t* a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t** a2; memcpy(&a2, values[4], sizeof(a2));
    size_t a3; memcpy(&a3, values[5], sizeof(a3));
    clingo_ast_t* a4; memcpy(&a4, values[6], sizeof(a4));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3, a4); break;
  }
  case 14: {
    clingo_ast_t** a0; memcpy(&a0, values[2], sizeof(a0));
    size_t a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t** a2; memcpy(&a2, values[4], sizeof(a2));
    size_t a3; memcpy(&a3, values[5], sizeof(a3));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3); break;
  }
  case 15: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t* a1; memcpy(&a1, values[3], sizeof(a1));
    int a2; memcpy(&a2, values[4], sizeof(a2));
    clingo_ast_t** a3; memcpy(&a3, values[5], sizeof(a3));
    size_t a4; memcpy(&a4, values[6], sizeof(a4));
    clingo_ast_t* a5; memcpy(&a5, values[7], sizeof(a5));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3, a4, a5); break;
  }
  case 16: {
    clingo_ast_t** a0; memcpy(&a0, values[2], sizeof(a0));
    size_t a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t* a2; memcpy(&a2, values[4], sizeof(a2));
    ret = clingo_ast_build(type, ast, a0, a1, a2); break;
  }
  case 17: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t* a1; memcpy(&a1, values[3], sizeof(a1));
    int a2; memcpy(&a2, values[4], sizeof(a2));
    clingo_ast_t** a3; memcpy(&a3, values[5], sizeof(a3));
    size_t a4; memcpy(&a4, values[6], sizeof(a4));
    clingo_ast_t* a5; memcpy(&a5, values[7], sizeof(a5));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3, a4, a5); break;
  }
  case 18: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t** a1; memcpy(&a1, values[3], sizeof(a1));
    size_t a2; memcpy(&a2, values[4], sizeof(a2));
    ret = clingo_ast_build(type, ast, a0, a1, a2); break;
  }
  case 19: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    int a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t** a2; memcpy(&a2, values[4], sizeof(a2));
    size_t a3; memcpy(&a3, values[5], sizeof(a3));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3); break;
  }
  case 20: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    char const* a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t** a2; memcpy(&a2, values[4], sizeof(a2));
    size_t a3; memcpy(&a3, values[5], sizeof(a3));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3); break;
  }
  case 21: {
    char const** a0; memcpy(&a0, values[2], sizeof(a0));
    size_t a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t* a2; memcpy(&a2, values[4], sizeof(a2));
    ret = clingo_ast_build(type, ast, a0, a1, a2); break;
  }
  case 22: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t** a1; memcpy(&a1, values[3], sizeof(a1));
    size_t a2; memcpy(&a2, values[4], sizeof(a2));
    ret = clingo_ast_build(type, ast, a0, a1, a2); break;
  }
  case 23: {
    char const* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t* a1; memcpy(&a1, values[3], sizeof(a1));
    ret = clingo_ast_build(type, ast, a0, a1); break;
  }
  case 24: {
    clingo_ast_t** a0; memcpy(&a0, values[2], sizeof(a0));
    size_t a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t** a2; memcpy(&a2, values[4], sizeof(a2));
    size_t a3; memcpy(&a3, values[5], sizeof(a3));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3); break;
  }
  case 25: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t* a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t** a2; memcpy(&a2, values[4], sizeof(a2));
    size_t a3; memcpy(&a3, values[5], sizeof(a3));
    clingo_ast_t* a4; memcpy(&a4, values[6], sizeof(a4));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3, a4); break;
  }
  case 26: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    int a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t* a2; memcpy(&a2, values[4], sizeof(a2));
    ret = clingo_ast_build(type, ast, a0, a1, a2); break;
  }
  case 27: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    char const* a1; memcpy(&a1, values[3], sizeof(a1));
    int a2; memcpy(&a2, values[4], sizeof(a2));
    int a3; memcpy(&a3, values[5], sizeof(a3));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3); break;
  }
  case 28: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    char const* a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t** a2; memcpy(&a2, values[4], sizeof(a2));
    size_t a3; memcpy(&a3, values[5], sizeof(a3));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3); break;
  }
  case 29: {
    char const** a0; memcpy(&a0, values[2], sizeof(a0));
    size_t a1; memcpy(&a1, values[3], sizeof(a1));
    char const* a2; memcpy(&a2, values[4], sizeof(a2));
    ret = clingo_ast_build(type, ast, a0, a1, a2); break;
  }
  case 30: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    int a1; memcpy(&a1, values[3], sizeof(a1));
    char const* a2; memcpy(&a2, values[4], sizeof(a2));
    int a3; memcpy(&a3, values[5], sizeof(a3));
    char const* a4; memcpy(&a4, values[6], sizeof(a4));
    clingo_ast_t* a5; memcpy(&a5, values[7], sizeof(a5));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3, a4, a5); break;
  }
  case 31: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t* a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t** a2; memcpy(&a2, values[4], sizeof(a2));
    size_t a3; memcpy(&a3, values[5], sizeof(a3));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3); break;
  }
  case 32: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    char const* a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t* a2; memcpy(&a2, values[4], sizeof(a2));
    int a3; memcpy(&a3, values[5], sizeof(a3));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3); break;
  }
  case 33: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    char const* a1; memcpy(&a1, values[3], sizeof(a1));
    int a2; memcpy(&a2, values[4], sizeof(a2));
    int a3; memcpy(&a3, values[5], sizeof(a3));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3); break;
  }
  case 34: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t* a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t** a2; memcpy(&a2, values[4], sizeof(a2));
    size_t a3; memcpy(&a3, values[5], sizeof(a3));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3); break;
  }
  case 35: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t* a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t* a2; memcpy(&a2, values[4], sizeof(a2));
    clingo_ast_t** a3; memcpy(&a3, values[5], sizeof(a3));
    size_t a4; memcpy(&a4, values[6], sizeof(a4));
    clingo_ast_t** a5; memcpy(&a5, values[7], sizeof(a5));
    size_t a6; memcpy(&a6, values[8], sizeof(a6));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3, a4, a5, a6); break;
  }
  case 36: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    char const* a1; memcpy(&a1, values[3], sizeof(a1));
    char const* a2; memcpy(&a2, values[4], sizeof(a2));
    ret = clingo_ast_build(type, ast, a0, a1, a2); break;
  }
  case 37: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    char const* a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t** a2; memcpy(&a2, values[4], sizeof(a2));
    size_t a3; memcpy(&a3, values[5], sizeof(a3));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3); break;
  }
  case 38: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t* a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t** a2; memcpy(&a2, values[4], sizeof(a2));
    size_t a3; memcpy(&a3, values[5], sizeof(a3));
    clingo_ast_t* a4; memcpy(&a4, values[6], sizeof(a4));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3, a4); break;
  }
  case 39: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t* a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t* a2; memcpy(&a2, values[4], sizeof(a2));
    clingo_ast_t** a3; memcpy(&a3, values[5], sizeof(a3));
    size_t a4; memcpy(&a4, values[6], sizeof(a4));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3, a4); break;
  }
  case 40: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t* a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t** a2; memcpy(&a2, values[4], sizeof(a2));
    size_t a3; memcpy(&a3, values[5], sizeof(a3));
    clingo_ast_t* a4; memcpy(&a4, values[6], sizeof(a4));
    clingo_ast_t* a5; memcpy(&a5, values[7], sizeof(a5));
    clingo_ast_t* a6; memcpy(&a6, values[8], sizeof(a6));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3, a4, a5, a6); break;
  }
  case 41: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    clingo_ast_t* a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t** a2; memcpy(&a2, values[4], sizeof(a2));
    size_t a3; memcpy(&a3, values[5], sizeof(a3));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3); break;
  }
  case 42: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    char const* a1; memcpy(&a1, values[3], sizeof(a1));
    int a2; memcpy(&a2, values[4], sizeof(a2));
    int a3; memcpy(&a3, values[5], sizeof(a3));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3); break;
  }
  case 43: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    char const* a1; memcpy(&a1, values[3], sizeof(a1));
    int a2; memcpy(&a2, values[4], sizeof(a2));
    int a3; memcpy(&a3, values[5], sizeof(a3));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3); break;
  }
  case 44: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    char const* a1; memcpy(&a1, values[3], sizeof(a1));
    clingo_ast_t** a2; memcpy(&a2, values[4], sizeof(a2));
    size_t a3; memcpy(&a3, values[5], sizeof(a3));
    clingo_ast_t** a4; memcpy(&a4, values[6], sizeof(a4));
    size_t a5; memcpy(&a5, values[7], sizeof(a5));
    ret = clingo_ast_build(type, ast, a0, a1, a2, a3, a4, a5); break;
  }
  case 45: {
    clingo_location_t* a0; memcpy(&a0, values[2], sizeof(a0));
    char const* a1; memcpy(&a1, values[3], sizeof(a1));
    int a2; memcpy(&a2, values[4], sizeof(a2));
    ret = clingo_ast_build(type, ast, a0, a1, a2); break;
  }
  }
  memcpy(result, &ret, sizeof(ret));
}
