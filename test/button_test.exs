defmodule ButtonTest do
  use ExUnit.Case
  use TestMacros

  # Buttons have no complex editable state.
  test "basic button check" do
    initial = Button.init()

    # defaults
    assert initial == %{
             focused: false,
             origin: {0, 0},
             size: {2, 1},
             visible: true,
             enabled: true,
             findex: 0,
             class: nil,
             text: "",
             shortcut: nil,
             on_click: &Button.nop/0
           }

    # triggers: left click, space, ctrl+enter
    model = %{on_click: &Button.nop/0}
    assert Button.handle(model, @ev_kp_space) == {model, {:click, :nop}}
    assert Button.handle(model, @ev_kp_trigger) == {model, {:click, :nop}}
    assert Button.handle(model, @ev_mp_left) == {model, {:click, :nop}}

    # colors properly applied for each state
    button(text: "T", origin: {1, 1})
    |> render(5, 3)
    |> assert("[T]", 1, 1, @tcf_normal, @tcb_normal)
    |> focused(true)
    |> render(5, 3)
    |> assert("[T]", 1, 1, @tcf_focused, @tcb_focused)
    |> enabled(false)
    |> render(5, 3)
    |> assert("[T]", 1, 1, @tcf_disabled, @tcb_disabled)

    # text is horizontally centered
    button(text: "T", origin: {1, 1}, size: {5, 1})
    |> render(7, 3)
    |> assert("[ T ]", 1, 1, @tcf_normal, @tcb_normal)

    # text is vertically centered
    button(text: "T", origin: {1, 1}, size: {3, 3})
    |> render(5, 5)
    |> assert("   ", 1, 1, @tcf_normal, @tcb_normal)
    |> assert("[T]", 1, 2, @tcf_normal, @tcb_normal)
    |> assert("   ", 1, 3, @tcf_normal, @tcb_normal)

    # text is fully centered
    button(text: "T", origin: {1, 1}, size: {5, 3})
    |> render(7, 5)
    |> assert("     ", 1, 1, @tcf_normal, @tcb_normal)
    |> assert("[ T ]", 1, 2, @tcf_normal, @tcb_normal)
    |> assert("     ", 1, 3, @tcf_normal, @tcb_normal)
  end
end
