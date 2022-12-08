defmodule ButtonTest do
  use ExUnit.Case
  use ControlTest

  test "basic button check" do
    ControlTest.common_checks(Button, input?: true, button?: true)

    initial = Button.init()

    # defaults
    assert initial == %{
             focused: false,
             origin: {0, 0},
             size: {2, 1},
             visible: true,
             enabled: true,
             findex: 0,
             theme: :default,
             text: "",
             shortcut: nil,
             on_click: &Button.nop/0
           }
  end
end
