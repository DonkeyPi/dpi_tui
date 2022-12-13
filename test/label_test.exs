defmodule Ash.LabelTest do
  use ExUnit.Case
  use TestMacros

  # Labels have no complex editable state.
  test "basic label check" do
    initial = Label.init()

    # defaults
    assert initial == %{
             origin: {0, 0},
             size: {0, 1},
             visible: true,
             class: nil,
             text: "",
             align: :left
           }
  end

  # default render
  label(text: "T")
  |> render()
  |> assert("T", 0, @tc_normal)

  # excess text
  label(text: "Title", size: {3, 1})
  |> render()
  |> assert("Tit", 0, @tc_normal)
  |> align(:right)
  |> render()
  |> assert("Tit", 0, @tc_normal)
  |> align(:center)
  |> render()
  |> assert("Tit", 0, @tc_normal)

  # align text
  label(text: "Title", size: {7, 1})
  |> render()
  |> assert("Title  ", 0, @tc_normal)
  |> align(:right)
  |> render()
  |> assert("  Title", 0, @tc_normal)
  |> align(:center)
  |> render()
  |> assert(" Title ", 0, @tc_normal)

  label(text: "Title", size: {6, 1})
  |> align(:center)
  |> render()
  |> assert("Title ", 0, @tc_normal)

  # vertically center
  label(text: "T", size: {1, 3})
  |> render()
  |> assert(" ", 0, @tc_normal)
  |> assert("T", 1, @tc_normal)
  |> assert(" ", 2, @tc_normal)

  label(text: "T", size: {1, 2})
  |> render()
  |> assert("T", 0, @tc_normal)
  |> assert(" ", 1, @tc_normal)

  # unicode
  label(text: "Tĩtlĕ")
  |> render()
  |> assert("Tĩtlĕ", 0, @tc_normal)

  label(text: "Tĩtlĕ", size: {3, 1})
  |> render()
  |> assert("Tĩt", 0, @tc_normal)
end
