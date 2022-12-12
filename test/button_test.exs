defmodule ButtonTest do
  use ExUnit.Case
  use Ash.Tui.Aliases
  use Ash.Tui.Events
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

    # triggers
    model = %{on_click: &Button.nop/0}
    assert Button.handle(model, @ev_kp_trigger) == {model, {:click, :nop}}
    assert Button.handle(model, @ev_mp_left) == {model, {:click, :nop}}

    # colors properly applied for each state
    button(text: "B", origin: {1, 1})
    |> render(5, 3)
    |> assert("[B]", 1, 1, @bf_normal, @bb_normal)
    |> focused(true)
    |> render(5, 3)
    |> assert("[B]", 1, 1, @bf_focused, @bb_focused)
    |> enabled(false)
    |> render(5, 3)
    |> assert("[B]", 1, 1, @bf_disabled, @bb_disabled)

    # text is horizontally centered
    button(text: "B", origin: {1, 1}, size: {5, 1})
    |> render(7, 3)
    |> assert("[ B ]", 1, 1, @bf_normal, @bb_normal)

    # text is vertically centered
    button(text: "B", origin: {1, 1}, size: {3, 3})
    |> render(5, 5)
    |> assert("   ", 1, 1, @bf_normal, @bb_normal)
    |> assert("[B]", 1, 2, @bf_normal, @bb_normal)
    |> assert("   ", 1, 3, @bf_normal, @bb_normal)

    # text is fully centered
    button(text: "B", origin: {1, 1}, size: {5, 3})
    |> render(7, 5)
    |> assert("     ", 1, 1, @bf_normal, @bb_normal)
    |> assert("[ B ]", 1, 2, @bf_normal, @bb_normal)
    |> assert("     ", 1, 3, @bf_normal, @bb_normal)
  end
end
