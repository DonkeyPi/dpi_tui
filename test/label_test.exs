defmodule LabelTest do
  use ExUnit.Case
  use ControlTest

  test "basic label check" do
    ControlTest.common_checks(Label)

    initial = Label.init()

    # defaults
    assert initial == %{
             origin: {0, 0},
             size: {0, 1},
             visible: true,
             class: nil,
             text: ""
           }
  end
end
