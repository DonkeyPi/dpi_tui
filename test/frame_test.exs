defmodule FrameTest do
  use ExUnit.Case
  use TestMacros

  # Frames have no complex editable state.
  test "basic frame check" do
    initial = Frame.init()

    # defaults
    assert initial == %{
             origin: {0, 0},
             size: {2, 2},
             visible: true,
             class: nil,
             border: :single,
             text: ""
           }

    # default rendering
    frame(origin: {1, 1})
    |> render(4, 4)
    |> assert("┌┐", 1, 1, @tcf_normal, @tcb_normal)
    |> assert("└┘", 1, 2, @tcf_normal, @tcb_normal)
    |> size({3, 3})
    |> render(5, 5)
    |> assert("┌─┐", 1, 1, @tcf_normal, @tcb_normal)
    |> assert("│ │", 1, 2, @tcf_normal, @tcb_normal)
    |> assert("└─┘", 1, 3, @tcf_normal, @tcb_normal)

    # excess text
    frame(origin: {1, 1}, text: "Title")
    |> render(4, 4)
    |> assert("┌┐", 1, 1, @tcf_normal, @tcb_normal)
    |> assert("└┘", 1, 2, @tcf_normal, @tcb_normal)
    |> size({5, 3})
    |> render(7, 5)
    |> assert("┌Tit┐", 1, 1, @tcf_normal, @tcb_normal)
    |> assert("│   │", 1, 2, @tcf_normal, @tcb_normal)
    |> assert("└───┘", 1, 3, @tcf_normal, @tcb_normal)

    # double border
    frame(origin: {1, 1}, size: {3, 3}, border: :double)
    |> render(5, 5)
    |> assert("╔═╗", 1, 1, @tcf_normal, @tcb_normal)
    |> assert("║ ║", 1, 2, @tcf_normal, @tcb_normal)
    |> assert("╚═╝", 1, 3, @tcf_normal, @tcb_normal)
  end
end
