defmodule Ash.CanvasTest do
  use ExUnit.Case
  use TestMacros

  test "basic canvas check" do
    # Root panel draws with focused style.
    # Rendering end with the top control,
    # the label in this case, so it end at
    # {1, 0} with normal colors.
    panel(root: true, size: {2, 2})
    |> save(:main)
    |> label(text: "L")
    |> save(:hello)
    |> restore(:main)
    |> children([:hello])
    |> render()
    |> check([
      {:f, @tcf_normal},
      {:b, @tcb_normal},
      {:d, 'L'},
      {:f, @tcf_focused},
      {:b, @tcb_focused},
      {:d, ' '},
      {:x, 0},
      {:y, 1},
      {:d, '  '},
      {:x, 1},
      {:y, 0},
      {:f, @tcf_normal},
      {:b, @tcb_normal}
    ])
  end
end
