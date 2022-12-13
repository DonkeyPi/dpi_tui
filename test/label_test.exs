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
  |> check("T", 0, @tc_normal)

  # excess text
  label(text: "Title", size: {3, 1})
  |> render()
  |> check("Tit", 0, @tc_normal)
  |> align(:right)
  |> render()
  |> check("Tit", 0, @tc_normal)
  |> align(:center)
  |> render()
  |> check("Tit", 0, @tc_normal)

  # align text
  label(text: "Title", size: {7, 1})
  |> render()
  |> check("Title  ", 0, @tc_normal)
  |> align(:right)
  |> render()
  |> check("  Title", 0, @tc_normal)
  |> align(:center)
  |> render()
  |> check(" Title ", 0, @tc_normal)

  label(text: "Title", size: {6, 1})
  |> align(:center)
  |> render()
  |> check("Title ", 0, @tc_normal)

  # vertically center
  label(text: "T", size: {1, 3})
  |> render()
  |> check(" ", 0, @tc_normal)
  |> check("T", 1, @tc_normal)
  |> check(" ", 2, @tc_normal)

  label(text: "T", size: {1, 2})
  |> render()
  |> check("T", 0, @tc_normal)
  |> check(" ", 1, @tc_normal)

  # unicode
  label(text: "Tĩtlĕ")
  |> render()
  |> check("Tĩtlĕ", 0, @tc_normal)

  label(text: "Tĩtlĕ", size: {3, 1})
  |> render()
  |> check("Tĩt", 0, @tc_normal)
end
