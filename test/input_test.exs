defmodule InputTest do
  use ExUnit.Case
  use Ash.Tui.Aliases
  use Ash.Tui.Events

  # Input complex state consists of text and cursor properties.
  test "basic input check" do
    initial = Input.init()

    # defaults
    assert initial == %{
             focused: false,
             origin: {0, 0},
             size: {0, 1},
             visible: true,
             enabled: true,
             findex: 0,
             class: nil,
             password: false,
             text: "",
             cursor: 0,
             on_change: &Input.nop/1
           }

    on_change = fn value -> value end

    # updates

    # cursor is recalculated on text update
    expected = %{initial | text: "text", cursor: 4}

    assert Input.update(initial, text: "text") == expected
    assert Input.update(initial, text: "text", cursor: 1) == expected
    assert Input.update(initial, cursor: 1, text: "text") == expected

    # triggers from text input
    model = Input.init(size: {10, 1}, on_change: on_change)

    # insert first char
    assert Input.handle(model, ev_kp_data('a')) ==
             {%{model | text: "a", cursor: 1}, {:text, "a", "a"}}

    # insert at the end
    assert Input.handle(%{model | text: "a", cursor: 1}, ev_kp_data('b')) ==
             {%{model | text: "ab", cursor: 2}, {:text, "ab", "ab"}}

    # insert at the beginning
    assert Input.handle(%{model | text: "a", cursor: 0}, ev_kp_data('b')) ==
             {%{model | text: "ba", cursor: 1}, {:text, "ba", "ba"}}

    # insert in the middle
    assert Input.handle(%{model | text: "ab", cursor: 1}, ev_kp_data('c')) ==
             {%{model | text: "acb", cursor: 2}, {:text, "acb", "acb"}}

    # delete second with delete
    assert Input.handle(%{model | text: "abc", cursor: 1}, @ev_kp_delete) ==
             {%{model | text: "ac", cursor: 1}, {:text, "ac", "ac"}}

    # delete first with backspace
    assert Input.handle(%{model | text: "abc", cursor: 1}, @ev_kp_backspace) ==
             {%{model | text: "bc", cursor: 0}, {:text, "bc", "bc"}}

    # retrigger
    assert Input.handle(%{model | text: "abc", cursor: 1}, @ev_kp_trigger) ==
             {%{model | text: "abc", cursor: 1}, {:text, "abc", "abc"}}

    # mouse

    # move cursor to beginning on click
    assert Input.handle(%{model | text: "abc", cursor: 2}, ev_mp_left(0, 0)) ==
             {%{model | text: "abc", cursor: 0}, nil}

    # move cursor to middle on click
    assert Input.handle(%{model | text: "abc"}, ev_mp_left(2, 0)) ==
             {%{model | text: "abc", cursor: 2}, nil}

    # move cursor to end on click
    assert Input.handle(%{model | text: "abc"}, ev_mp_left(4, 0)) ==
             {%{model | text: "abc", cursor: 3}, nil}

    # nops

    # ignore backspace when cursor at beginning
    assert Input.handle(%{initial | size: {10, 1}, text: "a"}, @ev_kp_backspace) ==
             {%{initial | size: {10, 1}, text: "a"}, nil}

    # ignore delete when cursor at end
    assert Input.handle(%{initial | size: {10, 1}, text: "a", cursor: 1}, @ev_kp_delete) ==
             {%{initial | size: {10, 1}, text: "a", cursor: 1}, nil}
  end
end
