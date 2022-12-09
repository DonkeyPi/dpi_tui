defmodule FrameTest do
  use ExUnit.Case
  use ControlTest

  test "basic frame check" do
    ControlTest.common_checks(Frame)

    theme = Theme.get(:default)

    initial = Frame.init()

    # defaults
    assert initial == %{
             origin: {0, 0},
             size: {0, 0},
             visible: true,
             bracket: false,
             style: :single,
             text: "",
             back: theme.back_readonly,
             fore: theme.fore_readonly
           }
  end
end
