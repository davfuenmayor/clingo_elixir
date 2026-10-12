defmodule Clingo.SafetyTest do
  use ExUnit.Case, async: true
  import Clingo.TestSupport
  alias Clingo.TestSupport.Raw, as: A

  test "output cells and saved aliases cannot revive a freed control" do
    Clingo.with_session(fn s ->
      cell = Clingo.alloc(s, "clingo_control_t*")
      assert A.control_new(s, nil, 0, nil, nil, 20, cell)
      control = Clingo.read(s, cell)
      saved = Clingo.array(s, "clingo_control_t*", [control])
      assert A.control_free(s, control) == :ok
      assert_raise ArgumentError, fn -> Clingo.read(s, cell) end
      assert_raise ArgumentError, fn -> Clingo.read(s, saved) end

      # A fresh output establishes a fresh lifetime, even if malloc reuses an address.
      for _ <- 1..30 do
        assert A.control_new(s, nil, 0, nil, nil, 20, cell)
        fresh = Clingo.read(s, cell)
        refute A.control_is_conflicting(s, fresh)
        assert_raise ArgumentError, fn -> Clingo.read(s, saved) end
        assert A.control_free(s, fresh) == :ok
      end
    end)
  end

  test "saved model pointers expire even when the native model address is reused" do
    Clingo.with_session(fn s ->
      h = handle(s, ground(s, control(s), "{a}."))
      assert A.solve_handle_resume(s, h)
      cell = Clingo.alloc(s, "clingo_model_t*")
      assert A.solve_handle_model(s, h, cell)
      saved = Clingo.array(s, "clingo_model_t*", [Clingo.read(s, cell)])
      assert A.solve_handle_resume(s, h)
      assert A.solve_handle_model(s, h, cell)
      assert A.model_number(s, Clingo.read(s, cell), Clingo.alloc(s, "uint64_t"))
      assert_raise ArgumentError, fn -> Clingo.read(s, saved) end
    end)
  end

  test "callback pointers saved in ordinary cells keep their callback lifetime" do
    Clingo.with_session(fn s ->
      saved = Clingo.alloc(s, "clingo_ast_t*")

      callback =
        Clingo.callback(s, "clingo_ast_callback_t", fn ast, _ ->
          Clingo.write(s, saved, ast)
          true
        end)

      assert A.ast_parse_string(s, "a.", callback, nil, nil, nil, nil, 20)
      assert_raise ArgumentError, fn -> Clingo.read(s, saved) end
    end)
  end

  test "interned symbol arguments stay immutable through reads, casts and native outputs" do
    Clingo.with_session(fn s ->
      value = symbol(s, "f(1)")
      cell = Clingo.alloc(s, "clingo_symbol_t*")
      assert A.symbol_arguments(s, value, cell, Clingo.alloc(s, "size_t"))
      args = Clingo.read(s, cell)
      assert Clingo.read(s, args) == symbol(s, "1")
      assert_raise ArgumentError, fn -> Clingo.write(s, args, symbol(s, "2")) end
      view = Clingo.cast(s, args, "clingo_symbol_t", 1)
      assert_raise ArgumentError, fn -> Clingo.write(s, view, symbol(s, "2")) end
      assert_raise ArgumentError, fn -> A.symbol_create_number(s, 2, args) end
      assert text(s, value) == "f(1)"
    end)
  end

  test "const callback arrays cannot be changed while output arguments remain writable" do
    Clingo.with_session(fn s ->
      callback =
        Clingo.callback(s, "clingo_symbol_callback_t", fn args, size, _ ->
          assert size == 1
          assert_raise ArgumentError, fn -> Clingo.write(s, args, symbol(s, "2")) end
          true
        end)

      args = Clingo.array(s, "clingo_symbol_t", [symbol(s, "1")])
      assert Clingo.call_pointer(s, callback, [args, 1, nil])
      assert text(s, Clingo.read(s, args)) == "1"
      Clingo.write(s, args, symbol(s, "3"))
      assert text(s, Clingo.read(s, args)) == "3"
    end)
  end

  test "waiting calls leave dirty schedulers available for an independent session" do
    Clingo.with_session(fn s ->
      Clingo.with_session(fn other ->
        owner = self()

        callback =
          Clingo.callback(s, "clingo_default_model_printer_t", fn _ ->
            send(owner, {:entered, self()})

            receive do
              :continue -> true
            end
          end)

        active = Task.async(fn -> Clingo.call_pointer(s, callback, [nil]) end)
        assert_receive {:entered, worker}
        waiting = for _ <- 1..8, do: Task.async(fn -> Clingo.alloc(s, "int") end)

        try do
          eventually = fn recur ->
            if :queue.len(:sys.get_state(s.dispatcher).queue) == length(waiting),
              do: :ok,
              else: recur.(recur)
          end

          eventually.(eventually)
          independent = Task.async(fn -> Clingo.alloc(other, "int") end)
          assert is_reference(Task.await(independent, 1_000))
        after
          send(worker, :continue)
        end

        assert Task.await(active) == true
        for task <- waiting, do: assert(is_reference(Task.await(task)))
      end)
    end)
  end
end
