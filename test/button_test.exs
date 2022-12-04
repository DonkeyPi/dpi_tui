defmodule ButtonTest do
  use ExUnit.Case
  use ControlTest

  test "basic button check" do
    control_test(Button, input?: true, button?: true)

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

    # update
    on_click = fn -> :click end
    assert Button.update(initial, focused: :any) == initial
    assert Button.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}
    assert Button.update(initial, size: {2, 3}) == %{initial | size: {2, 3}}
    assert Button.update(initial, visible: false) == %{initial | visible: false}
    assert Button.update(initial, enabled: false) == %{initial | enabled: false}
    assert Button.update(initial, findex: -1) == %{initial | findex: -1}
    assert Button.update(initial, theme: :theme) == %{initial | theme: :theme}
    assert Button.update(initial, text: "text") == %{initial | text: "text"}
    assert Button.update(initial, shortcut: :esc) == %{initial | shortcut: :esc}
    assert Button.update(initial, on_click: on_click) == %{initial | on_click: on_click}
    assert Button.update(initial, on_click: nil) == initial

    # navigation
    assert Button.handle(%{}, %{type: :key, key: :tab}) == {%{}, {:focus, :next}}
    assert Button.handle(%{}, %{type: :key, key: :kdown}) == {%{}, {:focus, :next}}
    assert Button.handle(%{}, %{type: :key, key: :kright}) == {%{}, {:focus, :next}}
    assert Button.handle(%{}, %{type: :key, key: :tab, flag: @rtab}) == {%{}, {:focus, :prev}}
    assert Button.handle(%{}, %{type: :key, key: :kup}) == {%{}, {:focus, :prev}}
    assert Button.handle(%{}, %{type: :key, key: :kleft}) == {%{}, {:focus, :prev}}

    # triggers
    assert Button.handle(%{on_click: on_click}, %{type: :key, key: :enter}) ==
             {%{on_click: on_click}, {:click, :click}}

    assert Button.handle(%{on_click: on_click}, %{type: :key, key: ' '}) ==
             {%{on_click: on_click}, {:click, :click}}

    assert Button.handle(%{on_click: on_click}, %{type: :mouse, action: :press}) ==
             {%{on_click: on_click}, {:click, :click}}

    assert Button.handle(%{on_click: on_click, shortcut: :shortcut}, {:shortcut, :shortcut}) ==
             {%{on_click: on_click, shortcut: :shortcut}, {:click, :click}}

    # nops
    assert Button.handle(%{}, :any) == {%{}, nil}
  end
end
