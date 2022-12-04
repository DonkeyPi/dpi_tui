ExUnit.start()

# FIXME understand why Button requires the outer `use Ash.Tui`
defmodule ControlTest do
  use Ash.Tui

  defmacro __using__(_) do
    quote do
      alias Ash.Tui.Control
      use Ash.Tui

      def nop(), do: :nop
      def nop(value), do: {:nop, value}

      def control_test(module, opts \\ []) do
        input? = Keyword.get(opts, :input?, false)
        panel? = Keyword.get(opts, :panel?, false)
        button? = Keyword.get(opts, :button?, false)

        focusable = %{
          enabled: true,
          visible: true,
          findex: 0,
          on_click: &nop/0,
          on_change: &nop/1,
          root: false,
          children: %{},
          index: []
        }

        focusable = %{focusable | children: %{id: {Button, focusable}}, index: [:id]}

        assert module.bounds(%{origin: {1, 2}, size: {3, 4}}) == {1, 2, 3, 4}
        assert module.visible(%{visible: :visible}) == :visible
        assert module.shortcut(%{shortcut: :shortcut}) == if(button?, do: :shortcut, else: nil)

        if input? or panel? do
          assert module.focused(%{focused: :focused}) == :focused
          assert module.focused(%{focused: nil}, :focused) == %{focused: :focused}
          assert module.findex(%{findex: :findex}) == :findex
        else
          assert module.focused(%{focused: :focused}) == false
          assert module.focused(%{focused: nil}, :focused) == %{focused: nil}
          assert module.findex(%{findex: :findex}) == -1
        end

        assert module.focusable(focusable) == (input? or panel?)
        assert module.focusable(%{focusable | enabled: false}) == false
        assert module.focusable(%{focusable | visible: false}) == false
        assert module.focusable(%{focusable | findex: -1}) == false

        if not panel? do
          assert module.focusable(%{focusable | on_click: nil}) ==
                   if(input?, do: not button?, else: false)

          assert module.focusable(%{focusable | on_change: nil}) ==
                   if(input?, do: button?, else: false)

          assert module.refocus(:state, :dir) == :state
          assert module.children(:state) == []
          assert module.children(:state, []) == :state
          assert module.modal(:state) == false
        end
      end
    end
  end
end
