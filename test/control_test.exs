defmodule Ash.ControlTest do
  use ExUnit.Case
  use TestMacros

  test "common button check" do
    common_checks(Button, input?: true, button?: true)
  end

  test "common checkbox check" do
    common_checks(Checkbox, input?: true)
  end

  test "common frame check" do
    common_checks(Frame)
  end

  test "common input check" do
    common_checks(Input, input?: true)
  end

  test "common label check" do
    common_checks(Label)
  end

  test "common panel check" do
    common_checks(Panel, panel?: true)
  end

  test "common radio check" do
    common_checks(Radio, input?: true)
  end

  test "common select check" do
    common_checks(Select, input?: true)
  end

  def nop(), do: :nop
  def nop(value), do: {:nop, value}

  # Per feature testing is in this case better than per control
  # testing. It makes clear the differences between controls.

  def common_checks(module, opts \\ []) do
    accessors_checks(module, opts)
    navigation_checks(module, opts)
    update_checks(module, opts)
    specials_checks(module, opts)
  end

  def accessors_checks(module, opts \\ []) do
    input? = Keyword.get(opts, :input?, false)
    panel? = Keyword.get(opts, :panel?, false)
    button? = Keyword.get(opts, :button?, false)
    unused(input?, panel?, button?)

    # this should make any focusable control focusable
    focusable = %{
      enabled: true,
      visible: true,
      findex: 0,
      on_click: &nop/0,
      on_change: &nop/1,
      root: false,
      children: %{},
      focusables: %{},
      index: []
    }

    # complement to make panel focusable
    focusable = %{focusable | focusables: %{id: true}}

    # simple getters
    assert module.bounds(%{origin: {1, 2}, size: {3, 4}}) == {1, 2, 3, 4}
    assert module.visible(%{visible: :visible}) == :visible
    assert module.shortcut(%{shortcut: :shortcut}) == if(button?, do: :shortcut, else: nil)

    # focused getter
    if input? or panel? do
      assert module.focused(%{focused: :focused}) == :focused
    else
      assert module.focused(%{focused: :focused}) == false
    end

    # focused setter
    if input? or panel? do
      assert module.focused(%{focused: nil}, :focused) == %{focused: :focused}
    else
      assert module.focused(%{focused: nil}, :focused) == %{focused: nil}
    end

    # findex getter
    if input? or panel? do
      assert module.findex(%{findex: :findex}) == :findex
    else
      assert module.findex(%{findex: :findex}) == -1
    end

    # modal getter
    if panel? do
      assert module.modal(%{root: :root}) == :root
    else
      assert module.modal(:state) == false
    end

    # children getter
    if panel? do
      assert module.children(%{children: nil, index: []}) == []
      assert module.children(%{children: %{0 => 0, 1 => 1}, index: [0, 1]}) == [{0, 0}, {1, 1}]
    else
      assert module.children(:state) == []
      assert module.children(:state, []) == :state
    end

    # focusable getter
    assert module.focusable(focusable) == (input? or panel?)
    assert module.focusable(%{focusable | enabled: false}) == false
    assert module.focusable(%{focusable | visible: false}) == false
    assert module.focusable(%{focusable | findex: -1}) == false

    if panel? do
      assert module.focusable(%{focusable | root: true}) == false
      assert module.focusable(%{focusable | focusables: %{}}) == false
    else
      if input? do
        assert module.focusable(%{focusable | on_click: nil}) == not button?
        assert module.focusable(%{focusable | on_change: nil}) == button?
      else
        assert module.focusable(%{focusable | on_click: nil}) == false
        assert module.focusable(%{focusable | on_change: nil}) == false
      end
    end

    # children setter
    if not panel? do
      assert module.children(:state) == []
      assert module.children(:state, []) == :state
    else
      initial = module.init()
      children = [{0, {module, initial}}, {1, {module, initial}}]

      assert module.children(initial, children) == %{
               initial
               | index: [0, 1],
                 children: %{0 => {module, initial}, 1 => {module, initial}},
                 focusables: %{0 => false, 1 => false}
             }
    end
  end

  def navigation_checks(module, opts \\ []) do
    input? = Keyword.get(opts, :input?, false)
    panel? = Keyword.get(opts, :panel?, false)
    button? = Keyword.get(opts, :button?, false)
    unused(input?, panel?, button?)

    # navigation (except Panel)
    if input? do
      assert module.handle(%{}, @ev_kp_enter) == {%{}, {:focus, :next}}
      assert module.handle(%{}, @ev_kp_fnext) == {%{}, {:focus, :next}}
      assert module.handle(%{}, @ev_kp_fprev) == {%{}, {:focus, :prev}}
    else
      assert module.handle(%{}, @ev_kp_enter) == {%{}, nil}
      assert module.handle(%{}, @ev_kp_fnext) == {%{}, nil}
      assert module.handle(%{}, @ev_kp_fprev) == {%{}, nil}
    end

    case module do
      Button ->
        assert module.handle(%{}, @ev_kp_kdown) == {%{}, {:focus, :next}}
        assert module.handle(%{}, @ev_kp_kright) == {%{}, {:focus, :next}}
        assert module.handle(%{}, @ev_kp_kup) == {%{}, {:focus, :prev}}
        assert module.handle(%{}, @ev_kp_kleft) == {%{}, {:focus, :prev}}

      Checkbox ->
        assert module.handle(%{}, @ev_kp_kdown) == {%{}, {:focus, :next}}
        assert module.handle(%{}, @ev_kp_kright) == {%{}, {:focus, :next}}
        assert module.handle(%{}, @ev_kp_kup) == {%{}, {:focus, :prev}}
        assert module.handle(%{}, @ev_kp_kleft) == {%{}, {:focus, :prev}}

      Input ->
        assert module.handle(%{}, @ev_kp_kdown) == {%{}, {:focus, :next}}
        assert module.handle(%{}, @ev_kp_kup) == {%{}, {:focus, :prev}}

      Radio ->
        assert module.handle(%{}, @ev_kp_kdown) == {%{}, {:focus, :next}}
        assert module.handle(%{}, @ev_kp_kup) == {%{}, {:focus, :prev}}

      Select ->
        assert module.handle(%{}, @ev_kp_kright) == {%{}, {:focus, :next}}
        assert module.handle(%{}, @ev_kp_kleft) == {%{}, {:focus, :prev}}

      Label ->
        nil

      Frame ->
        nil

      Panel ->
        nil
    end
  end

  def update_checks(module, opts \\ []) do
    input? = Keyword.get(opts, :input?, false)
    panel? = Keyword.get(opts, :panel?, false)
    button? = Keyword.get(opts, :button?, false)
    unused(input?, panel?, button?)

    # update
    initial = module.init()

    # origin update
    assert module.update(initial, origin: {0, 0}) == initial
    assert module.update(initial, origin: {1, 2}) == %{initial | origin: {1, 2}}

    # visible update
    assert module.update(initial, visible: true) == initial
    assert module.update(initial, visible: false) == %{initial | visible: false}

    # enabled update
    if input? or panel? do
      assert module.update(initial, enabled: true) == initial
      assert module.update(initial, enabled: false) == %{initial | enabled: false}
    end

    # focused update (always dropped)
    if input? or panel? do
      assert module.update(initial, focused: :dropped) == initial
    end

    # findex update
    if input? or panel? do
      assert module.update(initial, findex: 0) == initial
      assert module.update(initial, findex: -1) == %{initial | findex: -1}
    end

    # class update
    assert module.update(initial, class: nil) == initial
    assert module.update(initial, class: :class) == %{initial | class: :class}

    # size update
    assert module.update(initial, size: {0, 2}) == %{initial | size: {0, 2}}

    case module do
      Button -> assert module.update(initial, size: {0, 1}) == initial
      Checkbox -> assert module.update(initial, size: {3, 1}) == initial
      Frame -> assert module.update(initial, size: {2, 2}) == initial
      Input -> assert module.update(initial, size: {0, 1}) == initial
      Label -> assert module.update(initial, size: {0, 1}) == initial
      Panel -> assert module.update(initial, size: {0, 0}) == initial
      Radio -> assert module.update(initial, size: {0, 1}) == initial
      Select -> assert module.update(initial, size: {0, 0}) == initial
    end

    # control specific updates
    case module do
      Button ->
        on_click = fn -> :click end
        assert module.update(initial, text: "") == initial
        assert module.update(initial, shortcut: nil) == initial
        assert module.update(initial, on_click: nil) == initial
        assert module.update(initial, text: "text") == %{initial | text: "text"}
        assert module.update(initial, shortcut: :esc) == %{initial | shortcut: :esc}
        assert module.update(initial, on_click: on_click) == %{initial | on_click: on_click}

      Checkbox ->
        on_change = fn checked -> checked end
        assert module.update(initial, text: "") == initial
        assert module.update(initial, checked: false) == initial
        assert module.update(initial, on_change: nil) == initial
        assert module.update(initial, text: "text") == %{initial | text: "text"}
        assert module.update(initial, checked: true) == %{initial | checked: true}
        assert module.update(initial, on_change: on_change) == %{initial | on_change: on_change}

      Frame ->
        assert module.update(initial, border: :single) == initial
        assert module.update(initial, text: "") == initial
        assert module.update(initial, border: :double) == %{initial | border: :double}
        assert module.update(initial, text: "text") == %{initial | text: "text"}

      Input ->
        on_change = fn value -> value end
        assert module.update(initial, cursor: :dropped) == initial
        assert module.update(initial, password: false) == initial
        assert module.update(initial, text: "") == initial
        assert module.update(initial, on_change: nil) == initial
        assert module.update(initial, password: true) == %{initial | password: true}
        assert module.update(initial, on_change: on_change) == %{initial | on_change: on_change}

      Label ->
        assert module.update(initial, align: :left) == initial
        assert module.update(initial, text: "") == initial
        assert module.update(initial, align: :center) == %{initial | align: :center}
        assert module.update(initial, text: "text") == %{initial | text: "text"}

      Panel ->
        assert module.update(initial, root: :dropped) == initial
        assert module.update(initial, index: :dropped) == initial
        assert module.update(initial, children: :dropped) == initial
        assert module.update(initial, focus: :dropped) == initial

      Radio ->
        on_change = fn {index, item} -> {index, item} end
        assert module.update(initial, count: :dropped) == initial
        assert module.update(initial, map: :dropped) == initial
        assert module.update(initial, items: []) == initial
        # any selected value will be recalculated to initial -1
        assert module.update(initial, selected: -1) == initial
        assert module.update(initial, selected: 0) == initial
        assert module.update(initial, selected: 1) == initial
        assert module.update(initial, on_change: nil) == initial
        assert module.update(initial, on_change: on_change) == %{initial | on_change: on_change}

      Select ->
        on_change = fn {index, item} -> {index, item} end
        assert module.update(initial, count: :dropped) == initial
        assert module.update(initial, map: :dropped) == initial
        assert module.update(initial, offset: :dropped) == initial
        # any selected value will be recalculated to initial -1
        assert module.update(initial, selected: -1) == initial
        assert module.update(initial, selected: 0) == initial
        assert module.update(initial, selected: 1) == initial
        assert module.update(initial, items: []) == initial
        assert module.update(initial, on_change: nil) == initial
        assert module.update(initial, on_change: on_change) == %{initial | on_change: on_change}
    end
  end

  def specials_checks(module, opts \\ []) do
    input? = Keyword.get(opts, :input?, false)
    panel? = Keyword.get(opts, :panel?, false)
    button? = Keyword.get(opts, :button?, false)
    unused(input?, panel?, button?)

    # nop
    assert module.handle(%{}, :any) == {%{}, nil}

    # refocus
    if not panel? do
      assert module.refocus(:state, :dir) == :state
    end

    # shortcuts
    if button? do
      model = %{on_click: &Button.nop/0, shortcut: :shortcut}
      assert module.handle(model, {:shortcut, :shortcut, :press}) == {model, {:click, :nop}}
    else
      assert module.handle(%{}, {:shortcut, :shortcut, :press}) == {%{}, nil}
    end
  end

  defp unused(_input?, _panel?, _button?), do: :unused
end
