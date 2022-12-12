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
    frame()
    |> render()
    |> assert("┌┐", 0, @tcf_normal, @tcb_normal)
    |> assert("└┘", 1, @tcf_normal, @tcb_normal)
    |> size({3, 3})
    |> render()
    |> assert("┌─┐", 0, @tcf_normal, @tcb_normal)
    |> assert("│ │", 1, @tcf_normal, @tcb_normal)
    |> assert("└─┘", 2, @tcf_normal, @tcb_normal)

    # excess text
    frame(text: "Title", size: {2, 2})
    |> render()
    |> assert("┌┐", 0, @tcf_normal, @tcb_normal)
    |> assert("└┘", 1, @tcf_normal, @tcb_normal)
    |> size({5, 3})
    |> render()
    |> assert("┌Tit┐", 0, @tcf_normal, @tcb_normal)
    |> assert("│   │", 1, @tcf_normal, @tcb_normal)
    |> assert("└───┘", 2, @tcf_normal, @tcb_normal)

    # double border
    frame(size: {3, 3}, border: :double)
    |> render()
    |> assert("╔═╗", 0, @tcf_normal, @tcb_normal)
    |> assert("║ ║", 1, @tcf_normal, @tcb_normal)
    |> assert("╚═╝", 2, @tcf_normal, @tcb_normal)

    # unicode
    frame(text: "Tĩtlĕ")
    |> render()
    |> assert("┌Tĩtlĕ┐", 0, @tcf_normal, @tcb_normal)
    |> assert("└─────┘", 1, @tcf_normal, @tcb_normal)

    frame(text: "Tĩtlĕ", size: {5, 2})
    |> render()
    |> assert("┌Tĩt┐", 0, @tcf_normal, @tcb_normal)
    |> assert("└───┘", 1, @tcf_normal, @tcb_normal)
  end
end
