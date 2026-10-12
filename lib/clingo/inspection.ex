defmodule Clingo.Inspection do
  @moduledoc "Copied symbolic/theory atom inspection. Snapshots remain usable after grounding or close."
  alias Clingo.Internal.API, as: A
  import Clingo.Binding, only: [value: 1]

  def symbolic_atoms!(control) do
    Clingo.scoped(control.session, fn ->
      s = control.session
      atoms = value(A.control_symbolic_atoms(s, control.handle))
      iterator = value(A.symbolic_atoms_begin(s, atoms, nil))
      symbolic(s, atoms, iterator, [])
    end)
  end

  defp symbolic(s, atoms, iterator, acc) do
    if value(A.symbolic_atoms_is_valid(s, atoms, iterator)) do
      atom = %{
        symbol: Clingo.Symbol.decode(s, value(A.symbolic_atoms_symbol(s, atoms, iterator))),
        literal: value(A.symbolic_atoms_literal(s, atoms, iterator)),
        fact: value(A.symbolic_atoms_is_fact(s, atoms, iterator)),
        external: value(A.symbolic_atoms_is_external(s, atoms, iterator))
      }

      symbolic(s, atoms, value(A.symbolic_atoms_next(s, atoms, iterator)), [atom | acc])
    else
      Enum.reverse(acc)
    end
  end

  def theory_atoms!(control) do
    Clingo.scoped(control.session, fn ->
      s = control.session
      atoms = value(A.control_theory_atoms(s, control.handle))

      for id <- indices(value(A.theory_atoms_size(s, atoms))) do
        term = value(A.theory_atoms_atom_term(s, atoms, id))

        guard =
          if value(A.theory_atoms_atom_has_guard(s, atoms, id)) do
            {operator, rhs} = value(A.theory_atoms_atom_guard(s, atoms, id))
            {operator, value(A.theory_atoms_term_to_string(s, atoms, rhs))}
          end

        %{
          term: value(A.theory_atoms_term_to_string(s, atoms, term)),
          literal: value(A.theory_atoms_atom_literal(s, atoms, id)),
          guard: guard,
          elements:
            for element <- value(A.theory_atoms_atom_elements(s, atoms, id)) do
              %{
                terms:
                  Enum.map(
                    value(A.theory_atoms_element_tuple(s, atoms, element)),
                    &value(A.theory_atoms_term_to_string(s, atoms, &1))
                  ),
                condition: value(A.theory_atoms_element_condition(s, atoms, element)),
                condition_id: value(A.theory_atoms_element_condition_id(s, atoms, element))
              }
            end
        }
      end
    end)
  end

  defp indices(0), do: []
  defp indices(n), do: 0..(n - 1)
end
