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
    button(text: "T")
    |> render()
    |> assert("[T]", 0, @tcf_normal, @tcb_normal)
    |> focused(true)
    |> render()
    |> assert("[T]", 0, @tcf_focused, @tcb_focused)
    |> enabled(false)
    |> render()
    |> assert("[T]", 0, @tcf_disabled, @tcb_disabled)

    # text is horizontally centered
    button(text: "T", size: {5, 1})
    |> render()
    |> assert("[ T ]", 0, @tcf_normal, @tcb_normal)

    # text is vertically centered
    button(text: "T", size: {3, 3})
    |> render()
    |> assert("   ", 0, @tcf_normal, @tcb_normal)
    |> assert("[T]", 1, @tcf_normal, @tcb_normal)
    |> assert("   ", 2, @tcf_normal, @tcb_normal)

    button(text: "T", size: {3, 2})
    |> render()
    |> assert("[T]", 0, @tcf_normal, @tcb_normal)
    |> assert("   ", 1, @tcf_normal, @tcb_normal)

    # text is fully centered
    button(text: "T", size: {5, 3})
    |> render()
    |> assert("     ", 0, @tcf_normal, @tcb_normal)
    |> assert("[ T ]", 1, @tcf_normal, @tcb_normal)
    |> assert("     ", 2, @tcf_normal, @tcb_normal)

    # excess text
    button(text: "Title", size: {5, 1})
    |> render()
    |> assert("[Tit]", 0, @tcf_normal, @tcb_normal)

    # unicode
    button(text: "Tĩtlĕ")
    |> render()
    |> assert("[Tĩtlĕ]", 0, @tcf_normal, @tcb_normal)

    button(text: "Tĩtlĕ", size: {5, 1})
    |> render()
    |> assert("[Tĩt]", 0, @tcf_normal, @tcb_normal)
  end
end
