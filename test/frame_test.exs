defmodule FrameTest do
  use ExUnit.Case
  use Ash.Tui.Aliases
  use Ash.Tui.Events

  # Frames are simple controls in that they have no complex editable state.
  test "basic frame check" do
    initial = Frame.init()

    # defaults
    assert initial == %{
             origin: {0, 0},
             size: {0, 0},
             visible: true,
             class: nil,
             bracket: false,
             style: :single,
             text: ""
           }
  end
end
