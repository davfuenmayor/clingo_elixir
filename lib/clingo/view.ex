defmodule Clingo.View do
  @moduledoc """
  A scoped native view for extension callbacks. Views retain native lifetime and
  thread restrictions. `call!/3` addresses operations within the view's C family;
  common propagation and assignment operations have named functions below.
  """
  alias Clingo.Internal.API, as: A
  defstruct [:session, :handle, :kind]

  @operations for family <- [:assignment, :propagate_init, :propagate_control],
                  {function, arity} <- A.__info__(:functions),
                  prefix = "#{family}_",
                  name = Atom.to_string(function),
                  String.starts_with?(name, prefix),
                  into: %{},
                  do: {{family, String.replace_prefix(name, prefix, ""), arity - 2}, function}

  def call!(%__MODULE__{} = view, operation, args \\ []) do
    unless (is_atom(operation) or is_binary(operation)) and is_list(args),
      do: raise(ArgumentError, "view operation must be a name with a list of arguments")

    function =
      Map.get(@operations, {view.kind, to_string(operation), length(args)}) ||
        raise ArgumentError,
              "unsupported #{view.kind} operation #{inspect(operation)}/#{length(args)}"

    case apply(A, function, [view.session, view.handle | args]) do
      {status, value} when status in [true, :ok] -> value
      other -> other
    end
  end

  def decision_level(v), do: call!(v, :decision_level)
  def thread_id(v), do: call!(v, :thread_id)

  def assignment(%__MODULE__{} = v),
    do: %__MODULE__{v | kind: :assignment, handle: call!(v, :assignment)}

  def solver_literal!(v, literal), do: call!(v, :solver_literal, [literal])
  def add_watch!(v, literal), do: call!(v, :add_watch, [literal]) && :ok
  def check_mode!(v, mode), do: call!(v, :set_check_mode, [mode])

  def add_clause!(v, literals, type \\ :clingo_clause_type_learnt),
    do: call!(v, :add_clause, [literals, type])

  def propagate!(v), do: call!(v, :propagate)
end
