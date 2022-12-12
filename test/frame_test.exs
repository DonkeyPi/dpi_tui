defmodule FrameTest do
  use ExUnit.Case
  use ControlTest

  test "basic frame check" do
    ControlTest.common_checks(Frame)

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
