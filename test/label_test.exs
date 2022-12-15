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
             factor: 1
           }

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
    |> check("tle", 0, @tc_normal)
    |> align(:center)
    |> render()
    |> check("itl", 0, @tc_normal)

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

    # factor
    label(text: "T", factor: 2)
    |> render()
    |> check("TT", 0, @tc_normal)
    |> check("TT", 1, @tc_normal)

    label(text: "TA", factor: 2)
    |> render()
    |> check("TTAA", 0, @tc_normal)
    |> check("TTAA", 1, @tc_normal)

    label(text: "T", factor: 2, size: {4, 4})
    |> render()
    |> check("    ", 0, @tc_normal)
    |> check("TT  ", 1, @tc_normal)
    |> check("TT  ", 2, @tc_normal)
    |> check("    ", 3, @tc_normal)
    |> align(:right)
    |> render()
    |> check("    ", 0, @tc_normal)
    |> check("  TT", 1, @tc_normal)
    |> check("  TT", 2, @tc_normal)
    |> check("    ", 3, @tc_normal)
    |> align(:center)
    |> render()
    |> check("    ", 0, @tc_normal)
    |> check(" TT ", 1, @tc_normal)
    |> check(" TT ", 2, @tc_normal)
    |> check("    ", 3, @tc_normal)

    # factor rendering
    label(text: "T", factor: 2)
    |> render()
    |> check("TT", 0, @tc_normal)
    |> check("TT", 1, @tc_normal)
    |> check([
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

    # factor restored
    panel(root: true, size: {3, 2})
    |> save(:main)
    |> label(text: "2", factor: 2)
    |> save(:f2)
    |> label(text: "1", origin: {2, 0})
    |> save(:f1)
    |> restore(:main)
    |> children([:f2, :f1])
    |> render()
    |> check("22", 0, @tc_normal)
    |> check("22", 1, @tc_normal)
    |> check("1", 2, 0, @tc_normal)
    |> check(" ", 2, 1, @tc_focused)
    |> check([
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
