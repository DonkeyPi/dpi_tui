defmodule Ash.ButtonTest do
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
    |> check("[T]", 0, @tc_normal)
    |> focused(true)
    |> render()
    |> check("[T]", 0, @tc_focused)
    |> enabled(false)
    |> render()
    |> check("[T]", 0, @tc_disabled)

    # text is horizontally centered
    button(text: "T", size: {5, 1})
    |> render()
    |> check("[ T ]", 0, @tc_normal)

    # text is vertically centered
    button(text: "T", size: {3, 3})
    |> render()
    |> check("   ", 0, @tc_normal)
    |> check("[T]", 1, @tc_normal)
    |> check("   ", 2, @tc_normal)

    button(text: "T", size: {3, 2})
    |> render()
    |> check("[T]", 0, @tc_normal)
    |> check("   ", 1, @tc_normal)

    # text is fully centered
    button(text: "T", size: {5, 3})
    |> render()
    |> check("     ", 0, @tc_normal)
    |> check("[ T ]", 1, @tc_normal)
    |> check("     ", 2, @tc_normal)

    # excess text
    button(text: "Title", size: {5, 1})
    |> render()
    |> check("[Tit]", 0, @tc_normal)

    # unicode
    button(text: "Tĩtlĕ")
    |> render()
    |> check("[Tĩtlĕ]", 0, @tc_normal)

    button(text: "Tĩtlĕ", size: {5, 1})
    |> render()
    |> check("[Tĩt]", 0, @tc_normal)

    # triggers
    button(text: "T")
    |> handle(@ev_kp_trigger, {:click, :nop})
    |> render()
    |> check("[T]", 0, @tc_normal)
    |> handle(@ev_mp_left, {:click, :nop})
    |> render()
    |> check("[T]", 0, @tc_normal)
    |> handle(@ev_kp_space, {:click, :nop})
    |> render()
    |> check("[T]", 0, @tc_normal)
  end
end
