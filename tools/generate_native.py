#!/usr/bin/env python3
"""Finite typed callback and AST adapters. Run after generate.py writes api.json."""
import json, re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'tools/api.json').read_text())
types = manifest['types']
functions = {f['name']: f for f in manifest['functions']}
sites = json.loads((root / 'tools/callback_sites.json').read_text())
constructors = json.loads((root / 'tools/ast_constructors.json').read_text())

def resolve(i):
    while types[i]['kind'] == 'alias': i = types[i]['target']
    return i

def ctype(i): return types[i]['c_type']

def signature(raw):
    while raw in manifest['aliases']: raw = manifest['aliases'][raw]
    match = re.match(r'(.*?)\(\s*\*\s*\)\s*\((.*)\)$', raw)
    assert match, raw
    args, start, depth = [], 0, 0
    for i, char in enumerate(match[2]):
        depth += (char == '(') - (char == ')')
        if char == ',' and depth == 0:
            args.append(match[2][start:i].strip()); start = i + 1
    if match[2][start:].strip() not in ('', 'void'): args.append(match[2][start:].strip())
    return match[1].strip(), args

def declaration(t, name):
    return re.sub(r'\(\s*\*\s*\)', f'(*{name})', t, count=1) if re.search(r'\(\s*\*\s*\)', t) else f'{t} {name}'

lines = ['/* Generated typed adapters; do not edit. */']
for i, t in enumerate(types):
    if t['kind'] != 'callback': continue
    lines.append(f'typedef {declaration(t['c_type'], f'cb_type_{i}')};')

lines += ['static int call_typed(int type, void (*address)(void), void **values, void *result) {',
          '  (void)values; (void)result;', '  switch (resolve(type)) {']
for i, t in enumerate(types):
    if t['kind'] != 'callback': continue
    lines.append(f'  case {i}: {{')
    result_type, arg_types = signature(t['c_type'])
    for j, arg in enumerate(arg_types):
        lines.append(f'    {declaration(arg, f"a{j}")}; memcpy(&a{j}, values[{j}], sizeof(a{j}));')
    call = f'((cb_type_{i})address)(' + ', '.join(f'a{j}' for j in range(len(t['args']))) + ')'
    if types[resolve(t['result'])]['kind'] == 'void': lines.append(f'    {call};')
    else: lines.append(f'    {declaration(result_type, 'ret')} = {call}; memcpy(result, &ret, sizeof(ret));')
    lines += ['    return 1;', '  }']
lines += ['  default: return 0;', '  }', '}']

adapt = ['static int adapt_callbacks(Session *s, Function *fn, void **values) {']
observed = set()
for index, site in enumerate(sites):
    f = functions[site['function']]
    arg = next(i for i, a in enumerate(f['args']) if a['name'] == site['argument'])
    data = next(i for i, a in enumerate(f['args']) if a['name'] == site['data'])
    assert types[resolve(f['args'][data]['type'])]['name'] == 'void*'
    t = types[resolve(f['args'][arg]['type'])]
    record = types[resolve(t['target'])] if t['kind'] == 'pointer' else None
    fields = [(j, x) for j, x in enumerate(record['fields']) if types[resolve(x['type'])]['kind'] == 'callback'] if record else [(0, f['args'][arg])]
    assert set(site['callback_data_indices']) == {x['name'] for _, x in fields}
    observed.add((f['name'], arg))
    for j, field in fields:
        cb = types[resolve(field['type'])]
        di = site['callback_data_indices'][field['name']]
        assert types[resolve(cb['args'][di])]['name'] == 'void*'
        result, arg_types = signature(field['c_type'])
        sig = ', '.join(declaration(a, f'a{k}') for k, a in enumerate(arg_types)) or 'void'
        lines += [f'static {result} callback_{index}_{j}({sig}) {{',
                  f'  CallbackBundle *bundle = a{di};', f'  a{di} = bundle->data;',
                  '  void *values[] = {' + ', '.join(f'&a{k}' for k in range(len(cb['args']))) + '};']
        void = types[resolve(cb['result'])]['kind'] == 'void'
        lines.append('  unsigned char unused = 0;' if void else f'  {declaration(result, "ret")} = {{0}};')
        out = '&unused' if void else '&ret'
        lines += [f'  if (bundle->callbacks[{j}]) callback(bundle->callbacks[{j}], {out}, values);',
                  f'  else call_typed({resolve(field["type"])}, bundle->native[{j}], values, {out});']
        if not void: lines.append('  return ret;')
        lines.append('}')
    adapt += [f'  if (!strcmp(fn->name, "{f["name"]}")) {{', f'    if (*(void **)values[{arg}]) {{']
    if record:
        adapt += [f'      {record["name"]} *original = *(void **)values[{arg}];', '      int needed = 0;']
        for _, field in fields:
            adapt.append(f'      needed |= find_closure(s, (void *)original->{field["name"]}) != NULL;')
        adapt += ['      if (needed) {', f'        CallbackBundle *b = bundle_new(s, *(void **)values[{data}]);',
                  f'        {record["name"]} *copy = retain_bytes(s, sizeof(*copy));',
                  '        if (!b || !copy) return 0;', '        *copy = *original;']
        for j, field in fields:
            name = field['name']
            adapt += [f'        b->callbacks[{j}] = find_closure(s, (void *)original->{name});',
                      f'        b->native[{j}] = (void (*)(void))original->{name};',
                      f'        if (original->{name}) copy->{name} = callback_{index}_{j};']
        adapt += [f'        *(void **)values[{arg}] = copy;', f'        *(void **)values[{data}] = b;', '      }']
    else:
        adapt += [f'      Closure *c = find_closure(s, *(void **)values[{arg}]);', '      if (c) {',
                  f'        CallbackBundle *b = bundle_new(s, *(void **)values[{data}]);',
                  '        if (!b) return 0;', '        b->callbacks[0] = c;',
                  f'        *(void **)values[{arg}] = (void *)callback_{index}_0;',
                  f'        *(void **)values[{data}] = b;', '      }']
    adapt += ['    }', '  }']

expected = set()
for f in functions.values():
    for i, a in enumerate(f['args']):
        t = types[resolve(a['type'])]
        if t['kind'] == 'callback': expected.add((f['name'], i))
        if t['kind'] == 'pointer':
            target = types[resolve(t['target'])]
            if target['kind'] == 'record' and any(types[resolve(x['type'])]['kind'] == 'callback' for x in target['fields']): expected.add((f['name'], i))
assert expected == observed, 'Review callback-site policy after public API drift'
adapt += ['  return 1;', '}']
lines += adapt

lines += ['static int ast_metadata_matches(void) {',
          f'  if (g_clingo_ast_constructors.size != {len(constructors)}) return 0;']
for i, c in enumerate(constructors):
    lines += [f'  if (strcmp(g_clingo_ast_constructors.constructors[{i}].name, "{c["name"]}") || g_clingo_ast_constructors.constructors[{i}].size != {len(c["arguments"])}) return 0;']
    for j, a in enumerate(c['arguments']):
        lines.append(f'  if (g_clingo_ast_constructors.constructors[{i}].arguments[{j}].attribute != {a["attribute"]} || g_clingo_ast_constructors.constructors[{i}].arguments[{j}].type != {a["type"]} || strcmp(g_clingo_ast_attribute_names.names[{a["attribute"]}], "{a["name"]}")) return 0;')
lines += ['  return 1;', '}', 'static void call_ast(void **values, void *result) {',
          '  clingo_ast_type_t type; clingo_ast_t **ast;', '  memcpy(&type, values[0], sizeof(type)); memcpy(&ast, values[1], sizeof(ast));',
          '  bool ret = false;', '  switch (type) {']
attrtypes = ['int', 'clingo_symbol_t', 'clingo_location_t*', 'char const*', 'clingo_ast_t*', 'clingo_ast_t*', 'char const**', 'clingo_ast_t**']
for i, c in enumerate(constructors):
    args = []
    for a in c['arguments']:
        args.append(attrtypes[a['type']])
        if a['type'] in (6, 7): args.append('size_t')
    lines.append(f'  case {i}: {{')
    for j, t in enumerate(args): lines.append(f'    {declaration(t, f"a{j}")}; memcpy(&a{j}, values[{j+2}], sizeof(a{j}));')
    suffix = ''.join(f', a{j}' for j in range(len(args)))
    lines += [f'    ret = clingo_ast_build(type, ast{suffix}); break;', '  }']
lines += ['  }', '  memcpy(result, &ret, sizeof(ret));', '}']
(root / 'c_src/adapters.inc').write_text('\n'.join(lines) + '\n')
