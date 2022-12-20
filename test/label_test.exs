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
             align: :left,
             scale: 1,
             font: 0
           }

    # default render
    label(text: "T")
    |> render()
    |> assert_color("T", 0, @tc_normal)

    # excess text
    label(text: "Title", size: {3, 1})
    |> render()
    |> assert_color("Tit", 0, @tc_normal)
    |> align(:right)
    |> render()
    |> assert_color("tle", 0, @tc_normal)
    |> align(:center)
    |> render()
    |> assert_color("itl", 0, @tc_normal)

    # align text
    label(text: "Title", size: {7, 1})
    |> render()
    |> assert_color("Title  ", 0, @tc_normal)
    |> align(:right)
    |> render()
    |> assert_color("  Title", 0, @tc_normal)
    |> align(:center)
    |> render()
    |> assert_color(" Title ", 0, @tc_normal)

    label(text: "Title", size: {6, 1})
    |> align(:center)
    |> render()
    |> assert_color("Title ", 0, @tc_normal)

    # vertically center
    label(text: "T", size: {1, 3})
    |> render()
    |> assert_color(" ", 0, @tc_normal)
    |> assert_color("T", 1, @tc_normal)
    |> assert_color(" ", 2, @tc_normal)

    label(text: "T", size: {1, 2})
    |> render()
    |> assert_color("T", 0, @tc_normal)
    |> assert_color(" ", 1, @tc_normal)

    # unicode
    label(text: "Tĩtlĕ")
    |> render()
    |> assert_color("Tĩtlĕ", 0, @tc_normal)

    label(text: "Tĩtlĕ", size: {3, 1})
    |> render()
    |> assert_color("Tĩt", 0, @tc_normal)

    # scale
    label(text: "T", scale: 2)
    |> render()
    |> assert_color("TT", 0, @tc_normal)
    |> assert_color("TT", 1, @tc_normal)

    label(text: "TA", scale: 2)
    |> render()
    |> assert_color("TTAA", 0, @tc_normal)
    |> assert_color("TTAA", 1, @tc_normal)

    label(text: "T", scale: 2, size: {4, 4})
    |> render()
    |> assert_color("    ", 0, @tc_normal)
    |> assert_color("TT  ", 1, @tc_normal)
    |> assert_color("TT  ", 2, @tc_normal)
    |> assert_color("    ", 3, @tc_normal)
    |> align(:right)
    |> render()
    |> assert_color("    ", 0, @tc_normal)
    |> assert_color("  TT", 1, @tc_normal)
    |> assert_color("  TT", 2, @tc_normal)
    |> assert_color("    ", 3, @tc_normal)
    |> align(:center)
    |> render()
    |> assert_color("    ", 0, @tc_normal)
    |> assert_color(" TT ", 1, @tc_normal)
    |> assert_color(" TT ", 2, @tc_normal)
    |> assert_color("    ", 3, @tc_normal)

    # scale rendering
    label(text: "T", scale: 2)
    |> render()
    |> assert_color("TT", 0, @tc_normal)
    |> assert_color("TT", 1, @tc_normal)
    |> assert_diff([
      {:f, 17},
      {:b, 18},
      {:e, {2, 0, 0}},
      {:d, 'T'},
      {:e, {2, 1, 0}},
      {:d, 'T'},
      {:x, 0},
      {:y, 1},
      {:e, {2, 0, 1}},
      {:d, 'T'},
      {:e, {2, 1, 1}},
      {:d, 'T'}
    ])

    # opaque false for no background
    panel(root: true, size: {1, 1})
    |> save(:main)
    |> label(text: "1", class: %{back: @green})
    |> save(:f1)
    |> label(text: "2", class: %{back: nil})
    |> save(:f2)
    |> restore(:main)
    |> children([:f1])
    |> render()
    |> assert_color("1", 0, {@tcf_normal, @green})
    |> children([:f2])
    |> render()
    |> assert_color("2", 0, {@tcf_normal, @tcb_focused})
    |> children([:f1, :f2])
    |> render()
    |> assert_color("2", 0, {@tcf_normal, @green})

    # scale restored
    panel(root: true, size: {3, 2})
    |> save(:main)
    |> label(text: "2", scale: 2)
    |> save(:f2)
    |> label(text: "1", origin: {2, 0})
    |> save(:f1)
    |> restore(:main)
    |> children([:f2, :f1])
    |> render()
    |> assert_color("22", 0, @tc_normal)
    |> assert_color("22", 1, @tc_normal)
    |> assert_color("1", 2, 0, @tc_normal)
    |> assert_color(" ", 2, 1, @tc_focused)
    |> assert_diff([
      {:f, 17},
      {:b, 18},
      {:e, {2, 0, 0}},
      {:d, '2'},
      {:e, {2, 1, 0}},
      {:d, '2'},
      {:e, {1, 0, 0}},
      {:d, '1'},
      {:x, 0},
      {:y, 1},
      {:e, {2, 0, 1}},
      {:d, '2'},
      {:e, {2, 1, 1}},
      {:d, '2'},
      {:f, 19},
      {:b, 20},
      {:e, {1, 0, 0}},
      {:d, ' '},
      {:y, 0},
      {:f, 17},
      {:b, 18}
    ])
  end
end
