defmodule Clingo.TypedCallbacksTest do
  use ExUnit.Case, async: true
  import Clingo.TestSupport
  alias Clingo.TestSupport.Raw, as: A

  test "shared observer structs preserve registration userdata and same-signature fields" do
    Clingo.with_session(fn s ->
      parent = self()

      hook = fn event ->
        Clingo.callback(s, "bool(*)(void*)", fn data ->
          send(parent, {event, Clingo.read(s, Clingo.cast(s, data, "int"))})
          true
        end)
      end

      observer =
        struct(s, "clingo_ground_program_observer_t", %{
          begin_step: hook.(:begin),
          end_step: hook.(:end)
        })

      a = control(s)
      b = control(s)
      assert A.control_register_observer(s, a, observer, false, Clingo.array(s, "int", [11]))
      assert A.control_register_observer(s, b, observer, false, Clingo.array(s, "int", [22]))
      ground(s, a, "a.")
      ground(s, b, "b.")
      assert models(s, handle(s, a)) == [["a"]]
      assert models(s, handle(s, b)) == [["b"]]
      assert_receive {:begin, 11}
      assert_receive {:end, 11}
      assert_receive {:begin, 22}
      assert_receive {:end, 22}
    end)
  end
end
