defmodule Dpi.FocusTest do
  use ExUnit.Case
  use TestMacros

  # Focus is a path (root > panel > panel > panel > control)
  # of focused panels from root to the active control.
  # Any other control outside the path must have focused = false.
  # Focusable controls must be visible, enabled, indexed, and actionable.
  # Panels try at any time to synchronize their focused state.
  # - Non focused root panels try to focus a focusable child.
  # - Focused panels try to recover from child focus loss.

  test "basic single level focus check" do
    root = Panel.init(root: true)

    children = [
      l0: {Label, Label.init()},
      c0: {Button, Button.init()},
      c1: {Button, Button.init()},
      l1: {Label, Label.init()}
    ]

    # focus next, single level, multiple children
    panel = Panel.children(root, children)
    assert panel.focus == :c0
    {panel, nil} = Panel.handle(panel, @ev_kp_fnext)
    assert panel.focus == :c1
    {panel, nil} = Panel.handle(panel, @ev_kp_fnext)
    assert panel.focus == :c0

    # focus prev, single level, multiple children
    panel = Panel.children(root, children)
    assert panel.focus == :c0
    {panel, nil} = Panel.handle(panel, @ev_kp_fprev)
    assert panel.focus == :c1
    {panel, nil} = Panel.handle(panel, @ev_kp_fprev)
    assert panel.focus == :c0

    panel = Panel.children(root, children)
    assert panel.focus == :c0
    {panel, nil} = Panel.handle(panel, @ev_kp_fprev2)
    assert panel.focus == :c1
    {panel, nil} = Panel.handle(panel, @ev_kp_fprev2)
    assert panel.focus == :c0

    children = [
      l0: {Label, Label.init()},
      c0: {Button, Button.init()},
      l1: {Label, Label.init()}
    ]

    # focus next, single level, single child
    panel = Panel.children(root, children)
    assert panel.focus == :c0
    {panel, nil} = Panel.handle(panel, @ev_kp_fnext)
    assert panel.focus == :c0

    # focus prev, single level, single child
    panel = Panel.children(root, children)
    assert panel.focus == :c0
    {panel, nil} = Panel.handle(panel, @ev_kp_fprev)
    assert panel.focus == :c0

    panel = Panel.children(root, children)
    assert panel.focus == :c0
    {panel, nil} = Panel.handle(panel, @ev_kp_fprev2)
    assert panel.focus == :c0
  end

  test "basic multi level focus check" do
    root = Panel.init(root: true)
    normal = Panel.init(root: false)

    children = [
      l0: {Label, Label.init()},
      c0: {Button, Button.init()},
      c1: {Button, Button.init()},
      l1: {Label, Label.init()}
    ]

    # focus next, multi level, multiple children
    panel = Panel.children(normal, children)
    panel = Panel.children(root, p0: {Panel, panel})
    assert elem(panel.children.p0, 1).focus == :c0
    {panel, nil} = Panel.handle(panel, @ev_kp_fnext)
    assert elem(panel.children.p0, 1).focus == :c1
    {panel, nil} = Panel.handle(panel, @ev_kp_fnext)
    assert elem(panel.children.p0, 1).focus == :c0

    # focus prev, multi level, multiple children
    panel = Panel.children(normal, children)
    panel = Panel.children(root, p0: {Panel, panel})
    assert elem(panel.children.p0, 1).focus == :c0
    {panel, nil} = Panel.handle(panel, @ev_kp_fprev)
    assert elem(panel.children.p0, 1).focus == :c1
    {panel, nil} = Panel.handle(panel, @ev_kp_fprev)
    assert elem(panel.children.p0, 1).focus == :c0

    panel = Panel.children(normal, children)
    panel = Panel.children(root, p0: {Panel, panel})
    assert elem(panel.children.p0, 1).focus == :c0
    {panel, nil} = Panel.handle(panel, @ev_kp_fprev2)
    assert elem(panel.children.p0, 1).focus == :c1
    {panel, nil} = Panel.handle(panel, @ev_kp_fprev2)
    assert elem(panel.children.p0, 1).focus == :c0
  end
end
