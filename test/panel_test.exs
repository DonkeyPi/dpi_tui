defmodule Ash.PanelTest do
  use ExUnit.Case
  use TestMacros

  test "basic panel check" do
    initial = Panel.init()

    # defaults
    assert initial == %{
             focused: false,
             origin: {0, 0},
             size: {0, 0},
             visible: true,
             enabled: true,
             findex: 0,
             class: nil,
             root: false,
             index: [],
             children: %{},
             focusables: %{},
             focus: nil
           }

    # panel draws background
    panel(size: {2, 1})
    |> render()
    |> assert_color("  ", 0, @tc_normal)

    # top label overrides bottom label
    l0 = Control.init(Label, text: "0")
    l1 = Control.init(Label, text: "1")

    panel(size: {1, 1})
    |> children(l0: l0, l1: l1)
    |> render()
    |> assert_color("1", 0, @tc_normal)

    # hidded label wont render
    l0 = Control.init(Label, text: "0")
    l1 = Control.init(Label, text: "1", visible: false)

    panel(size: {1, 1})
    |> children(l0: l0, l1: l1)
    |> render()
    |> assert_color("0", 0, @tc_normal)

    # modal wont render (visible or invisible)
    label(text: "abc")
    |> save(:label1)
    |> label(text: "xyz")
    |> save(:label2)
    |> panel(root: true, size: {3, 1}, visible: false)
    |> children([:label2])
    |> save(:modal)
    |> panel(root: true, size: {3, 1})
    |> children([:label1, :modal])
    |> render()
    |> assert_color("abc", 0, @tc_normal)
    |> update(:modal, visible: true)
    |> render()
    |> assert_color("abc", 0, @tc_normal)
    # root is dropped by update
    |> put(:modal, root: false)
    |> render()
    |> assert_color("xyz", 0, @tc_normal)
  end

  test "panel handle check" do
    root = Panel.init(root: true)
    normal = Panel.init(root: false)

    panel = Panel.children(root, c0: Control.init(Label, size: {1, 1}))
    {^panel, nil} = Panel.handle(panel, @ev_kp_fnext)
    {^panel, nil} = Panel.handle(panel, @ev_kp_trigger)
    {^panel, nil} = Panel.handle(panel, ev_mp_left(0, 0))

    panel = Panel.children(root, c0: Control.init(Button, size: {1, 1}))
    {^panel, nil} = Panel.handle(panel, @ev_kp_fnext)
    {^panel, {:c0, {:click, :nop}}} = Panel.handle(panel, @ev_kp_trigger)
    {^panel, {:c0, {:click, :nop}}} = Panel.handle(panel, ev_mp_left(0, 0))

    # mouse changes focus with reversed order match search
    # last in the index means at the top
    panel =
      Panel.children(root,
        c0: Control.init(Button, size: {1, 1}),
        c1: Control.init(Button, size: {1, 1})
      )

    assert panel.focus == :c0
    {panel, {:c1, {:click, :nop}}} = Panel.handle(panel, ev_mp_left(0, 0))
    assert panel.focus == :c1
    assert elem(panel.children.c0, 1).focused == false
    assert elem(panel.children.c1, 1).focused == true

    # mouse ignores non visibles at the top
    panel =
      Panel.children(root,
        c0: Control.init(Button, size: {1, 1}),
        c1: Control.init(Button, size: {1, 1}, visible: false)
      )

    {^panel, {:c0, {:click, :nop}}} = Panel.handle(panel, ev_mp_left(0, 0))

    # non focusable shadows button
    panel =
      Panel.children(root,
        c0: Control.init(Button, size: {1, 1}),
        c1: Control.init(Label, size: {1, 1})
      )

    {^panel, nil} = Panel.handle(panel, ev_mp_left(0, 0))

    # invisible modal wont shadow button
    panel =
      Panel.children(root,
        c0: Control.init(Button, size: {1, 1}),
        c1: Control.init(Panel, size: {1, 1}, root: true, visible: false)
      )

    {^panel, {:c0, {:click, :nop}}} = Panel.handle(panel, ev_mp_left(0, 0))

    # visible modal shadows button
    panel =
      Panel.children(root,
        c0: Control.init(Button, size: {1, 1}),
        c1: Control.init(Panel, size: {1, 1}, root: true, visible: true)
      )

    {^panel, nil} = Panel.handle(panel, {:modal, [:c1], ev_mp_left(0, 0)})

    # keys get to nested focused control
    panel = Panel.children(normal, c0: Control.init(Button))
    panel = Panel.children(root, p0: {Panel, panel})
    {^panel, nil} = Panel.handle(panel, @ev_kp_fnext)
    {^panel, {:p0, {:c0, {:click, :nop}}}} = Panel.handle(panel, @ev_kp_trigger)

    # mouse gets to nested focused control
    panel = Panel.update(normal, size: {1, 1})
    panel = Panel.children(panel, c0: Control.init(Button, size: {1, 1}))
    panel = Panel.children(root, p0: {Panel, panel})
    {^panel, {:p0, {:c0, {:click, :nop}}}} = Panel.handle(panel, ev_mp_left(0, 0))

    # mouse focuses nested top control
    panel = Panel.update(normal, size: {1, 1})

    panel =
      Panel.children(panel,
        c0: Control.init(Button, size: {1, 1}),
        c1: Control.init(Button, size: {1, 1})
      )

    panel = Panel.children(root, p0: {Panel, panel})
    inner = elem(panel.children.p0, 1)
    assert elem(inner.children.c0, 1).focused == true
    {panel, {:p0, {:c1, {:click, :nop}}}} = Panel.handle(panel, ev_mp_left(0, 0))
    inner = elem(panel.children.p0, 1)
    assert elem(inner.children.c0, 1).focused == false
    assert elem(inner.children.c1, 1).focused == true

    # mouse gets to second level next child converted to client coordinates
    panel0 = Panel.update(normal, origin: {1, 1}, size: {2, 2})
    panel0 = Panel.children(panel0, c0: Control.init(Button, origin: {1, 1}, size: {1, 1}))
    panel = Panel.update(root, size: {3, 3})
    panel = Panel.children(panel, p0: {Panel, panel0})
    {_, nil} = Panel.handle(panel, ev_mp_left(0, 0))
    {_, nil} = Panel.handle(panel, ev_mp_left(1, 1))
    {_, {:p0, {:c0, {:click, :nop}}}} = Panel.handle(panel, ev_mp_left(2, 2))
    {_, nil} = Panel.handle(panel, ev_mp_left(3, 3))

    # input gets to second level next child converted to client coordinates
    panel0 = Panel.update(normal, origin: {1, 1}, size: {4, 2})
    panel0 = Panel.children(panel0, c0: Control.init(Radio, origin: {1, 1}, items: [0, 1]))
    panel = Panel.update(root, size: {5, 3})
    panel = Panel.children(panel, p0: {Panel, panel0})
    {panel, nil} = Panel.handle(panel, ev_mp_left(0, 0))
    {panel, nil} = Panel.handle(panel, ev_mp_left(1, 1))
    {panel, nil} = Panel.handle(panel, ev_mp_left(2, 2))
    {panel, {:p0, {:c0, {:item, 1, 1, {:nop, {1, 1}}}}}} = Panel.handle(panel, ev_mp_left(4, 2))
    {panel, {:p0, {:c0, {:item, 0, 0, {:nop, {0, 0}}}}}} = Panel.handle(panel, ev_mp_left(2, 2))
    {_, nil} = Panel.handle(panel, ev_mp_left(3, 3))

    # input gets to second level next child converted to client coordinates
    # click goes to control on unfocused branch
    panel0 = Panel.children(normal, c0: Control.init(Button))
    panel1 = Panel.update(normal, origin: {1, 1}, size: {4, 2})
    panel1 = Panel.children(panel1, c0: Control.init(Radio, origin: {1, 1}, items: [0, 1]))
    panel = Panel.update(root, size: {5, 3})
    panel = Panel.children(panel, p0: {Panel, panel0}, p1: {Panel, panel1})
    {panel, {:p0, {:c0, {:click, :nop}}}} = Panel.handle(panel, @ev_kp_trigger)
    {panel, nil} = Panel.handle(panel, ev_mp_left(0, 0))
    {panel, nil} = Panel.handle(panel, ev_mp_left(1, 1))
    {panel, nil} = Panel.handle(panel, ev_mp_left(2, 2))
    {panel, {:p1, {:c0, {:item, 1, 1, {:nop, {1, 1}}}}}} = Panel.handle(panel, ev_mp_left(4, 2))
    {panel, {:p1, {:c0, {:item, 0, 0, {:nop, {0, 0}}}}}} = Panel.handle(panel, ev_mp_left(2, 2))
    {panel, {:p1, {:c0, {:item, 0, 0, {:nop, {0, 0}}}}}} = Panel.handle(panel, @ev_kp_trigger)
    {_, nil} = Panel.handle(panel, ev_mp_left(3, 3))
  end

  test "panel refocus check" do
    root = Panel.init(root: true)
    normal = Panel.init(root: false)
    hidden = Panel.init(root: true, visible: false)
    disabled = Panel.init(root: true, enabled: false)
    findex = Panel.init(root: true, findex: -1)

    # replacing a button by a label losses focus (same id)
    panel = Panel.children(root, c0: Control.init(Button))
    assert panel.focus == :c0
    panel = Panel.children(panel, c0: Control.init(Label))
    assert panel.focus == nil

    # replacing a button by a label losses focus (different id)
    panel = Panel.children(root, c0: Control.init(Button))
    assert panel.focus == :c0
    panel = Panel.children(panel, c1: Control.init(Label))
    assert panel.focus == nil

    # replacing a button by a non focusable button losses focus
    panel = Panel.children(root, c0: Control.init(Button))
    assert panel.focus == :c0
    panel = Panel.children(panel, c0: Control.init(Button, findex: -1))
    assert panel.focus == nil

    # replacing a button by a button transfers focus
    panel = Panel.children(root, c0: Control.init(Button))
    assert panel.focus == :c0
    panel = Panel.children(panel, c1: Control.init(Button))
    assert panel.focus == :c1

    # modals use the autofocus below when made visible
    # making a root panel visible gains focus
    panel = Panel.children(hidden, c0: Control.init(Button))
    assert panel.focus == nil
    panel = Panel.update(panel, visible: true)
    assert panel.focus == :c0

    # enabling a root panel gains focus
    panel = Panel.children(disabled, c0: Control.init(Button))
    assert panel.focus == nil
    panel = Panel.update(panel, enabled: true)
    assert panel.focus == :c0

    # setting a valid findex on a root panel gains focus
    panel = Panel.children(findex, c0: Control.init(Button))
    assert panel.focus == nil
    panel = Panel.update(panel, findex: 0)
    assert panel.focus == :c0

    # refocus next goes to first child
    panel = Panel.children(normal, c0: Control.init(Button), c1: Control.init(Button))
    assert panel.focus == nil
    panel = Panel.focused(panel, true)
    panel = Panel.refocus(panel, :next)
    assert panel.focus == :c0

    # refocus prev goes to last child
    panel = Panel.children(normal, c0: Control.init(Button), c1: Control.init(Button))
    assert panel.focus == nil
    panel = Panel.focused(panel, true)
    panel = Panel.refocus(panel, :prev)
    assert panel.focus == :c1

    # Double focus, double cursor, or cursor override problem.
    # Moving focus to a different branch clears previous branch.

    # (1) Control holding the focus gets non focusable
    panel0 = Panel.children(normal, c0: Control.init(Button))
    panel1 = Panel.children(normal, c0: Control.init(Button))
    panel = Panel.children(root, p0: {Panel, panel0}, p1: {Panel, panel1})
    inner = elem(panel.children.p0, 1)
    assert inner.focused == true
    assert elem(inner.children.c0, 1).focused == true
    inner = elem(panel.children.p1, 1)
    assert elem(inner.children.c0, 1).focused == false
    button0 = %{elem(inner.children.c0, 1) | findex: -1}
    panel0 = Panel.children(normal, c0: {Button, button0})
    panel = Panel.children(root, p0: {Panel, panel0}, p1: {Panel, panel1})
    inner = elem(panel.children.p0, 1)
    assert inner.focused == false
    assert elem(inner.children.c0, 1).focused == false
    inner = elem(panel.children.p1, 1)
    assert elem(inner.children.c0, 1).focused == true

    # (2) Mouse click on a different branch.
    panel0 = Panel.children(normal, c0: Control.init(Button))
    panel1 = Panel.update(normal, size: {1, 1})
    panel1 = Panel.children(panel1, c0: Control.init(Button, size: {1, 1}))
    panel = Panel.update(root, size: {1, 1})
    panel = Panel.children(panel, p0: {Panel, panel0}, p1: {Panel, panel1})
    inner = elem(panel.children.p0, 1)
    assert inner.focused == true
    assert elem(inner.children.c0, 1).focused == true
    inner = elem(panel.children.p1, 1)
    assert elem(inner.children.c0, 1).focused == false
    {panel, {:p1, {:c0, {:click, :nop}}}} = Panel.handle(panel, ev_mp_left(0, 0))
    inner = elem(panel.children.p0, 1)
    assert inner.focused == false
    assert elem(inner.children.c0, 1).focused == false
    inner = elem(panel.children.p1, 1)
    assert elem(inner.children.c0, 1).focused == true
  end
end
