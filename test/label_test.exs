defmodule LabelTest do
  use ExUnit.Case
  use ControlTest

  test "basic label check" do
    ControlTest.common_checks(Label)

    theme = Theme.get(:default)

    initial = Label.init()

    # defaults
    assert initial == %{
             origin: {0, 0},
             size: {0, 1},
             visible: true,
             text: "",
             back: theme.back_readonly,
             fore: theme.fore_readonly
           }
  end
end
