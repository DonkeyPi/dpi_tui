defmodule ButtonTest do
  use ExUnit.Case
  use Ash.Tui.Aliases
  use Ash.Tui.Events

  # Buttons are simple controls in that they have no complex editable state.
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
  end
end
