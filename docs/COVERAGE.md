# Internal C operation inventory

Source: vendored `c_src/clingo.h`, clingo v5.8.2. Generated with clang.

Ordinary functions use generated typed C thunks; AST constructors and callback adapters use generated typed C calls.
The supported capability scope is `tools/api_scope.json`; these generated functions are private implementation details.
Unit test mapping and behavioral verification are recorded in `docs/VALIDATION.md`.

| C function | Elixir function | Unit test files | Header line |
|---|---|---|---|
| `clingo_error_string` | Internal native operation; no Elixir value facade | [symbol_test.exs](../test/symbol_test.exs) | 150 |
| `clingo_warning_string` | Internal native operation; no Elixir value facade | [symbol_test.exs](../test/symbol_test.exs) | 177 |
| `clingo_signature_create` | `Clingo.Internal.API.signature_create` (Elixir values) | [symbol_test.exs](../test/symbol_test.exs) | 267 |
| `clingo_signature_name` | `Clingo.Internal.API.signature_name` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs), [symbol_test.exs](../test/symbol_test.exs) | 276 |
| `clingo_signature_arity` | `Clingo.Internal.API.signature_arity` (Elixir values) | [symbol_test.exs](../test/symbol_test.exs) | 281 |
| `clingo_signature_is_positive` | `Clingo.Internal.API.signature_is_positive` (Elixir values) | [symbol_test.exs](../test/symbol_test.exs) | 286 |
| `clingo_signature_is_negative` | `Clingo.Internal.API.signature_is_negative` (Elixir values) | [symbol_test.exs](../test/symbol_test.exs) | 291 |
| `clingo_signature_is_equal_to` | `Clingo.Internal.API.signature_is_equal_to` (Elixir values) | [symbol_test.exs](../test/symbol_test.exs) | 297 |
| `clingo_signature_is_less_than` | `Clingo.Internal.API.signature_is_less_than` (Elixir values) | [symbol_test.exs](../test/symbol_test.exs) | 306 |
| `clingo_signature_hash` | `Clingo.Internal.API.signature_hash` (Elixir values) | [symbol_test.exs](../test/symbol_test.exs) | 311 |
| `clingo_symbol_create_number` | `Clingo.Internal.API.symbol_create_number` (Elixir values) | [inventory_test.exs](../test/inventory_test.exs), [public_api_test.exs](../test/public_api_test.exs), [safety_test.exs](../test/safety_test.exs), [symbol_test.exs](../test/symbol_test.exs) | 339 |
| `clingo_symbol_create_supremum` | `Clingo.Internal.API.symbol_create_supremum` (Elixir values) | [symbol_test.exs](../test/symbol_test.exs) | 343 |
| `clingo_symbol_create_infimum` | `Clingo.Internal.API.symbol_create_infimum` (Elixir values) | [symbol_test.exs](../test/symbol_test.exs) | 347 |
| `clingo_symbol_create_string` | Internal native operation; no Elixir value facade | [symbol_test.exs](../test/symbol_test.exs) | 354 |
| `clingo_symbol_create_id` | Internal native operation; no Elixir value facade | [symbol_test.exs](../test/symbol_test.exs) | 365 |
| `clingo_symbol_create_function` | `Clingo.Internal.API.symbol_create_function` (Elixir values) | [inventory_test.exs](../test/inventory_test.exs), [public_api_test.exs](../test/public_api_test.exs), [symbol_test.exs](../test/symbol_test.exs) | 377 |
| `clingo_symbol_number` | Internal native operation; no Elixir value facade | [callback_test.exs](../test/callback_test.exs), [symbol_test.exs](../test/symbol_test.exs) | 392 |
| `clingo_symbol_name` | Internal native operation; no Elixir value facade | [symbol_test.exs](../test/symbol_test.exs) | 402 |
| `clingo_symbol_string` | Internal native operation; no Elixir value facade | [symbol_test.exs](../test/symbol_test.exs) | 412 |
| `clingo_symbol_is_positive` | Internal native operation; no Elixir value facade | [symbol_test.exs](../test/symbol_test.exs) | 419 |
| `clingo_symbol_is_negative` | Internal native operation; no Elixir value facade | [symbol_test.exs](../test/symbol_test.exs) | 426 |
| `clingo_symbol_arguments` | `Clingo.Internal.API.symbol_arguments` (Elixir values) | [public_api_test.exs](../test/public_api_test.exs), [safety_test.exs](../test/safety_test.exs), [symbol_test.exs](../test/symbol_test.exs) | 434 |
| `clingo_symbol_type` | Internal native operation; no Elixir value facade | [symbol_test.exs](../test/symbol_test.exs) | 440 |
| `clingo_symbol_to_string_size` | Internal native operation; no Elixir value facade | [support.ex](../test/support.ex) | 447 |
| `clingo_symbol_to_string` | `Clingo.Internal.API.symbol_to_string` (Elixir values) | [ast_test.exs](../test/ast_test.exs), [public_api_test.exs](../test/public_api_test.exs), [support.ex](../test/support.ex) | 457 |
| `clingo_symbol_is_equal_to` | `Clingo.Internal.API.symbol_is_equal_to` (Elixir values) | [public_api_test.exs](../test/public_api_test.exs), [symbol_test.exs](../test/symbol_test.exs) | 469 |
| `clingo_symbol_is_less_than` | `Clingo.Internal.API.symbol_is_less_than` (Elixir values) | [symbol_test.exs](../test/symbol_test.exs) | 479 |
| `clingo_symbol_hash` | Internal native operation; no Elixir value facade | [symbol_test.exs](../test/symbol_test.exs) | 484 |
| `clingo_add_string` | Internal native operation; no Elixir value facade | [symbol_test.exs](../test/symbol_test.exs) | 497 |
| `clingo_parse_term` | Internal native operation; no Elixir value facade | [support.ex](../test/support.ex) | 511 |
| `clingo_symbolic_atoms_size` | `Clingo.Internal.API.symbolic_atoms_size` (Elixir values) | [callback_test.exs](../test/callback_test.exs), [inspection_test.exs](../test/inspection_test.exs), [lifecycle_test.exs](../test/lifecycle_test.exs) | 562 |
| `clingo_symbolic_atoms_begin` | `Clingo.Internal.API.symbolic_atoms_begin` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 570 |
| `clingo_symbolic_atoms_end` | `Clingo.Internal.API.symbolic_atoms_end` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 578 |
| `clingo_symbolic_atoms_find` | `Clingo.Internal.API.symbolic_atoms_find` (Elixir values) | [callback_test.exs](../test/callback_test.exs), [inspection_test.exs](../test/inspection_test.exs), [propagation_test.exs](../test/propagation_test.exs), [solve_test.exs](../test/solve_test.exs) | 587 |
| `clingo_symbolic_atoms_iterator_is_equal_to` | `Clingo.Internal.API.symbolic_atoms_iterator_is_equal_to` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 596 |
| `clingo_symbolic_atoms_symbol` | `Clingo.Internal.API.symbolic_atoms_symbol` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 606 |
| `clingo_symbolic_atoms_is_fact` | `Clingo.Internal.API.symbolic_atoms_is_fact` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 619 |
| `clingo_symbolic_atoms_is_external` | `Clingo.Internal.API.symbolic_atoms_is_external` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 630 |
| `clingo_symbolic_atoms_literal` | `Clingo.Internal.API.symbolic_atoms_literal` (Elixir values) | [callback_test.exs](../test/callback_test.exs), [propagation_test.exs](../test/propagation_test.exs), [solve_test.exs](../test/solve_test.exs) | 643 |
| `clingo_symbolic_atoms_signatures_size` | Internal native operation; no Elixir value facade | [inspection_test.exs](../test/inspection_test.exs) | 651 |
| `clingo_symbolic_atoms_signatures` | `Clingo.Internal.API.symbolic_atoms_signatures` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 663 |
| `clingo_symbolic_atoms_next` | `Clingo.Internal.API.symbolic_atoms_next` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 671 |
| `clingo_symbolic_atoms_is_valid` | `Clingo.Internal.API.symbolic_atoms_is_valid` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 682 |
| `clingo_theory_atoms_term_type` | `Clingo.Internal.API.theory_atoms_term_type` (Elixir values) | [backend_test.exs](../test/backend_test.exs) | 761 |
| `clingo_theory_atoms_term_number` | `Clingo.Internal.API.theory_atoms_term_number` (Elixir values) | [backend_test.exs](../test/backend_test.exs) | 770 |
| `clingo_theory_atoms_term_name` | `Clingo.Internal.API.theory_atoms_term_name` (Elixir values) | [backend_test.exs](../test/backend_test.exs) | 782 |
| `clingo_theory_atoms_term_arguments` | `Clingo.Internal.API.theory_atoms_term_arguments` (Elixir values) | [backend_test.exs](../test/backend_test.exs) | 792 |
| `clingo_theory_atoms_term_to_string_size` | Internal native operation; no Elixir value facade | [backend_test.exs](../test/backend_test.exs) | 801 |
| `clingo_theory_atoms_term_to_string` | `Clingo.Internal.API.theory_atoms_term_to_string` (Elixir values) | [backend_test.exs](../test/backend_test.exs) | 814 |
| `clingo_theory_atoms_element_tuple` | `Clingo.Internal.API.theory_atoms_element_tuple` (Elixir values) | [backend_test.exs](../test/backend_test.exs) | 828 |
| `clingo_theory_atoms_element_condition` | `Clingo.Internal.API.theory_atoms_element_condition` (Elixir values) | [backend_test.exs](../test/backend_test.exs) | 838 |
| `clingo_theory_atoms_element_condition_id` | `Clingo.Internal.API.theory_atoms_element_condition_id` (Elixir values) | [backend_test.exs](../test/backend_test.exs) | 852 |
| `clingo_theory_atoms_element_to_string_size` | Internal native operation; no Elixir value facade | [backend_test.exs](../test/backend_test.exs) | 862 |
| `clingo_theory_atoms_element_to_string` | `Clingo.Internal.API.theory_atoms_element_to_string` (Elixir values) | [backend_test.exs](../test/backend_test.exs) | 873 |
| `clingo_theory_atoms_size` | `Clingo.Internal.API.theory_atoms_size` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [callback_test.exs](../test/callback_test.exs) | 885 |
| `clingo_theory_atoms_atom_term` | `Clingo.Internal.API.theory_atoms_atom_term` (Elixir values) | [backend_test.exs](../test/backend_test.exs) | 892 |
| `clingo_theory_atoms_atom_elements` | `Clingo.Internal.API.theory_atoms_atom_elements` (Elixir values) | [backend_test.exs](../test/backend_test.exs) | 901 |
| `clingo_theory_atoms_atom_has_guard` | `Clingo.Internal.API.theory_atoms_atom_has_guard` (Elixir values) | [backend_test.exs](../test/backend_test.exs) | 909 |
| `clingo_theory_atoms_atom_guard` | `Clingo.Internal.API.theory_atoms_atom_guard` (Elixir values) | [backend_test.exs](../test/backend_test.exs) | 921 |
| `clingo_theory_atoms_atom_literal` | `Clingo.Internal.API.theory_atoms_atom_literal` (Elixir values) | [backend_test.exs](../test/backend_test.exs) | 929 |
| `clingo_theory_atoms_atom_to_string_size` | Internal native operation; no Elixir value facade | [backend_test.exs](../test/backend_test.exs) | 938 |
| `clingo_theory_atoms_atom_to_string` | `Clingo.Internal.API.theory_atoms_atom_to_string` (Elixir values) | [backend_test.exs](../test/backend_test.exs) | 949 |
| `clingo_assignment_decision_level` | `Clingo.Internal.API.assignment_decision_level` (Elixir values) | [callback_test.exs](../test/callback_test.exs), [propagation_test.exs](../test/propagation_test.exs) | 997 |
| `clingo_assignment_root_level` | `Clingo.Internal.API.assignment_root_level` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1004 |
| `clingo_assignment_has_conflict` | `Clingo.Internal.API.assignment_has_conflict` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1009 |
| `clingo_assignment_has_literal` | `Clingo.Internal.API.assignment_has_literal` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1015 |
| `clingo_assignment_level` | `Clingo.Internal.API.assignment_level` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1023 |
| `clingo_assignment_decision` | `Clingo.Internal.API.assignment_decision` (Elixir values) | [propagation_test.exs](../test/propagation_test.exs) | 1031 |
| `clingo_assignment_is_fixed` | `Clingo.Internal.API.assignment_is_fixed` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1039 |
| `clingo_assignment_is_true` | `Clingo.Internal.API.assignment_is_true` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1048 |
| `clingo_assignment_is_false` | `Clingo.Internal.API.assignment_is_false` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1057 |
| `clingo_assignment_truth_value` | `Clingo.Internal.API.assignment_truth_value` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1065 |
| `clingo_assignment_size` | `Clingo.Internal.API.assignment_size` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1071 |
| `clingo_assignment_at` | `Clingo.Internal.API.assignment_at` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1078 |
| `clingo_assignment_is_total` | `Clingo.Internal.API.assignment_is_total` (Elixir values) | [callback_test.exs](../test/callback_test.exs), [concurrency_test.exs](../test/concurrency_test.exs) | 1084 |
| `clingo_assignment_trail_size` | `Clingo.Internal.API.assignment_trail_size` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1090 |
| `clingo_assignment_trail_begin` | `Clingo.Internal.API.assignment_trail_begin` (Elixir values) | [propagation_test.exs](../test/propagation_test.exs) | 1104 |
| `clingo_assignment_trail_end` | `Clingo.Internal.API.assignment_trail_end` (Elixir values) | [propagation_test.exs](../test/propagation_test.exs) | 1114 |
| `clingo_assignment_trail_at` | `Clingo.Internal.API.assignment_trail_at` (Elixir values) | [propagation_test.exs](../test/propagation_test.exs) | 1122 |
| `clingo_propagate_init_solver_literal` | `Clingo.Internal.API.propagate_init_solver_literal` (Elixir values) | [callback_test.exs](../test/callback_test.exs), [propagation_test.exs](../test/propagation_test.exs) | 1180 |
| `clingo_propagate_init_add_watch` | `Clingo.Internal.API.propagate_init_add_watch` (Elixir values) | [callback_test.exs](../test/callback_test.exs), [propagation_test.exs](../test/propagation_test.exs) | 1188 |
| `clingo_propagate_init_add_watch_to_thread` | `Clingo.Internal.API.propagate_init_add_watch_to_thread` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1196 |
| `clingo_propagate_init_remove_watch` | `Clingo.Internal.API.propagate_init_remove_watch` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1204 |
| `clingo_propagate_init_remove_watch_from_thread` | `Clingo.Internal.API.propagate_init_remove_watch_from_thread` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1212 |
| `clingo_propagate_init_freeze_literal` | `Clingo.Internal.API.propagate_init_freeze_literal` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1225 |
| `clingo_propagate_init_symbolic_atoms` | `Clingo.Internal.API.propagate_init_symbolic_atoms` (Elixir values) | [callback_test.exs](../test/callback_test.exs), [propagation_test.exs](../test/propagation_test.exs) | 1232 |
| `clingo_propagate_init_theory_atoms` | `Clingo.Internal.API.propagate_init_theory_atoms` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1239 |
| `clingo_propagate_init_number_of_threads` | `Clingo.Internal.API.propagate_init_number_of_threads` (Elixir values) | [callback_test.exs](../test/callback_test.exs), [concurrency_test.exs](../test/concurrency_test.exs) | 1246 |
| `clingo_propagate_init_set_check_mode` | `Clingo.Internal.API.propagate_init_set_check_mode` (Elixir values) | [callback_test.exs](../test/callback_test.exs), [concurrency_test.exs](../test/concurrency_test.exs), [maintenance_test.exs](../test/maintenance_test.exs), [propagation_test.exs](../test/propagation_test.exs) | 1252 |
| `clingo_propagate_init_get_check_mode` | `Clingo.Internal.API.propagate_init_get_check_mode` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1259 |
| `clingo_propagate_init_set_undo_mode` | `Clingo.Internal.API.propagate_init_set_undo_mode` (Elixir values) | [callback_test.exs](../test/callback_test.exs), [propagation_test.exs](../test/propagation_test.exs) | 1265 |
| `clingo_propagate_init_get_undo_mode` | `Clingo.Internal.API.propagate_init_get_undo_mode` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1272 |
| `clingo_propagate_init_assignment` | `Clingo.Internal.API.propagate_init_assignment` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1278 |
| `clingo_propagate_init_add_literal` | `Clingo.Internal.API.propagate_init_add_literal` (Elixir values) | [propagation_test.exs](../test/propagation_test.exs) | 1292 |
| `clingo_propagate_init_add_clause` | `Clingo.Internal.API.propagate_init_add_clause` (Elixir values) | [propagation_test.exs](../test/propagation_test.exs) | 1305 |
| `clingo_propagate_init_add_weight_constraint` | `Clingo.Internal.API.propagate_init_add_weight_constraint` (Elixir values) | [propagation_test.exs](../test/propagation_test.exs) | 1327 |
| `clingo_propagate_init_add_minimize` | `Clingo.Internal.API.propagate_init_add_minimize` (Elixir values) | [propagation_test.exs](../test/propagation_test.exs) | 1340 |
| `clingo_propagate_init_propagate` | `Clingo.Internal.API.propagate_init_propagate` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 1353 |
| `clingo_propagate_control_thread_id` | `Clingo.Internal.API.propagate_control_thread_id` (Elixir values) | [callback_test.exs](../test/callback_test.exs), [concurrency_test.exs](../test/concurrency_test.exs), [maintenance_test.exs](../test/maintenance_test.exs) | 1384 |
| `clingo_propagate_control_assignment` | `Clingo.Internal.API.propagate_control_assignment` (Elixir values) | [callback_test.exs](../test/callback_test.exs), [concurrency_test.exs](../test/concurrency_test.exs), [propagation_test.exs](../test/propagation_test.exs) | 1390 |
| `clingo_propagate_control_add_literal` | `Clingo.Internal.API.propagate_control_add_literal` (Elixir values) | [propagation_test.exs](../test/propagation_test.exs) | 1401 |
| `clingo_propagate_control_add_watch` | `Clingo.Internal.API.propagate_control_add_watch` (Elixir values) | [propagation_test.exs](../test/propagation_test.exs) | 1414 |
| `clingo_propagate_control_has_watch` | `Clingo.Internal.API.propagate_control_has_watch` (Elixir values) | [propagation_test.exs](../test/propagation_test.exs) | 1422 |
| `clingo_propagate_control_remove_watch` | `Clingo.Internal.API.propagate_control_remove_watch` (Elixir values) | [propagation_test.exs](../test/propagation_test.exs) | 1430 |
| `clingo_propagate_control_add_clause` | `Clingo.Internal.API.propagate_control_add_clause` (Elixir values) | [propagation_test.exs](../test/propagation_test.exs) | 1446 |
| `clingo_propagate_control_propagate` | `Clingo.Internal.API.propagate_control_propagate` (Elixir values) | [propagation_test.exs](../test/propagation_test.exs) | 1460 |
| `clingo_backend_begin` | `Clingo.Internal.API.backend_begin` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [observer_test.exs](../test/observer_test.exs) | 1662 |
| `clingo_backend_end` | `Clingo.Internal.API.backend_end` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [observer_test.exs](../test/observer_test.exs) | 1669 |
| `clingo_backend_rule` | `Clingo.Internal.API.backend_rule` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [observer_test.exs](../test/observer_test.exs) | 1680 |
| `clingo_backend_weight_rule` | `Clingo.Internal.API.backend_weight_rule` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [observer_test.exs](../test/observer_test.exs) | 1694 |
| `clingo_backend_minimize` | `Clingo.Internal.API.backend_minimize` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [observer_test.exs](../test/observer_test.exs) | 1706 |
| `clingo_backend_project` | `Clingo.Internal.API.backend_project` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [observer_test.exs](../test/observer_test.exs) | 1715 |
| `clingo_backend_external` | `Clingo.Internal.API.backend_external` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [observer_test.exs](../test/observer_test.exs) | 1724 |
| `clingo_backend_assume` | `Clingo.Internal.API.backend_assume` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [observer_test.exs](../test/observer_test.exs) | 1734 |
| `clingo_backend_heuristic` | `Clingo.Internal.API.backend_heuristic` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [observer_test.exs](../test/observer_test.exs) | 1747 |
| `clingo_backend_acyc_edge` | `Clingo.Internal.API.backend_acyc_edge` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [observer_test.exs](../test/observer_test.exs) | 1759 |
| `clingo_backend_add_atom` | `Clingo.Internal.API.backend_add_atom` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [observer_test.exs](../test/observer_test.exs) | 1767 |
| `clingo_backend_theory_term_number` | `Clingo.Internal.API.backend_theory_term_number` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [observer_test.exs](../test/observer_test.exs) | 1776 |
| `clingo_backend_theory_term_string` | `Clingo.Internal.API.backend_theory_term_string` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [observer_test.exs](../test/observer_test.exs) | 1785 |
| `clingo_backend_theory_term_sequence` | `Clingo.Internal.API.backend_theory_term_sequence` (Elixir values) | [backend_test.exs](../test/backend_test.exs) | 1796 |
| `clingo_backend_theory_term_function` | `Clingo.Internal.API.backend_theory_term_function` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [observer_test.exs](../test/observer_test.exs) | 1809 |
| `clingo_backend_theory_term_symbol` | `Clingo.Internal.API.backend_theory_term_symbol` (Elixir values) | [backend_test.exs](../test/backend_test.exs) | 1819 |
| `clingo_backend_theory_element` | `Clingo.Internal.API.backend_theory_element` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [observer_test.exs](../test/observer_test.exs) | 1831 |
| `clingo_backend_theory_atom` | `Clingo.Internal.API.backend_theory_atom` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [observer_test.exs](../test/observer_test.exs) | 1848 |
| `clingo_backend_theory_atom_with_guard` | `Clingo.Internal.API.backend_theory_atom_with_guard` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [observer_test.exs](../test/observer_test.exs) | 1865 |
| `clingo_configuration_root` | `Clingo.Internal.API.configuration_root` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 1922 |
| `clingo_configuration_type` | `Clingo.Internal.API.configuration_type` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 1931 |
| `clingo_configuration_description` | `Clingo.Internal.API.configuration_description` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 1939 |
| `clingo_configuration_array_size` | `Clingo.Internal.API.configuration_array_size` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 1952 |
| `clingo_configuration_array_at` | `Clingo.Internal.API.configuration_array_at` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 1964 |
| `clingo_configuration_map_size` | `Clingo.Internal.API.configuration_map_size` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 1978 |
| `clingo_configuration_map_has_subkey` | `Clingo.Internal.API.configuration_map_has_subkey` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 1989 |
| `clingo_configuration_map_subkey_name` | `Clingo.Internal.API.configuration_map_subkey_name` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 1999 |
| `clingo_configuration_map_at` | `Clingo.Internal.API.configuration_map_at` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 2010 |
| `clingo_configuration_value_is_assigned` | `Clingo.Internal.API.configuration_value_is_assigned` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 2024 |
| `clingo_configuration_value_get_size` | Internal native operation; no Elixir value facade | [inspection_test.exs](../test/inspection_test.exs) | 2033 |
| `clingo_configuration_value_get` | `Clingo.Internal.API.configuration_value_get` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 2044 |
| `clingo_configuration_value_set` | `Clingo.Internal.API.configuration_value_set` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 2053 |
| `clingo_statistics_root` | `Clingo.Internal.API.statistics_root` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 2119 |
| `clingo_statistics_type` | `Clingo.Internal.API.statistics_type` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 2126 |
| `clingo_statistics_array_size` | `Clingo.Internal.API.statistics_array_size` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 2139 |
| `clingo_statistics_array_at` | `Clingo.Internal.API.statistics_array_at` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 2149 |
| `clingo_statistics_array_push` | `Clingo.Internal.API.statistics_array_push` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 2159 |
| `clingo_statistics_map_size` | `Clingo.Internal.API.statistics_map_size` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 2173 |
| `clingo_statistics_map_has_subkey` | `Clingo.Internal.API.statistics_map_has_subkey` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 2183 |
| `clingo_statistics_map_subkey_name` | `Clingo.Internal.API.statistics_map_subkey_name` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 2193 |
| `clingo_statistics_map_at` | `Clingo.Internal.API.statistics_map_at` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 2204 |
| `clingo_statistics_map_add_subkey` | `Clingo.Internal.API.statistics_map_add_subkey` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 2215 |
| `clingo_statistics_value_get` | `Clingo.Internal.API.statistics_value_get` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 2230 |
| `clingo_statistics_value_set` | `Clingo.Internal.API.statistics_value_set` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 2239 |
| `clingo_model_type` | Internal native operation; no Elixir value facade | [solve_test.exs](../test/solve_test.exs) | 2322 |
| `clingo_model_number` | Internal native operation; no Elixir value facade | [application_test.exs](../test/application_test.exs), [callback_test.exs](../test/callback_test.exs), [concurrency_test.exs](../test/concurrency_test.exs), [safety_test.exs](../test/safety_test.exs), [solve_test.exs](../test/solve_test.exs) | 2328 |
| `clingo_model_symbols_size` | Internal native operation; no Elixir value facade | [support.ex](../test/support.ex) | 2336 |
| `clingo_model_symbols` | `Clingo.Internal.API.model_symbols` (Elixir values) | [concurrency_test.exs](../test/concurrency_test.exs), [public_api_test.exs](../test/public_api_test.exs), [support.ex](../test/support.ex) | 2353 |
| `clingo_model_contains` | `Clingo.Internal.API.model_contains` (Elixir values) | [propagation_test.exs](../test/propagation_test.exs), [solve_test.exs](../test/solve_test.exs) | 2361 |
| `clingo_model_is_true` | `Clingo.Internal.API.model_is_true` (Elixir values) | [propagation_test.exs](../test/propagation_test.exs) | 2369 |
| `clingo_model_is_consequence` | `Clingo.Internal.API.model_is_consequence` (Elixir values) | [propagation_test.exs](../test/propagation_test.exs) | 2383 |
| `clingo_model_cost_size` | Internal native operation; no Elixir value facade | [solve_test.exs](../test/solve_test.exs) | 2390 |
| `clingo_model_cost` | Internal native operation; no Elixir value facade | [solve_test.exs](../test/solve_test.exs) | 2402 |
| `clingo_model_priority` | `Clingo.Internal.API.model_priority` (Elixir values) | [solve_test.exs](../test/solve_test.exs) | 2415 |
| `clingo_model_optimality_proven` | Internal native operation; no Elixir value facade | [solve_test.exs](../test/solve_test.exs) | 2424 |
| `clingo_model_thread_id` | `Clingo.Internal.API.model_thread_id` (Elixir values) | [solve_test.exs](../test/solve_test.exs) | 2430 |
| `clingo_model_extend` | `Clingo.Internal.API.model_extend` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 2441 |
| `clingo_model_context` | `Clingo.Internal.API.model_context` (Elixir values) | [callback_test.exs](../test/callback_test.exs), [propagation_test.exs](../test/propagation_test.exs) | 2453 |
| `clingo_solve_control_symbolic_atoms` | `Clingo.Internal.API.solve_control_symbolic_atoms` (Elixir values) | [callback_test.exs](../test/callback_test.exs) | 2459 |
| `clingo_solve_control_add_clause` | `Clingo.Internal.API.solve_control_add_clause` (Elixir values) | [propagation_test.exs](../test/propagation_test.exs) | 2473 |
| `clingo_solve_handle_get` | Internal native operation; no Elixir value facade | [callback_test.exs](../test/callback_test.exs), [concurrency_test.exs](../test/concurrency_test.exs), [lifecycle_test.exs](../test/lifecycle_test.exs), [solve_test.exs](../test/solve_test.exs) | 2577 |
| `clingo_solve_handle_wait` | Internal native operation; no Elixir value facade | [lifecycle_test.exs](../test/lifecycle_test.exs) | 2587 |
| `clingo_solve_handle_model` | `Clingo.Internal.API.solve_handle_model` (Elixir values) | [concurrency_test.exs](../test/concurrency_test.exs), [lifecycle_test.exs](../test/lifecycle_test.exs), [propagation_test.exs](../test/propagation_test.exs), [public_api_test.exs](../test/public_api_test.exs), [safety_test.exs](../test/safety_test.exs), [solve_test.exs](../test/solve_test.exs), [support.ex](../test/support.ex) | 2595 |
| `clingo_solve_handle_core` | Internal native operation; no Elixir value facade | [solve_test.exs](../test/solve_test.exs) | 2605 |
| `clingo_solve_handle_last` | Internal native operation; no Elixir value facade | [solve_test.exs](../test/solve_test.exs) | 2616 |
| `clingo_solve_handle_resume` | `Clingo.Internal.API.solve_handle_resume` (Elixir values) | [concurrency_test.exs](../test/concurrency_test.exs), [lifecycle_test.exs](../test/lifecycle_test.exs), [propagation_test.exs](../test/propagation_test.exs), [public_api_test.exs](../test/public_api_test.exs), [safety_test.exs](../test/safety_test.exs), [solve_test.exs](../test/solve_test.exs), [support.ex](../test/support.ex) | 2627 |
| `clingo_solve_handle_cancel` | Internal native operation; no Elixir value facade | [lifecycle_test.exs](../test/lifecycle_test.exs) | 2634 |
| `clingo_solve_handle_close` | `Clingo.Internal.API.solve_handle_close` (Elixir values) | [application_test.exs](../test/application_test.exs), [inspection_test.exs](../test/inspection_test.exs), [public_api_test.exs](../test/public_api_test.exs), [solve_test.exs](../test/solve_test.exs) | 2643 |
| `clingo_control_new` | `Clingo.Internal.API.control_new` (Elixir values) | [public_api_test.exs](../test/public_api_test.exs), [safety_test.exs](../test/safety_test.exs), [support.ex](../test/support.ex), [symbol_test.exs](../test/symbol_test.exs) | 2995 |
| `clingo_control_free` | `Clingo.Internal.API.control_free` (Elixir values) | [lifecycle_test.exs](../test/lifecycle_test.exs), [public_api_test.exs](../test/public_api_test.exs), [safety_test.exs](../test/safety_test.exs) | 3001 |
| `clingo_control_load` | `Clingo.Internal.API.control_load` (Elixir values) | [lifecycle_test.exs](../test/lifecycle_test.exs) | 3013 |
| `clingo_control_load_aspif` | `Clingo.Internal.API.control_load_aspif` (Elixir values) | [lifecycle_test.exs](../test/lifecycle_test.exs) | 3027 |
| `clingo_control_add` | `Clingo.Internal.API.control_add` (Elixir values) | [callback_test.exs](../test/callback_test.exs), [public_api_test.exs](../test/public_api_test.exs), [solve_test.exs](../test/solve_test.exs), [support.ex](../test/support.ex) | 3044 |
| `clingo_control_ground` | `Clingo.Internal.API.control_ground` (Elixir values) | [ast_test.exs](../test/ast_test.exs), [callback_test.exs](../test/callback_test.exs), [lifecycle_test.exs](../test/lifecycle_test.exs), [public_api_test.exs](../test/public_api_test.exs), [solve_test.exs](../test/solve_test.exs), [support.ex](../test/support.ex) | 3066 |
| `clingo_control_solve` | `Clingo.Internal.API.control_solve` (Elixir values) | [application_test.exs](../test/application_test.exs), [callback_test.exs](../test/callback_test.exs), [concurrency_test.exs](../test/concurrency_test.exs), [inspection_test.exs](../test/inspection_test.exs), [lifecycle_test.exs](../test/lifecycle_test.exs), [public_api_test.exs](../test/public_api_test.exs), [support.ex](../test/support.ex) | 3089 |
| `clingo_control_cleanup` | `Clingo.Internal.API.control_cleanup` (Elixir values) | [solve_test.exs](../test/solve_test.exs) | 3110 |
| `clingo_control_assign_external` | `Clingo.Internal.API.control_assign_external` (Elixir values) | [solve_test.exs](../test/solve_test.exs) | 3123 |
| `clingo_control_release_external` | `Clingo.Internal.API.control_release_external` (Elixir values) | [solve_test.exs](../test/solve_test.exs) | 3137 |
| `clingo_control_remove_minimize` | `Clingo.Internal.API.control_remove_minimize` (Elixir values) | [solve_test.exs](../test/solve_test.exs) | 3145 |
| `clingo_control_update_project` | `Clingo.Internal.API.control_update_project` (Elixir values) | [solve_test.exs](../test/solve_test.exs) | 3157 |
| `clingo_control_register_propagator` | `Clingo.Internal.API.control_register_propagator` (Elixir values) | [callback_test.exs](../test/callback_test.exs), [concurrency_test.exs](../test/concurrency_test.exs), [maintenance_test.exs](../test/maintenance_test.exs), [propagation_test.exs](../test/propagation_test.exs) | 3173 |
| `clingo_control_is_conflicting` | `Clingo.Internal.API.control_is_conflicting` (Elixir values) | [application_test.exs](../test/application_test.exs), [concurrency_test.exs](../test/concurrency_test.exs), [inventory_test.exs](../test/inventory_test.exs), [lifecycle_test.exs](../test/lifecycle_test.exs), [safety_test.exs](../test/safety_test.exs), [solve_test.exs](../test/solve_test.exs) | 3186 |
| `clingo_control_statistics` | `Clingo.Internal.API.control_statistics` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 3205 |
| `clingo_control_interrupt` | `Clingo.Internal.API.control_interrupt` (Elixir values) | [lifecycle_test.exs](../test/lifecycle_test.exs) | 3210 |
| `clingo_control_configuration` | `Clingo.Internal.API.control_configuration` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs) | 3236 |
| `clingo_control_set_enable_enumeration_assumption` | `Clingo.Internal.API.control_set_enable_enumeration_assumption` (Elixir values) | [solve_test.exs](../test/solve_test.exs) | 3254 |
| `clingo_control_get_enable_enumeration_assumption` | `Clingo.Internal.API.control_get_enable_enumeration_assumption` (Elixir values) | [solve_test.exs](../test/solve_test.exs) | 3260 |
| `clingo_control_set_enable_cleanup` | `Clingo.Internal.API.control_set_enable_cleanup` (Elixir values) | [solve_test.exs](../test/solve_test.exs) | 3272 |
| `clingo_control_get_enable_cleanup` | `Clingo.Internal.API.control_get_enable_cleanup` (Elixir values) | [solve_test.exs](../test/solve_test.exs) | 3281 |
| `clingo_control_get_const` | `Clingo.Internal.API.control_get_const` (Elixir values) | [solve_test.exs](../test/solve_test.exs) | 3294 |
| `clingo_control_has_const` | `Clingo.Internal.API.control_has_const` (Elixir values) | [solve_test.exs](../test/solve_test.exs) | 3305 |
| `clingo_control_symbolic_atoms` | `Clingo.Internal.API.control_symbolic_atoms` (Elixir values) | [inspection_test.exs](../test/inspection_test.exs), [lifecycle_test.exs](../test/lifecycle_test.exs), [propagation_test.exs](../test/propagation_test.exs), [solve_test.exs](../test/solve_test.exs) | 3315 |
| `clingo_control_theory_atoms` | `Clingo.Internal.API.control_theory_atoms` (Elixir values) | [backend_test.exs](../test/backend_test.exs) | 3324 |
| `clingo_control_register_observer` | `Clingo.Internal.API.control_register_observer` (Elixir values) | [callback_test.exs](../test/callback_test.exs), [observer_test.exs](../test/observer_test.exs), [public_api_test.exs](../test/public_api_test.exs), [typed_callbacks_test.exs](../test/typed_callbacks_test.exs) | 3333 |
| `clingo_control_register_backend` | `Clingo.Internal.API.control_register_backend` (Elixir values) | [lifecycle_test.exs](../test/lifecycle_test.exs) | 3348 |
| `clingo_control_backend` | `Clingo.Internal.API.control_backend` (Elixir values) | [backend_test.exs](../test/backend_test.exs), [observer_test.exs](../test/observer_test.exs) | 3363 |
| `clingo_ast_build` | Internal native operation; no Elixir value facade | [ast_test.exs](../test/ast_test.exs) | 3653 |
| `clingo_ast_acquire` | `Clingo.Internal.API.ast_acquire` (Elixir values) | [ast_test.exs](../test/ast_test.exs), [review_regression_test.exs](../test/review_regression_test.exs) | 3666 |
| `clingo_ast_release` | `Clingo.Internal.API.ast_release` (Elixir values) | [ast_test.exs](../test/ast_test.exs), [review_regression_test.exs](../test/review_regression_test.exs) | 3672 |
| `clingo_ast_copy` | Internal native operation; no Elixir value facade | [ast_test.exs](../test/ast_test.exs) | 3685 |
| `clingo_ast_deep_copy` | `Clingo.Internal.API.ast_deep_copy` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 3692 |
| `clingo_ast_less_than` | `Clingo.Internal.API.ast_less_than` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 3704 |
| `clingo_ast_equal` | `Clingo.Internal.API.ast_equal` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 3710 |
| `clingo_ast_hash` | `Clingo.Internal.API.ast_hash` (Elixir values) | [ast_test.exs](../test/ast_test.exs), [review_regression_test.exs](../test/review_regression_test.exs) | 3715 |
| `clingo_ast_to_string_size` | Internal native operation; no Elixir value facade | [support.ex](../test/support.ex) | 3728 |
| `clingo_ast_to_string` | `Clingo.Internal.API.ast_to_string` (Elixir values) | [support.ex](../test/support.ex) | 3736 |
| `clingo_ast_get_type` | `Clingo.Internal.API.ast_get_type` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 3749 |
| `clingo_ast_has_attribute` | `Clingo.Internal.API.ast_has_attribute` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 3757 |
| `clingo_ast_attribute_type` | `Clingo.Internal.API.ast_attribute_type` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 3766 |
| `clingo_ast_attribute_get_number` | `Clingo.Internal.API.ast_attribute_get_number` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 3781 |
| `clingo_ast_attribute_set_number` | Internal native operation; no Elixir value facade | [ast_test.exs](../test/ast_test.exs) | 3790 |
| `clingo_ast_attribute_get_symbol` | `Clingo.Internal.API.ast_attribute_get_symbol` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 3805 |
| `clingo_ast_attribute_set_symbol` | Internal native operation; no Elixir value facade | [ast_test.exs](../test/ast_test.exs) | 3814 |
| `clingo_ast_attribute_get_location` | `Clingo.Internal.API.ast_attribute_get_location` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 3829 |
| `clingo_ast_attribute_set_location` | Internal native operation; no Elixir value facade | [ast_test.exs](../test/ast_test.exs) | 3838 |
| `clingo_ast_attribute_get_string` | `Clingo.Internal.API.ast_attribute_get_string` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 3853 |
| `clingo_ast_attribute_set_string` | Internal native operation; no Elixir value facade | [ast_test.exs](../test/ast_test.exs) | 3862 |
| `clingo_ast_attribute_get_ast` | `Clingo.Internal.API.ast_attribute_get_ast` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 3877 |
| `clingo_ast_attribute_set_ast` | Internal native operation; no Elixir value facade | [ast_test.exs](../test/ast_test.exs) | 3886 |
| `clingo_ast_attribute_get_optional_ast` | `Clingo.Internal.API.ast_attribute_get_optional_ast` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 3904 |
| `clingo_ast_attribute_set_optional_ast` | Internal native operation; no Elixir value facade | [ast_test.exs](../test/ast_test.exs) | 3915 |
| `clingo_ast_attribute_get_string_at` | `Clingo.Internal.API.ast_attribute_get_string_at` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 3930 |
| `clingo_ast_attribute_set_string_at` | Internal native operation; no Elixir value facade | [ast_test.exs](../test/ast_test.exs) | 3941 |
| `clingo_ast_attribute_delete_string_at` | Internal native operation; no Elixir value facade | [ast_test.exs](../test/ast_test.exs) | 3950 |
| `clingo_ast_attribute_size_string_array` | `Clingo.Internal.API.ast_attribute_size_string_array` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 3959 |
| `clingo_ast_attribute_insert_string_at` | Internal native operation; no Elixir value facade | [ast_test.exs](../test/ast_test.exs) | 3970 |
| `clingo_ast_attribute_get_ast_at` | `Clingo.Internal.API.ast_attribute_get_ast_at` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 3987 |
| `clingo_ast_attribute_set_ast_at` | Internal native operation; no Elixir value facade | [ast_test.exs](../test/ast_test.exs) | 3998 |
| `clingo_ast_attribute_delete_ast_at` | Internal native operation; no Elixir value facade | [ast_test.exs](../test/ast_test.exs) | 4007 |
| `clingo_ast_attribute_size_ast_array` | `Clingo.Internal.API.ast_attribute_size_ast_array` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 4016 |
| `clingo_ast_attribute_insert_ast_at` | Internal native operation; no Elixir value facade | [ast_test.exs](../test/ast_test.exs) | 4027 |
| `clingo_ast_parse_string` | `Clingo.Internal.API.ast_parse_string` (Elixir values) | [ast_test.exs](../test/ast_test.exs), [inventory_test.exs](../test/inventory_test.exs), [review_regression_test.exs](../test/review_regression_test.exs), [safety_test.exs](../test/safety_test.exs) | 4055 |
| `clingo_ast_parse_files` | `Clingo.Internal.API.ast_parse_files` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 4077 |
| `clingo_program_builder_init` | `Clingo.Internal.API.program_builder_init` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 4097 |
| `clingo_program_builder_begin` | `Clingo.Internal.API.program_builder_begin` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 4103 |
| `clingo_program_builder_end` | `Clingo.Internal.API.program_builder_end` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 4108 |
| `clingo_program_builder_add` | `Clingo.Internal.API.program_builder_add` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 4118 |
| `clingo_ast_unpool` | `Clingo.Internal.API.ast_unpool` (Elixir values) | [ast_test.exs](../test/ast_test.exs) | 4142 |
| `clingo_options_add` | `Clingo.Internal.API.options_add` (Elixir values) | [application_test.exs](../test/application_test.exs) | 4252 |
| `clingo_options_add_flag` | `Clingo.Internal.API.options_add_flag` (Elixir values) | [application_test.exs](../test/application_test.exs) | 4266 |
| `clingo_main` | `Clingo.Internal.API.main` (Elixir values) | [application_test.exs](../test/application_test.exs) | 4276 |
| `clingo_register_script` | `Clingo.Internal.API.register_script` (Elixir values) | [application_test.exs](../test/application_test.exs) | 4322 |
| `clingo_script_version` | `Clingo.Internal.API.script_version` (Elixir values) | [application_test.exs](../test/application_test.exs) | 4327 |

## Non-function declarations

| Declaration | Binding |
|---|---|
| `clingo_error_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_warning_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_signature_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_signature_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_symbol_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_symbol_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_symbol_t**` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_symbol_type_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_logger_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_symbolic_atoms_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_symbolic_atoms_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_symbolic_atoms` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_symbolic_atom_iterator_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_symbolic_atom_iterator_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_literal_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_literal_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_theory_atoms_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_theory_atoms_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_theory_atoms` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_id_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_theory_term_type_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_theory_term_type_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_id_t**` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_id_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_literal_t**` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_assignment_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_assignment_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_assignment` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_truth_value_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_truth_value_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_propagate_init_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_propagate_init_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_propagate_init` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_symbolic_atoms_t**` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_theory_atoms_t**` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_propagator_check_mode_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_propagator_undo_mode_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_weighted_literal_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_weighted_literal_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_weighted_literal` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_weight_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_weight_constraint_type_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_propagate_control_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_propagate_control_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_propagate_control` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_clause_type_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_backend_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_backend_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_backend` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_atom_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_atom_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_external_type_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_heuristic_type_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_theory_sequence_type_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_configuration_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_configuration_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_configuration` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_configuration_type_bitset_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_configuration_type_bitset_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_statistics_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_statistics_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_statistic` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_statistics_type_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_statistics_type_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_model_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_model_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_model` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_model_type_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_model_type_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_show_type_bitset_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_consequence_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_consequence_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_weight_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_solve_control_t**` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_solve_control_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_solve_control_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_solve_control` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_solve_handle_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_solve_handle_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_solve_handle` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_solve_result_bitset_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_solve_result_bitset_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_model_t**` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_control_t**` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_control_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_control_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_control` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_part_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_part_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_part` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ground_callback_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_location_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_location_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_location` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_symbol_callback_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_solve_mode_bitset_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_solve_event_callback_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_solve_event_type_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_solve_handle_t**` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_propagator_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_propagator_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_propagator` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_statistics_t**` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_configuration_t**` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ground_program_observer_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ground_program_observer_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_ground_program_observer` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_backend_type_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_backend_t**` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_type_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_t**` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_ast` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_type_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_attribute_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_attribute_type_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_attribute_type_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_callback_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_program_builder_t**` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_program_builder_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_program_builder_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_program_builder` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_unpool_type_bitset_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_options_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_options_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_options` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_application_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_application_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_application` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_main_function_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_model_printer_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_default_model_printer_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_script_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_script_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_script` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_propagator_init_callback_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_propagator_propagate_callback_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_propagator_undo_callback_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_propagator_check_callback_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_comment_type_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_theory_sequence_type_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_comparison_operator_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_sign_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_unary_operator_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_binary_operator_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_aggregate_function_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_theory_operator_type_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_theory_atom_definition_type_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_attribute_names_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_ast_attribute_names` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_argument_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_ast_argument` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_constructor_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_ast_constructor` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_argument_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_constructors_t` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `struct clingo_ast_constructors` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `clingo_ast_constructor_t*` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_error_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_warning_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_truth_value_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_symbol_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_theory_term_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_propagator_check_mode_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_propagator_undo_mode_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_weight_constraint_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_clause_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_comment_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_theory_sequence_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_heuristic_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_external_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_configuration_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_statistics_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_model_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_show_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_consequence_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_solve_result_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_solve_mode_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_solve_event_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_backend_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_ast_theory_sequence_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_ast_comparison_operator_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_ast_sign_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_ast_unary_operator_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_ast_binary_operator_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_ast_aggregate_function_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_ast_theory_operator_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_ast_theory_atom_definition_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_ast_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_ast_attribute_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_ast_attribute_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `enum clingo_ast_unpool_type_e` | `Clingo.type/1`, typed allocation/read/write; callbacks via `Clingo.callback/3` |
| `g_clingo_ast_attribute_names` | `Clingo.global/2` |
| `g_clingo_ast_constructors` | `Clingo.global/2` |
| `clingo_error_success` | `Clingo.constant/1` |
| `clingo_error_runtime` | `Clingo.constant/1` |
| `clingo_error_logic` | `Clingo.constant/1` |
| `clingo_error_bad_alloc` | `Clingo.constant/1` |
| `clingo_error_unknown` | `Clingo.constant/1` |
| `clingo_warning_operation_undefined` | `Clingo.constant/1` |
| `clingo_warning_runtime_error` | `Clingo.constant/1` |
| `clingo_warning_atom_undefined` | `Clingo.constant/1` |
| `clingo_warning_file_included` | `Clingo.constant/1` |
| `clingo_warning_variable_unbounded` | `Clingo.constant/1` |
| `clingo_warning_global_variable` | `Clingo.constant/1` |
| `clingo_warning_other` | `Clingo.constant/1` |
| `clingo_truth_value_free` | `Clingo.constant/1` |
| `clingo_truth_value_true` | `Clingo.constant/1` |
| `clingo_truth_value_false` | `Clingo.constant/1` |
| `clingo_symbol_type_infimum` | `Clingo.constant/1` |
| `clingo_symbol_type_number` | `Clingo.constant/1` |
| `clingo_symbol_type_string` | `Clingo.constant/1` |
| `clingo_symbol_type_function` | `Clingo.constant/1` |
| `clingo_symbol_type_supremum` | `Clingo.constant/1` |
| `clingo_theory_term_type_tuple` | `Clingo.constant/1` |
| `clingo_theory_term_type_list` | `Clingo.constant/1` |
| `clingo_theory_term_type_set` | `Clingo.constant/1` |
| `clingo_theory_term_type_function` | `Clingo.constant/1` |
| `clingo_theory_term_type_number` | `Clingo.constant/1` |
| `clingo_theory_term_type_symbol` | `Clingo.constant/1` |
| `clingo_propagator_check_mode_none` | `Clingo.constant/1` |
| `clingo_propagator_check_mode_total` | `Clingo.constant/1` |
| `clingo_propagator_check_mode_fixpoint` | `Clingo.constant/1` |
| `clingo_propagator_check_mode_both` | `Clingo.constant/1` |
| `clingo_propagator_undo_mode_default` | `Clingo.constant/1` |
| `clingo_propagator_undo_mode_always` | `Clingo.constant/1` |
| `clingo_weight_constraint_type_implication_left` | `Clingo.constant/1` |
| `clingo_weight_constraint_type_implication_right` | `Clingo.constant/1` |
| `clingo_weight_constraint_type_equivalence` | `Clingo.constant/1` |
| `clingo_clause_type_learnt` | `Clingo.constant/1` |
| `clingo_clause_type_static` | `Clingo.constant/1` |
| `clingo_clause_type_volatile` | `Clingo.constant/1` |
| `clingo_clause_type_volatile_static` | `Clingo.constant/1` |
| `clingo_comment_type_line` | `Clingo.constant/1` |
| `clingo_comment_type_block` | `Clingo.constant/1` |
| `clingo_theory_sequence_type_tuple` | `Clingo.constant/1` |
| `clingo_theory_sequence_type_set` | `Clingo.constant/1` |
| `clingo_theory_sequence_type_list` | `Clingo.constant/1` |
| `clingo_heuristic_type_level` | `Clingo.constant/1` |
| `clingo_heuristic_type_sign` | `Clingo.constant/1` |
| `clingo_heuristic_type_factor` | `Clingo.constant/1` |
| `clingo_heuristic_type_init` | `Clingo.constant/1` |
| `clingo_heuristic_type_true` | `Clingo.constant/1` |
| `clingo_heuristic_type_false` | `Clingo.constant/1` |
| `clingo_external_type_free` | `Clingo.constant/1` |
| `clingo_external_type_true` | `Clingo.constant/1` |
| `clingo_external_type_false` | `Clingo.constant/1` |
| `clingo_external_type_release` | `Clingo.constant/1` |
| `clingo_configuration_type_value` | `Clingo.constant/1` |
| `clingo_configuration_type_array` | `Clingo.constant/1` |
| `clingo_configuration_type_map` | `Clingo.constant/1` |
| `clingo_statistics_type_empty` | `Clingo.constant/1` |
| `clingo_statistics_type_value` | `Clingo.constant/1` |
| `clingo_statistics_type_array` | `Clingo.constant/1` |
| `clingo_statistics_type_map` | `Clingo.constant/1` |
| `clingo_model_type_stable_model` | `Clingo.constant/1` |
| `clingo_model_type_brave_consequences` | `Clingo.constant/1` |
| `clingo_model_type_cautious_consequences` | `Clingo.constant/1` |
| `clingo_show_type_shown` | `Clingo.constant/1` |
| `clingo_show_type_atoms` | `Clingo.constant/1` |
| `clingo_show_type_terms` | `Clingo.constant/1` |
| `clingo_show_type_theory` | `Clingo.constant/1` |
| `clingo_show_type_all` | `Clingo.constant/1` |
| `clingo_show_type_complement` | `Clingo.constant/1` |
| `clingo_consequence_false` | `Clingo.constant/1` |
| `clingo_consequence_true` | `Clingo.constant/1` |
| `clingo_consequence_unknown` | `Clingo.constant/1` |
| `clingo_solve_result_satisfiable` | `Clingo.constant/1` |
| `clingo_solve_result_unsatisfiable` | `Clingo.constant/1` |
| `clingo_solve_result_exhausted` | `Clingo.constant/1` |
| `clingo_solve_result_interrupted` | `Clingo.constant/1` |
| `clingo_solve_mode_async` | `Clingo.constant/1` |
| `clingo_solve_mode_yield` | `Clingo.constant/1` |
| `clingo_solve_event_type_model` | `Clingo.constant/1` |
| `clingo_solve_event_type_unsat` | `Clingo.constant/1` |
| `clingo_solve_event_type_statistics` | `Clingo.constant/1` |
| `clingo_solve_event_type_finish` | `Clingo.constant/1` |
| `clingo_backend_type_reify` | `Clingo.constant/1` |
| `clingo_backend_type_reify_sccs` | `Clingo.constant/1` |
| `clingo_backend_type_reify_steps` | `Clingo.constant/1` |
| `clingo_backend_type_aspif` | `Clingo.constant/1` |
| `clingo_backend_type_smodels` | `Clingo.constant/1` |
| `clingo_ast_theory_sequence_type_tuple` | `Clingo.constant/1` |
| `clingo_ast_theory_sequence_type_list` | `Clingo.constant/1` |
| `clingo_ast_theory_sequence_type_set` | `Clingo.constant/1` |
| `clingo_ast_comparison_operator_greater_than` | `Clingo.constant/1` |
| `clingo_ast_comparison_operator_less_than` | `Clingo.constant/1` |
| `clingo_ast_comparison_operator_less_equal` | `Clingo.constant/1` |
| `clingo_ast_comparison_operator_greater_equal` | `Clingo.constant/1` |
| `clingo_ast_comparison_operator_not_equal` | `Clingo.constant/1` |
| `clingo_ast_comparison_operator_equal` | `Clingo.constant/1` |
| `clingo_ast_sign_no_sign` | `Clingo.constant/1` |
| `clingo_ast_sign_negation` | `Clingo.constant/1` |
| `clingo_ast_sign_double_negation` | `Clingo.constant/1` |
| `clingo_ast_unary_operator_minus` | `Clingo.constant/1` |
| `clingo_ast_unary_operator_negation` | `Clingo.constant/1` |
| `clingo_ast_unary_operator_absolute` | `Clingo.constant/1` |
| `clingo_ast_binary_operator_xor` | `Clingo.constant/1` |
| `clingo_ast_binary_operator_or` | `Clingo.constant/1` |
| `clingo_ast_binary_operator_and` | `Clingo.constant/1` |
| `clingo_ast_binary_operator_plus` | `Clingo.constant/1` |
| `clingo_ast_binary_operator_minus` | `Clingo.constant/1` |
| `clingo_ast_binary_operator_multiplication` | `Clingo.constant/1` |
| `clingo_ast_binary_operator_division` | `Clingo.constant/1` |
| `clingo_ast_binary_operator_modulo` | `Clingo.constant/1` |
| `clingo_ast_binary_operator_power` | `Clingo.constant/1` |
| `clingo_ast_aggregate_function_count` | `Clingo.constant/1` |
| `clingo_ast_aggregate_function_sum` | `Clingo.constant/1` |
| `clingo_ast_aggregate_function_sump` | `Clingo.constant/1` |
| `clingo_ast_aggregate_function_min` | `Clingo.constant/1` |
| `clingo_ast_aggregate_function_max` | `Clingo.constant/1` |
| `clingo_ast_theory_operator_type_unary` | `Clingo.constant/1` |
| `clingo_ast_theory_operator_type_binary_left` | `Clingo.constant/1` |
| `clingo_ast_theory_operator_type_binary_right` | `Clingo.constant/1` |
| `clingo_ast_theory_atom_definition_type_head` | `Clingo.constant/1` |
| `clingo_ast_theory_atom_definition_type_body` | `Clingo.constant/1` |
| `clingo_ast_theory_atom_definition_type_any` | `Clingo.constant/1` |
| `clingo_ast_theory_atom_definition_type_directive` | `Clingo.constant/1` |
| `clingo_ast_type_id` | `Clingo.constant/1` |
| `clingo_ast_type_variable` | `Clingo.constant/1` |
| `clingo_ast_type_symbolic_term` | `Clingo.constant/1` |
| `clingo_ast_type_unary_operation` | `Clingo.constant/1` |
| `clingo_ast_type_binary_operation` | `Clingo.constant/1` |
| `clingo_ast_type_interval` | `Clingo.constant/1` |
| `clingo_ast_type_function` | `Clingo.constant/1` |
| `clingo_ast_type_pool` | `Clingo.constant/1` |
| `clingo_ast_type_boolean_constant` | `Clingo.constant/1` |
| `clingo_ast_type_symbolic_atom` | `Clingo.constant/1` |
| `clingo_ast_type_comparison` | `Clingo.constant/1` |
| `clingo_ast_type_guard` | `Clingo.constant/1` |
| `clingo_ast_type_conditional_literal` | `Clingo.constant/1` |
| `clingo_ast_type_aggregate` | `Clingo.constant/1` |
| `clingo_ast_type_body_aggregate_element` | `Clingo.constant/1` |
| `clingo_ast_type_body_aggregate` | `Clingo.constant/1` |
| `clingo_ast_type_head_aggregate_element` | `Clingo.constant/1` |
| `clingo_ast_type_head_aggregate` | `Clingo.constant/1` |
| `clingo_ast_type_disjunction` | `Clingo.constant/1` |
| `clingo_ast_type_theory_sequence` | `Clingo.constant/1` |
| `clingo_ast_type_theory_function` | `Clingo.constant/1` |
| `clingo_ast_type_theory_unparsed_term_element` | `Clingo.constant/1` |
| `clingo_ast_type_theory_unparsed_term` | `Clingo.constant/1` |
| `clingo_ast_type_theory_guard` | `Clingo.constant/1` |
| `clingo_ast_type_theory_atom_element` | `Clingo.constant/1` |
| `clingo_ast_type_theory_atom` | `Clingo.constant/1` |
| `clingo_ast_type_literal` | `Clingo.constant/1` |
| `clingo_ast_type_theory_operator_definition` | `Clingo.constant/1` |
| `clingo_ast_type_theory_term_definition` | `Clingo.constant/1` |
| `clingo_ast_type_theory_guard_definition` | `Clingo.constant/1` |
| `clingo_ast_type_theory_atom_definition` | `Clingo.constant/1` |
| `clingo_ast_type_rule` | `Clingo.constant/1` |
| `clingo_ast_type_definition` | `Clingo.constant/1` |
| `clingo_ast_type_show_signature` | `Clingo.constant/1` |
| `clingo_ast_type_show_term` | `Clingo.constant/1` |
| `clingo_ast_type_minimize` | `Clingo.constant/1` |
| `clingo_ast_type_script` | `Clingo.constant/1` |
| `clingo_ast_type_program` | `Clingo.constant/1` |
| `clingo_ast_type_external` | `Clingo.constant/1` |
| `clingo_ast_type_edge` | `Clingo.constant/1` |
| `clingo_ast_type_heuristic` | `Clingo.constant/1` |
| `clingo_ast_type_project_atom` | `Clingo.constant/1` |
| `clingo_ast_type_project_signature` | `Clingo.constant/1` |
| `clingo_ast_type_defined` | `Clingo.constant/1` |
| `clingo_ast_type_theory_definition` | `Clingo.constant/1` |
| `clingo_ast_type_comment` | `Clingo.constant/1` |
| `clingo_ast_attribute_type_number` | `Clingo.constant/1` |
| `clingo_ast_attribute_type_symbol` | `Clingo.constant/1` |
| `clingo_ast_attribute_type_location` | `Clingo.constant/1` |
| `clingo_ast_attribute_type_string` | `Clingo.constant/1` |
| `clingo_ast_attribute_type_ast` | `Clingo.constant/1` |
| `clingo_ast_attribute_type_optional_ast` | `Clingo.constant/1` |
| `clingo_ast_attribute_type_string_array` | `Clingo.constant/1` |
| `clingo_ast_attribute_type_ast_array` | `Clingo.constant/1` |
| `clingo_ast_attribute_argument` | `Clingo.constant/1` |
| `clingo_ast_attribute_arguments` | `Clingo.constant/1` |
| `clingo_ast_attribute_arity` | `Clingo.constant/1` |
| `clingo_ast_attribute_atom` | `Clingo.constant/1` |
| `clingo_ast_attribute_atoms` | `Clingo.constant/1` |
| `clingo_ast_attribute_atom_type` | `Clingo.constant/1` |
| `clingo_ast_attribute_bias` | `Clingo.constant/1` |
| `clingo_ast_attribute_body` | `Clingo.constant/1` |
| `clingo_ast_attribute_code` | `Clingo.constant/1` |
| `clingo_ast_attribute_coefficient` | `Clingo.constant/1` |
| `clingo_ast_attribute_comparison` | `Clingo.constant/1` |
| `clingo_ast_attribute_condition` | `Clingo.constant/1` |
| `clingo_ast_attribute_elements` | `Clingo.constant/1` |
| `clingo_ast_attribute_external` | `Clingo.constant/1` |
| `clingo_ast_attribute_external_type` | `Clingo.constant/1` |
| `clingo_ast_attribute_function` | `Clingo.constant/1` |
| `clingo_ast_attribute_guard` | `Clingo.constant/1` |
| `clingo_ast_attribute_guards` | `Clingo.constant/1` |
| `clingo_ast_attribute_head` | `Clingo.constant/1` |
| `clingo_ast_attribute_is_default` | `Clingo.constant/1` |
| `clingo_ast_attribute_left` | `Clingo.constant/1` |
| `clingo_ast_attribute_left_guard` | `Clingo.constant/1` |
| `clingo_ast_attribute_literal` | `Clingo.constant/1` |
| `clingo_ast_attribute_location` | `Clingo.constant/1` |
| `clingo_ast_attribute_modifier` | `Clingo.constant/1` |
| `clingo_ast_attribute_name` | `Clingo.constant/1` |
| `clingo_ast_attribute_node_u` | `Clingo.constant/1` |
| `clingo_ast_attribute_node_v` | `Clingo.constant/1` |
| `clingo_ast_attribute_operator_name` | `Clingo.constant/1` |
| `clingo_ast_attribute_operator_type` | `Clingo.constant/1` |
| `clingo_ast_attribute_operators` | `Clingo.constant/1` |
| `clingo_ast_attribute_parameters` | `Clingo.constant/1` |
| `clingo_ast_attribute_positive` | `Clingo.constant/1` |
| `clingo_ast_attribute_priority` | `Clingo.constant/1` |
| `clingo_ast_attribute_right` | `Clingo.constant/1` |
| `clingo_ast_attribute_right_guard` | `Clingo.constant/1` |
| `clingo_ast_attribute_sequence_type` | `Clingo.constant/1` |
| `clingo_ast_attribute_sign` | `Clingo.constant/1` |
| `clingo_ast_attribute_symbol` | `Clingo.constant/1` |
| `clingo_ast_attribute_term` | `Clingo.constant/1` |
| `clingo_ast_attribute_terms` | `Clingo.constant/1` |
| `clingo_ast_attribute_value` | `Clingo.constant/1` |
| `clingo_ast_attribute_variable` | `Clingo.constant/1` |
| `clingo_ast_attribute_weight` | `Clingo.constant/1` |
| `clingo_ast_attribute_comment_type` | `Clingo.constant/1` |
| `clingo_ast_unpool_type_condition` | `Clingo.constant/1` |
| `clingo_ast_unpool_type_other` | `Clingo.constant/1` |
| `clingo_ast_unpool_type_all` | `Clingo.constant/1` |

Version macros: `Clingo.version/0` and `Clingo.constant/1`. Visibility/export macros are compile-time linkage directives; `CLINGO_DEPRECATED` marks declarations and introduces no callable capability. Header guards, standard includes, and C++ linkage guards have no runtime operation.

## Struct callback extension points

| Callback field | Binding |
|---|---|
| `struct clingo_propagator.init` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_propagator.propagate` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_propagator.undo` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_propagator.check` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_propagator.decide` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.init_program` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.begin_step` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.end_step` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.rule` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.weight_rule` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.minimize` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.project` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.output_atom` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.output_term` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.external` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.assume` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.heuristic` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.acyc_edge` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.theory_term_number` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.theory_term_string` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.theory_term_compound` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.theory_element` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.theory_atom` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_ground_program_observer.theory_atom_with_guard` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_application.program_name` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_application.version` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_application.message_limit` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_application.main` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_application.logger` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_application.printer` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_application.register_options` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_application.validate_options` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_script.execute` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_script.call` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_script.callable` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_script.main` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
| `struct clingo_script.free` | Typed callback field; `Clingo.callback/3`, `Clingo.type/1`; extension tests |
