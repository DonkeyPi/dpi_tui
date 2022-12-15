defmodule Ash.CanvasTest do
  use ExUnit.Case
  use TestMacros

  test "basic canvas check" do
    # Root panel draws with focused style.
    # Rendering end with the top control,
    # the label in this case, so it end at
    # {1, 0} with normal colors.
    panel(root: true, size: {5, 2})
    |> save(:main)
    |> label(text: "0012")
    |> save(:hello)
    |> restore(:main)
    |> children([:hello])
    |> render()
    |> check([
      {:f, @tcf_normal},
      {:b, @tcb_normal},
      {:d, [{48, 2}, 49, 50]},
      {:f, @tcf_focused},
      {:b, @tcb_focused},
      {:d, ' '},
      {:x, 0},
      {:y, 1},
      {:d, [{32, 5}]},
      {:x, 4},
      {:y, 0},
      {:f, @tcf_normal},
      {:b, @tcb_normal}
    ])
  end
end
