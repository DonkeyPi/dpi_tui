defmodule Ash.FrameTest do
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
    |> check("┌┐", 0, @tc_normal)
    |> check("└┘", 1, @tc_normal)
    |> size({3, 3})
    |> render()
    |> check("┌─┐", 0, @tc_normal)
    |> check("│ │", 1, @tc_normal)
    |> check("└─┘", 2, @tc_normal)

    # excess text
    frame(text: "Title", size: {2, 2})
    |> render()
    |> check("┌┐", 0, @tc_normal)
    |> check("└┘", 1, @tc_normal)
    |> size({5, 3})
    |> render()
    |> check("┌Tit┐", 0, @tc_normal)
    |> check("│   │", 1, @tc_normal)
    |> check("└───┘", 2, @tc_normal)

    # double border
    frame(size: {3, 3}, border: :double)
    |> render()
    |> check("╔═╗", 0, @tc_normal)
    |> check("║ ║", 1, @tc_normal)
    |> check("╚═╝", 2, @tc_normal)

    # unicode
    frame(text: "Tĩtlĕ")
    |> render()
    |> check("┌Tĩtlĕ┐", 0, @tc_normal)
    |> check("└─────┘", 1, @tc_normal)

    frame(text: "Tĩtlĕ", size: {5, 2})
    |> render()
    |> check("┌Tĩt┐", 0, @tc_normal)
    |> check("└───┘", 1, @tc_normal)
  end
end
