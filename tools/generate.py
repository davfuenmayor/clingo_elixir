#!/usr/bin/env python3
"""Generate the ABI inventory from the pinned public header; requires clang."""
import json, re, subprocess
from pathlib import Path
root = Path(__file__).resolve().parents[1]
nodes = json.loads(subprocess.check_output(['clang', '-Xclang', '-ast-dump=json', '-fsyntax-only', str(root/'c_src/clingo.h')]))['inner']
aliases = {n['name']: n['type']['qualType'] for n in nodes if n['kind']=='TypedefDecl'}
# Keep the checked-in inventory independent of the generator host's libc and
# LP64/LLP64 typedef spelling. The supported runtimes all have 64-bit size_t.
aliases.update({'int32_t': 'int', 'uint32_t': 'unsigned int',
                'int64_t': 'long long', 'uint64_t': 'unsigned long long',
                'size_t': 'uint64_t'})
records = {f"struct {n['name']}": n for n in nodes if n['kind']=='RecordDecl' and n.get('name','').startswith('clingo_')}
types, ids = [], {}
def qualifiers(s):
    # Bit zero describes the immediate pointee, bit one its pointee, etc.
    for _ in range(12):
        expanded = re.sub(r'\b\w+\b', lambda m: aliases.get(m[0], m[0]), s)
        if expanded == s: break
        s = expanded
    if '(*' in s: return 0
    return sum(1 << i for i, part in enumerate(reversed(s.split('*')[:-1]))
               if re.search(r'\bconst\b', part))
def split(s):
    parts, start, depth = [], 0, 0
    for i,c in enumerate(s):
        depth += (c=='(') - (c==')')
        if c==',' and depth==0: parts.append(s[start:i].strip()); start=i+1
    if s[start:].strip() not in ('', 'void'): parts.append(s[start:].strip())
    return parts

def typ(s):
    original = s
    s=re.sub(r'\b(const|volatile|restrict)\b', '', s)
    s=re.sub(r'\s+', ' ', s).strip()
    s=re.sub(r'\s*([*(),])\s*', r'\1', s)
    if s in ids: return ids[s]
    idx=len(types); ids[s]=idx; t={'name':s,'c_type':original}; types.append(t)
    if s in aliases:
        t.update(kind='alias', target=typ(aliases[s]))
    elif '(*' in s:
        m=re.match(r'(.*?)\(\*\)\((.*)\)$',s); assert m,s
        raw=re.match(r'(.*?)\(\s*\*\s*\)\s*\((.*)\)$', original)
        t.update(kind='callback', result=typ(m[1]), args=[typ(a) for a in split(m[2])],
                 result_qualifiers=qualifiers(raw[1]), qualifiers=[qualifiers(a) for a in split(raw[2])])
    elif s.endswith('*'): t.update(kind='pointer', target=typ(s[:-1]))
    elif s.startswith('struct '):
        n=records[s]
        t.update(kind='record' if n.get('completeDefinition') else 'opaque',fields=[{'name':f['name'],'type':typ(f['type']['qualType']),'c_type':f['type']['qualType'],'qualifiers':qualifiers(f['type']['qualType'])} for f in n.get('inner',[]) if f['kind']=='FieldDecl'])
    elif s.startswith('enum '): t.update(kind='alias',target=typ('int'))
    else:
        kinds={'void':'void','bool':'bool','_Bool':'bool','char':'signed','signed char':'signed','unsigned char':'unsigned','short':'signed','unsigned short':'unsigned','int':'signed','unsigned int':'unsigned','long':'signed','unsigned long':'unsigned','long long':'signed','unsigned long long':'unsigned','double':'double'}
        assert s in kinds,s
        t.update(kind=kinds[s])
    return idx
functions=[]
for n in nodes:
    if n['kind']=='FunctionDecl' and n.get('name','').startswith('clingo_'):
        args=[p for p in n.get('inner',[]) if p['kind']=='ParmVarDecl']
        result=n['type']['qualType'].split('(')[0].strip()
        functions.append({'name':n['name'],'result':typ(result),'result_c_type':result,'result_qualifiers':qualifiers(result),'args':[{'name':p.get('name',f'arg{i}'),'type':typ(p['type']['qualType']),'c_type':p['type']['qualType'],'qualifiers':qualifiers(p['type']['qualType']),'const_string':bool(re.match(r'^const char \*$',p['type']['qualType']))} for i,p in enumerate(args)],'variadic':n.get('variadic',False),'line':n['loc']['line']})
policy=json.loads((root/'tools/api_policy.json').read_text())
assert set(policy)=={f['name'] for f in functions}, 'Review policy for every public declaration'
for f in functions:
    f['policy']=policy[f['name']]
    assert [a['name'] for a in f['args']]==[a['name'] for a in f['policy']['arguments']],f['name']
    for a in f['policy']['arguments']:
        assert a['size'] is None or a['size'] in {p['name'] for p in f['args']}, (f['name'],a)
# Explicit capability inventory: header growth never expands the product silently.
scope = json.loads((root/'tools/api_scope.json').read_text())
selected = {name for group in scope['capabilities'].values() for name in group['operations']}
assert len(selected) == sum(len(g['operations']) for g in scope['capabilities'].values()), 'Duplicate scope operation'
assert selected | set(scope['excluded']) == {f['name'] for f in functions}, 'Review changed header scope'
assert not selected & set(scope['excluded'])
functions = [f for f in functions if f['name'] in selected]
for name in aliases:
    if name.startswith('clingo_'): typ(name)
for name in ['size_t','uint64_t','int64_t','uint32_t','int32_t','char*','void*','clingo_symbol_t*','clingo_ast_t*','clingo_location_t*','clingo_ast_t**','size_t*'] :typ(name)
globals_=[{'name':n['name'],'type':typ(n['type']['qualType'])} for n in nodes if n['kind']=='VarDecl' and n.get('name','').startswith('g_clingo_')]
enums=[]
for n in nodes:
    if n['kind']=='EnumDecl' and n.get('name','').startswith('clingo_'):
        typ('enum '+n['name'])
        enums.extend(f['name'] for f in n.get('inner',[]) if f['kind']=='EnumConstantDecl')
# C layout is computed by the compiler, never guessed by Python.
lines=['/* Generated by tools/generate.py; do not edit. */']
for i,t in enumerate(types):
    if t['kind']=='record':
        fs=t['fields']
        lines.append(f'static Field fields_{i}[] = {{'+','.join('{"%s",%d,offsetof(%s,%s),%d}'%(f['name'],f['type'],t['name'],f['name'],f['qualifiers']) for f in fs)+'};')
    if t['kind']=='callback':
        lines.append(f'static int args_{i}[] = {{'+','.join(map(str,t['args']))+'};')
        lines.append(f'static unsigned qualifiers_{i}[] = {{'+','.join(map(str,t['qualifiers']))+'};')
lines.append('static Type types[] = {')
for i,t in enumerate(types):
    k=t['kind']; base=t
    while base['kind']=='alias': base=types[base['target']]
    size='0' if base['kind'] in ('void','opaque') else 'sizeof(void*)' if k=='callback' else f'sizeof({t["name"]})'
    object_kind={'struct clingo_control':1,'struct clingo_solve_handle':2,'struct clingo_ast':3,'struct clingo_model':4,'struct clingo_symbolic_atoms':5,'struct clingo_theory_atoms':6}.get(base['name'],0)
    lines.append('{"%s",K_%s,%s,%d,%d,%s,%d,%s,%d,%s,%d},'%(t['name'],k.upper(),size,t.get('target',-1),t.get('result',-1),f'args_{i}' if k=='callback' else 'NULL',len(t.get('fields',t.get('args',[]))),f'fields_{i}' if k=='record' else 'NULL',t.get('result_qualifiers',0),f'qualifiers_{i}' if k=='callback' else 'NULL',object_kind))
lines.append('};')
for i,f in enumerate(functions):
    names=[a['name'] for a in f['args']]
    arguments=[]
    for a,p in zip(f['args'], f['policy']['arguments']):
        size=names.index(p['size']) if p['size'] else -1
        arguments.append('{%d,%d,%d,%d,%d,%d,%d}' % (
            a['type'], size, a['const_string'], a['qualifiers'],
            p['nullable'], p['direction']=='out', p['owned']))
    lines.append(f'static Argument fnargs_{i}[] = {{'+','.join(arguments)+'};')
    if not f['variadic']:
        lines.append(f'static void direct_{i}(void **values, void *result) {{')
        lines.append('  (void)values; (void)result;')
        for j,a in enumerate(f['args']):
            ctype=a['c_type']
            declaration=re.sub(r'\(\s*\*\s*\)',f'(*arg_{j}_t)',ctype) if '(*' in ctype.replace(' ','') else f'{ctype} arg_{j}_t'
            lines.append(f'  typedef {declaration}; arg_{j}_t a{j}; memcpy(&a{j}, values[{j}], sizeof(a{j}));')
        call=f'{f["name"]}('+','.join(f'a{j}' for j in range(len(f['args'])))+')'
        if f['result_c_type']=='void': lines.append(f'  {call};')
        else: lines.append(f'  {f["result_c_type"]} value = {call}; memcpy(result, &value, sizeof(value));')
        lines.append('}')
lines.append('static Function functions[] = {')
for i,f in enumerate(functions):
    flags=' | '.join('F_'+v.upper() for v in f['policy']['flags']) or '0'
    lines.append('{"%s",(void(*)(void))%s,%d,%d,fnargs_%d,%d,%d,%s,%s,0},'%(
        f['name'],f['name'],f['result'],len(f['args']),i,f['variadic'],
        f['result_qualifiers'],'NULL' if f['variadic'] else f'direct_{i}',flags))
lines.extend(['};','static Global globals[] = {'])
for g in globals_:lines.append('{"%s",%d,NULL},'%(g['name'],g['type']))
# Imported DLL data addresses are resolved at load time on Windows.
lines.extend(['};','static void initialize_globals(void) {'])
for i,g in enumerate(globals_):lines.append('  globals[%d].address = &%s;'%(i,g['name']))
lines.extend(['}','static Constant constants[] = {'])
for e in enums:lines.append('{"%s",%s},'%(e,e))
lines.extend(['{"CLINGO_VERSION_MAJOR",CLINGO_VERSION_MAJOR},{"CLINGO_VERSION_MINOR",CLINGO_VERSION_MINOR},{"CLINGO_VERSION_REVISION",CLINGO_VERSION_REVISION}','};'])
(root/'c_src/api.inc').write_text('\n'.join(lines)+'\n')
manifest={'version':'5.8.2','functions':functions,'types':types,'globals':globals_,'constants':enums,'aliases':aliases}
(root/'tools/api.json').write_text(json.dumps(manifest,indent=2)+'\n')
def literal(value):
    if value is None: return 'nil'
    if isinstance(value,bool): return str(value).lower()
    if isinstance(value,int): return str(value)
    if isinstance(value,str): return json.dumps(value)
    if isinstance(value,list): return '['+', '.join(literal(x) for x in value)+']'
    return '%{'+', '.join(literal(k)+' => '+literal(v) for k,v in value.items())+'}'
# Generate only the value adapter; raw C probes live in test support.
public=['# Generated by tools/generate.py.', 'defmodule Clingo.Internal.API do', '  @moduledoc false']
metadata={}
size_queries={
 'clingo_symbol_to_string':'clingo_symbol_to_string_size',
 'clingo_symbolic_atoms_signatures':'clingo_symbolic_atoms_signatures_size',
 'clingo_theory_atoms_term_to_string':'clingo_theory_atoms_term_to_string_size',
 'clingo_theory_atoms_element_to_string':'clingo_theory_atoms_element_to_string_size',
 'clingo_theory_atoms_atom_to_string':'clingo_theory_atoms_atom_to_string_size',
 'clingo_configuration_value_get':'clingo_configuration_value_get_size',
 'clingo_model_symbols':'clingo_model_symbols_size',
 'clingo_model_cost':'clingo_model_cost_size',
 'clingo_model_priority':'clingo_model_cost_size',
 'clingo_ast_to_string':'clingo_ast_to_string_size'}
native_only = set(scope['native_only'])
assert native_only <= selected, 'Native-only entries must refer to retained operations'
value_adapters = selected - native_only
binding_operations = value_adapters | {size_queries[n] for n in value_adapters if n in size_queries}
for f in functions:
    if f['name'] not in binding_operations: continue
    name=f['name'][7:]
    metadata[f['name']]={
      'arguments':[dict(name=p['name'], direction=p['direction'], size=p['size'], type=types[a['type']]['name']) for a,p in zip(f['args'],f['policy']['arguments'])],
      'size_query':size_queries.get(f['name'])}
    if f['name'] in ['clingo_symbol_arguments', 'clingo_theory_atoms_term_arguments', 'clingo_theory_atoms_element_tuple', 'clingo_theory_atoms_element_condition', 'clingo_theory_atoms_atom_elements', 'clingo_solve_handle_core']:
        outs=[a for a in metadata[f['name']]['arguments'] if a['direction']=='out']
        outs[0]['size']=outs[1]['name']
    sizes={p['size'] for p in f['policy']['arguments'] if p['size']}
    inputs=[a['name'] for a,p in zip(f['args'],f['policy']['arguments']) if p['direction']=='in' and a['name'] not in sizes]
    if f['name'] not in value_adapters: continue
    assert not f['variadic'], 'Variadic construction belongs to the AST capability'
    defaults={
     'clingo_control_new':{'arguments':'[]','logger':'nil','logger_data':'nil','message_limit':'20'},
     'clingo_control_ground':{'ground_callback':'nil','ground_callback_data':'nil'},
     'clingo_control_solve':{'mode':'2','assumptions':'[]','notify':'nil','data':'nil'}
    }.get(f['name'],{})
    parameters=[n+' \\\\ '+defaults[n] if n in defaults else n for n in inputs]
    public.append(f'  def {name}({", ".join(["session"]+parameters)}), do: Clingo.Binding.call(session, :{f["name"]}, [{", ".join(inputs)}])')
public.append('end')
(root/'lib/clingo/internal/api.ex').write_text('\n'.join(public)+'\n')
for m in metadata.values():
    sizes = {a['size'] for a in m['arguments'] if a['size']}
    inputs = [a for a in m['arguments'] if a['direction'] != 'out' and a['name'] not in sizes]
    m['inputs'] = [a['name'] for a in inputs]
    m['input_arrays'] = {a['name']: a['size'] for a in inputs if a['size']}
    m['outputs'] = [i for i, a in enumerate(m['arguments']) if a['direction'] == 'out' and a['name'] not in sizes]
    m['output_sizes'] = list(dict.fromkeys(a['size'] for a in m['arguments'] if a['direction'] == 'out' and a['size']))
resolved = {}
for t in types:
    base = t
    while base['kind'] == 'alias': base = types[base['target']]
    resolved[t['name']] = ids[base['name']]
# Callback argument relationships are reviewed policy, not runtime heuristics.
callback_policy = json.loads((root/'tools/callback_policy.json').read_text())
hooks = {}
for record_name, fields in callback_policy.items():
    record = types[ids[record_name]]
    assert set(fields) == {f['name'] for f in record['fields']}, 'Review changed callback fields'
    hooks[record_name] = {}
    for field in record['fields']:
        callback = types[resolved[types[field['type']]['name']]]
        policy = fields[field['name']]
        args = callback['args']
        userdata = policy['userdata']
        assert types[args[userdata]]['name'] == 'void*', (record_name, field['name'])
        plan = []
        skip = {userdata}
        if 'decision' in policy: skip.add(policy['decision'])
        for index in policy['arrays']:
            pointer = types[resolved[types[args[index]]['name']]]
            assert pointer['kind'] == 'pointer' and types[args[index+1]]['name'] == 'size_t'
            assert index not in skip and index+1 not in skip
            skip.add(index+1)
        for index, type_id in enumerate(args):
            if index not in skip:
                type_name = types[type_id]['name']
                base = types[resolved[type_name]]
                target = types[base['target']]['name'] if base['kind'] == 'pointer' else None
                views = {'clingo_propagate_init_t': 'propagate_init',
                         'clingo_propagate_control_t': 'propagate_control',
                         'clingo_assignment_t': 'assignment'}
                if index in policy['arrays']:
                    conversion = 'symbols' if target == 'clingo_symbol_t' else 'array'
                elif type_name == 'clingo_symbol_t':
                    conversion = 'symbol'
                else:
                    conversion = views.get(target, 'value')
                plan.append({'index': index, 'conversion': conversion})
        hooks[record_name][field['name']] = {
            'plan': plan, 'arity': len(args), 'decision': policy.get('decision'),
            'void': types[resolved[types[callback['result']]['name']]]['kind'] == 'void'}
# Elixir needs conversion facts, not C declarations, qualifiers or callback ABI
# layouts. Those remain authoritative in the native inventory and manifest.
needed = {a['type'] for m in metadata.values() for a in m['arguments']} | set(hooks)
binding_types, binding_resolved = {}, {}
while needed:
    name = needed.pop()
    if name in binding_resolved: continue
    t = types[resolved[name]]
    binding_resolved[name] = t['name']
    entry = {'name': t['name'], 'kind': t['kind']}
    if t['kind'] == 'pointer':
        entry['target'] = types[t['target']]['name']
        needed.add(entry['target'])
    if t['kind'] == 'record':
        entry['fields'] = [{'name': f['name'], 'type': types[f['type']]['name']} for f in t['fields']]
        needed.update(f['type'] for f in entry['fields'])
    binding_types[t['name']] = entry
meta=['# Generated by tools/generate.py.', 'defmodule Clingo.BindingMetadata do', '  @moduledoc false',
      '  @functions '+literal(metadata), '  @types '+literal(dict(sorted(binding_types.items()))),
      '  @resolved '+literal(dict(sorted(binding_resolved.items()))), '  @hooks '+literal(hooks),
      '  def function(name), do: Map.fetch!(@functions, to_string(name))',
      '  def hooks(name), do: Map.fetch!(@hooks, resolved(name)["name"])',
      '  def resolved(name), do: Map.fetch!(@types, Map.fetch!(@resolved, name))', 'end']
(root/'lib/clingo/binding_metadata.ex').write_text('\n'.join(meta)+'\n')
coverage=['# Internal C operation inventory','', 'Source: vendored `c_src/clingo.h`, clingo v5.8.2. Generated with clang.', '', 'Ordinary functions use generated typed C thunks; AST constructors and callback adapters use generated typed C calls.', 'The supported capability scope is `tools/api_scope.json`; these generated functions are private implementation details.', 'Unit test mapping and behavioral verification are recorded in `docs/VALIDATION.md`.', '', '| C function | Elixir function | Unit test files | Header line |','|---|---|---|---|']
for f in functions:
    name=f['name'][7:]
    tests=[p.name for p in sorted((root/'test').glob('*')) if p.is_file() and re.search(r'(?:A\.'+name+r'\(|:'+name+r'\b)',p.read_text())]
    links=', '.join(f'[{n}](../test/{n})' for n in tests) or 'Inventory checks; see runtime coverage'
    adapter = f'`Clingo.Internal.API.{name}` (Elixir values)' if f['name'] in value_adapters else 'Internal native operation; no Elixir value facade'
    coverage.append(f'| `{f["name"]}` | {adapter} | {links} | {f["line"]} |')
coverage+=['','## Non-function declarations','','| Declaration | Binding |','|---|---|']
for t in types:
    if t['name'].startswith(('clingo_', 'struct clingo_', 'enum clingo_')):
        coverage.append(f'| `{t["name"]}` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |')
for g in globals_:coverage.append(f'| `{g["name"]}` | `Clingo.global/2` |')
for e in enums:coverage.append(f'| `{e}` | `Clingo.constant/1` |')
coverage+=['','Version macros: `Clingo.version/0` and `Clingo.constant/1`. Visibility/export macros are compile-time linkage directives; `CLINGO_DEPRECATED` marks declarations and introduces no callable capability. Header guards, standard includes, and C++ linkage guards have no runtime operation.']
coverage+=['','## Struct callback extension points','','| Callback field | Binding |','|---|---|']
for t in types:
    if t['kind']=='record':
        for field in t['fields']:
            ft=types[field['type']]
            while ft['kind']=='alias':ft=types[ft['target']]
            if ft['kind']=='callback':coverage.append(f'| `{t["name"]}.{field["name"]}` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |')
(root/'docs/COVERAGE.md').write_text('\n'.join(coverage)+'\n')
subprocess.run(['mix','format',str(root/'lib/clingo/internal/api.ex'),str(root/'lib/clingo/binding_metadata.ex')],cwd=root,check=True)
print(f'{len(functions)} functions, {len(types)} types, {len(enums)} constants, {len(globals_)} globals')

subprocess.check_call(["python3", str(root / "tools/generate_native.py")])
