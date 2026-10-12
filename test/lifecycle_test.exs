defmodule Clingo.LifecycleTest do
  use ExUnit.Case, async: true
  import Clingo.TestSupport
  alias Clingo.TestSupport.Raw, as: A
  import Bitwise

  test "release controls, close sessions, reject foreign and expired resources" do
    s = Clingo.open()
    c = control(s)
    atoms = out(s, :control_symbolic_atoms, [c], "clingo_symbolic_atoms_t*")
    assert A.control_free(s, c) == :ok
    assert_raise ArgumentError, fn -> A.control_is_conflicting(s, c) end
    assert_raise ArgumentError, fn -> out(s, :symbolic_atoms_size, [atoms], "size_t") end
    p = Clingo.alloc(s, "int", 2)
    assert Clingo.write(s, p, -2, 1) == :ok
    assert Clingo.read(s, p, 1) == -2
    assert_raise ArgumentError, fn -> Clingo.read(s, p, 2) end
    assert_raise ArgumentError, fn -> Clingo.write(s, p, 1 <<< 40) end

    Clingo.with_session(fn other ->
      assert_raise ArgumentError, fn -> Clingo.read(other, p) end
    end)

    assert Clingo.close(s) == :ok
    assert_raise ArgumentError, fn -> Clingo.read(s, p) end
    assert Clingo.close(s) == :ok
  end

  import Bitwise

  test "async solve wait and cancellation preserve incomplete result bits" do
    Clingo.with_session(fn s ->
      c = ground(s, control(s), "{a(1..24)}.")
      h = out(s, :control_solve, [c, 3, nil, 0, nil, nil], "clingo_solve_handle_t*")
      assert A.solve_handle_resume(s, h)
      ready = Clingo.alloc(s, "bool")
      assert A.solve_handle_wait(s, h, 10.0, ready) == :ok
      assert Clingo.read(s, ready)
      assert A.solve_handle_cancel(s, h)
      result = out(s, :solve_handle_get, [h], "clingo_solve_result_bitset_t")
      assert (result &&& 8) == 8
      assert (result &&& 4) == 0
    end)
  end

  test "another BEAM process interrupts a long solve without blocking normal schedulers" do
    Clingo.with_session(fn s ->
      c = ground(s, control(s), "{a(1..28)}.")

      task =
        Task.async(fn ->
          h = out(s, :control_solve, [c, 0, nil, 0, nil, nil], "clingo_solve_handle_t*")
          out(s, :solve_handle_get, [h], "clingo_solve_result_bitset_t")
        end)

      Process.sleep(20)
      assert Clingo.interrupt(c) == :ok
      result = Task.await(task, 5_000)
      assert (result &&& 8) == 8
      assert (result &&& 4) == 0
      assert A.control_interrupt(s, c) == :ok
    end)
  end

  test "file loading, aspif loading and reification" do
    Clingo.with_session(fn s ->
      file = Path.join(System.tmp_dir!(), "clingo-load-#{System.unique_integer([:positive])}.lp")
      aspif = file <> ".aspif"
      reify = file <> ".reify"
      File.write!(file, "a.")
      File.write!(aspif, "asp 1 0 0\n1 0 1 1 0 0\n4 1 a 0\n0\n")

      try do
        c = control(s)
        assert A.control_load(s, c, file)
        assert A.control_register_backend(s, c, 0, reify, false)
        parts = Clingo.array(s, "clingo_part_t", [%{name: "base", params: nil, size: 0}])
        assert A.control_ground(s, c, parts, 1, nil, nil)
        assert models(s, handle(s, c)) == [["a"]]
        c = control(s)
        assert A.control_load_aspif(s, c, Clingo.array(s, "char*", [aspif]), 1)
        assert models(s, handle(s, c)) == [["a"]]
      after
        Enum.each([file, aspif, reify], &File.rm/1)
      end
    end)
  end
end

defmodule Clingo.NoResultTest do
  use ExUnit.Case, async: true
  import Clingo.TestSupport
  alias Clingo.TestSupport.Raw, as: A
  import Bitwise

  test "interruption before any model has no satisfiability conclusion" do
    Clingo.with_session(fn s ->
      c = ground(s, control(s), "1 {in(P,H):H=1..20} 1 :- P=1..21. :- in(P,H), in(Q,H), P<Q.")
      h = out(s, :control_solve, [c, 1, nil, 0, nil, nil], "clingo_solve_handle_t*")
      ready = Clingo.alloc(s, "bool")
      assert A.solve_handle_wait(s, h, 0.0, ready) == :ok
      refute Clingo.read(s, ready)
      assert A.solve_handle_cancel(s, h)
      result = out(s, :solve_handle_get, [h], "clingo_solve_result_bitset_t")
      assert (result &&& 3) == 0
      assert (result &&& 4) == 0
      assert (result &&& 8) == 8
      assert out(s, :solve_handle_model, [h], "clingo_model_t*") == nil
    end)
  end
end
