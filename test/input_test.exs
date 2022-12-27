defmodule Ash.InputTest do
  use ExUnit.Case
  use TestMacros

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
             selected: false,
             on_change: &Input.nop/1,
             validate: &Input.validate/1
           }

    Buffer.start()

    on_change = fn value ->
      Buffer.add("#{value}")
      value
    end

    Input.init(on_change: on_change, text: "text")
    assert Buffer.get() == "text"
    Buffer.start()

    model = Input.init(on_change: on_change, text: "")
    assert Buffer.get() == ""
    Buffer.start()

    model = Input.update(model, text: "text")
    assert Buffer.get() == "text"
    Buffer.start()

    Input.update(model, text: "text2")
    assert Buffer.get() == "text2"
    Buffer.start()

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

    # validation
    validate = fn text -> String.length(text) > 1 end
    assert Input.valid(%{initial | text: "a", validate: validate}) == false
    assert Input.valid(%{initial | text: "abc", validate: validate}) == true

    # colors properly applied for each state
    input(text: "T")
    |> render()
    |> assert_color("T", 0, @tc_normal)
    |> focused(true)
    |> selected(false)
    |> render()
    |> assert_color("T", 0, @tc_focused)
    |> enabled(false)
    |> render()
    |> assert_color("T", 0, @tc_disabled)

    input(size: {2, 1})
    |> enabled(false)
    |> render()
    |> assert_color("  ", 0, @tc_disabled)

    # password
    input(text: "T", size: {2, 1})
    |> password(true)
    |> render()
    |> assert_color("* ", 0, @tc_normal)

    # basic cursor
    input(text: "T", size: {2, 1})
    |> focused(true)
    |> render()
    |> assert_cursor("T ", 0, 1)

    input(text: "T")
    |> focused(true)
    |> render()
    |> assert_cursor("T", 0, false)

    input(text: "T", size: {2, 1})
    |> render()
    |> assert_cursor("T ", 0, false)

    # extra rows
    input(text: "T", size: {1, 2})
    |> render()
    |> assert_color("T", 0, @tc_normal)
    |> assert_color(" ", 1, @tc_normal)

    # text insertion
    state =
      input(size: {5, 1})
      |> focused(true)
      |> selected(false)
      |> render()
      |> assert_cursor("     ", 0, 0)
      |> handle(ev_kp_data('ṕ'), {:text, "ṕ", {:nop, "ṕ"}})
      |> render()
      |> assert_cursor("ṕ    ", 0, 1)
      |> handle(ev_kp_data('íe'), {:text, "ṕíe", {:nop, "ṕíe"}})
      |> render()
      |> assert_cursor("ṕíe  ", 0, 3)

    state
    |> handle(@ev_kp_backspace, {:text, "ṕí", {:nop, "ṕí"}})
    |> render()
    |> assert_cursor("ṕí   ", 0, 2)
    |> cursor(1)
    |> handle(@ev_kp_backspace, {:text, "í", {:nop, "í"}})
    |> render()
    |> assert_cursor("í   ", 0, 0)
    |> handle(@ev_kp_backspace, nil)
    |> render()
    |> assert_cursor("í   ", 0, 0)

    state
    |> handle(@ev_kp_delete, nil)
    |> render()
    |> assert_cursor("ṕíe  ", 0, 3)
    |> cursor(2)
    |> handle(@ev_kp_delete, {:text, "ṕí", {:nop, "ṕí"}})
    |> render()
    |> assert_cursor("ṕí   ", 0, 2)
    |> handle(@ev_kp_delete, nil)
    |> render()
    |> assert_cursor("ṕí   ", 0, 2)

    # cursor navigation
    state
    |> cursor(5)
    |> render()
    |> assert_cursor("ṕíe  ", 0, false)
    |> handle(@ev_kp_end, nil)
    |> render()
    |> assert_cursor("ṕíe  ", 0, 3)
    |> handle(@ev_kp_kleft, nil)
    |> render()
    |> assert_cursor("ṕíe  ", 0, 2)
    |> handle(@ev_kp_home, nil)
    |> render()
    |> assert_cursor("ṕíe  ", 0, 0)
    |> handle(@ev_kp_kright, nil)
    |> render()
    |> assert_cursor("ṕíe  ", 0, 1)
    |> handle(ev_mp_left(4, 0), nil)
    |> render()
    |> assert_cursor("ṕíe  ", 0, 3)
    |> handle(ev_mp_left(0, 0), nil)
    |> render()
    |> assert_cursor("ṕíe  ", 0, 0)

    # Cols limits text length at insertion only.
    # Initial and updated text can break the rule.
    # Text can be reduced at any time.
    # No scrolling implemented.
    input(text: "abcd", size: {2, 1})
    |> focused(true)
    |> render()
    |> assert_cursor("ab", 0, false)
    |> handle(@ev_kp_end, nil)
    |> render()
    |> assert_cursor("ab", 0, false)
    |> handle(@ev_kp_backspace, {:text, "abc", {:nop, "abc"}})
    |> render()
    |> assert_cursor("ab", 0, false)
    |> handle(@ev_kp_home, nil)
    |> render()
    |> assert_cursor("ab", 0, 0)
    |> handle(ev_kp_data('a'), nil)
    |> render()
    |> assert_cursor("ab", 0, 0)
    |> handle(@ev_kp_delete, {:text, "bc", {:nop, "bc"}})
    |> render()
    |> assert_cursor("bc", 0, 0)
    |> handle(ev_kp_data('a'), nil)
    |> render()
    |> assert_cursor("bc", 0, 0)
    |> cursor(1)
    |> handle(ev_kp_data('a'), nil)
    |> render()
    |> assert_cursor("bc", 0, 1)

    # triggers
    input(text: "T")
    |> render()
    |> assert_color("T", 0, @tc_normal)
    |> handle(@ev_kp_trigger, {:text, "T", {:nop, "T"}})
    |> render()
    |> assert_color("T", 0, @tc_normal)

    # invalid
    input(text: "T", validate: validate)
    |> render()
    |> assert_color("T", 0, @tc_invalid)
    |> update(text: "TTT", size: {3, 1})
    |> render()
    |> assert_color("TTT", 0, @tc_normal)

    # selection

    initial = Input.init(text: "text", cursor: 1, on_change: on_change)
    assert initial.selected == false
    assert initial.cursor == 1
    assert initial.text == "text"
    # on focus selected all
    model = Input.focused(initial, true)
    assert model.selected == true
    # shift + home selected all
    {model, _} = Input.handle(initial, @ev_kp_home_shift)
    assert model.selected == true
    assert model.cursor == 0
    # shift + end selected all
    {model, _} = Input.handle(initial, @ev_kp_end_shift)
    assert model.selected == true
    assert model.cursor == 4
    # double click select all
    {selected, _} = Input.handle(initial, @ev_ms_trigger2)
    assert selected.selected == true
    assert selected.cursor == 4
    # single click clears selection
    {model, _} = Input.handle(selected, ev_mp_left(0, 0))
    assert model.selected == false
    # left/right/home/end/data arrow clears selection
    {model, _} = Input.handle(selected, @ev_kp_kleft)
    assert model.selected == false
    {model, _} = Input.handle(selected, @ev_kp_kright)
    assert model.selected == false
    {model, _} = Input.handle(selected, @ev_kp_home)
    assert model.selected == false
    {model, _} = Input.handle(selected, @ev_kp_end)
    assert model.selected == false
    {model, _} = Input.handle(selected, ev_kp_data('a'))
    assert model.selected == false
    # delete/backspace/data replaces selection
    Buffer.start()
    {model, _} = Input.handle(selected, @ev_kp_backspace)
    assert model.selected == false
    assert model.cursor == 0
    assert model.text == ""
    assert Buffer.get() == ""
    Buffer.start()
    {model, _} = Input.handle(selected, @ev_kp_delete)
    assert model.selected == false
    assert model.cursor == 0
    assert model.text == ""
    assert Buffer.get() == ""
    Buffer.start()
    {model, _} = Input.handle(selected, ev_kp_data('a'))
    assert model.selected == false
    assert model.cursor == 1
    assert model.text == "a"
    assert Buffer.get() == "a"
    Buffer.start()
    {model, _} = Input.handle(selected, ev_kp_data('ab'))
    assert model.selected == false
    assert model.cursor == 2
    assert model.text == "ab"
    assert Buffer.get() == "ab"
    Buffer.start()
  end
end
