defmodule LabelTest do
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
  label(origin: {1, 1}, text: "T")
  |> render(3, 3)
  |> assert("T", 1, 1, @tcf_normal, @tcb_normal)

  # excess text
  label(origin: {1, 1}, text: "Title", size: {3, 1})
  |> render(5, 3)
  |> assert("Tit", 1, 1, @tcf_normal, @tcb_normal)
  |> align(:right)
  |> render(5, 3)
  |> assert("Tit", 1, 1, @tcf_normal, @tcb_normal)
  |> align(:center)
  |> render(5, 3)
  |> assert("Tit", 1, 1, @tcf_normal, @tcb_normal)

  # align text
  label(origin: {1, 1}, text: "Title", size: {7, 1})
  |> render(9, 3)
  |> assert("Title  ", 1, 1, @tcf_normal, @tcb_normal)
  |> align(:right)
  |> render(9, 3)
  |> assert("  Title", 1, 1, @tcf_normal, @tcb_normal)
  |> align(:center)
  |> render(9, 3)
  |> assert(" Title ", 1, 1, @tcf_normal, @tcb_normal)

  label(origin: {1, 1}, text: "Title", size: {6, 1})
  |> align(:center)
  |> render(8, 3)
  |> assert("Title ", 1, 1, @tcf_normal, @tcb_normal)

  # vertically center
  label(origin: {1, 1}, text: "T", size: {1, 3})
  |> render(3, 5)
  |> assert(" ", 1, 1, @tcf_normal, @tcb_normal)
  |> assert("T", 1, 2, @tcf_normal, @tcb_normal)
  |> assert(" ", 1, 3, @tcf_normal, @tcb_normal)

  label(origin: {1, 1}, text: "T", size: {1, 2})
  |> render(3, 4)
  |> assert("T", 1, 1, @tcf_normal, @tcb_normal)
  |> assert(" ", 1, 2, @tcf_normal, @tcb_normal)
end
