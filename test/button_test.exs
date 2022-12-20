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
             size: {0, 1},
             visible: true,
             enabled: true,
             findex: 0,
             class: nil,
             text: "",
             border: nil,
             shortcut: nil,
             on_click: &Button.nop/0
           }

    # triggers: left click, space, ctrl+enter
    model = %{on_click: &Button.nop/0, enabled: true}
    assert Button.handle(model, @ev_kp_enter) == {model, {:click, :nop}}
    assert Button.handle(model, @ev_kp_space) == {model, {:click, :nop}}
    assert Button.handle(model, @ev_kp_trigger) == {model, {:click, :nop}}
    assert Button.handle(model, ev_mp_left(0, 0)) == {model, {:click, :nop}}

    # trigger restricted to focusables by panel
    panel(root: true, size: {1, 1})
    |> children(button: Control.init(Button, size: {1, 1}))
    |> handle(@ev_kp_space, {:button, {:click, :nop}})
    |> handle(@ev_kp_trigger, {:button, {:click, :nop}})
    |> handle(ev_mp_left(0, 0), {:button, {:click, :nop}})
    |> children(button: Control.init(Button, size: {1, 1}, enabled: false))
    |> handle(@ev_kp_space, nil)
    |> children(button: Control.init(Button, size: {1, 1}, visible: false))
    |> handle(@ev_kp_space, nil)
    |> children(button: Control.init(Button, size: {1, 1}, enabled: false))
    |> handle(@ev_kp_trigger, nil)
    |> children(button: Control.init(Button, size: {1, 1}, visible: false))
    |> handle(@ev_kp_trigger, nil)
    |> children(button: Control.init(Button, size: {1, 1}, enabled: false))
    |> handle(ev_mp_left(0, 0), nil)
    |> children(button: Control.init(Button, size: {1, 1}, visible: false))
    |> handle(ev_mp_left(0, 0), nil)

    # colors properly applied for each state
    button(text: "T")
    |> render()
    |> assert_color("T", 0, @tc_normal)
    |> focused(true)
    |> render()
    |> assert_color("T", 0, @tc_focused)
    |> enabled(false)
    |> render()
    |> assert_color("T", 0, @tc_disabled)

    # text is horizontally centered
    button(text: "T", size: {3, 1})
    |> render()
    |> assert_color(" T ", 0, @tc_normal)

    # text is vertically centered
    button(text: "T", size: {3, 3}, border: :round)
    |> render()
    |> assert_color("╭─╮", 0, @tc_normal)
    |> assert_color("│T│", 1, @tc_normal)
    |> assert_color("╰─╯", 2, @tc_normal)

    button(text: "T", size: {3, 2})
    |> render()
    |> assert_color(" T ", 0, @tc_normal)
    |> assert_color("   ", 1, @tc_normal)

    # text is fully centered
    button(text: "T", size: {5, 3}, border: :round)
    |> render()
    |> assert_color("╭───╮", 0, @tc_normal)
    |> assert_color("│ T │", 1, @tc_normal)
    |> assert_color("╰───╯", 2, @tc_normal)

    # excess text
    button(text: "Title", size: {3, 1})
    |> render()
    |> assert_color("itl", 0, @tc_normal)

    # unicode
    button(text: "Tĩtlĕ")
    |> render()
    |> assert_color("Tĩtlĕ", 0, @tc_normal)

    button(text: "Tĩtlĕ", size: {3, 1})
    |> render()
    |> assert_color("ĩtl", 0, @tc_normal)

    # triggers
    button(text: "T")
    |> handle(@ev_kp_trigger, {:click, :nop})
    |> render()
    |> assert_color("T", 0, @tc_normal)
    |> handle(@ev_mp_left, {:click, :nop})
    |> render()
    |> assert_color("T", 0, @tc_normal)
    |> handle(@ev_kp_space, {:click, :nop})
    |> render()
    |> assert_color("T", 0, @tc_normal)
  end
end
