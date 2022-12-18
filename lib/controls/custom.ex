defmodule Ash.Tui.Custom do
  @behaviour Ash.Tui.Control

  @props %{size: {0, 0}, origin: {0, 0}}

  def init(props), do: Enum.into(props, @props)
  def bounds(%{origin: {x, y}, size: {w, h}}), do: {x, y, w, h}
  def visible(model), do: Map.get(model, :visible, true)
  def focused(model, focused), do: Map.put(model, :focused, focused)
  def focused(model), do: Map.get(model, :focused, false)
  def findex(model), do: Map.get(model, :findex, -1)
  def shortcut(model), do: Map.get(model, :shortcut, nil)
  def valid(model), do: Map.get(model, :valid, true)
  def modal(model), do: Map.get(model, :modal, false)
  def update(model, props), do: Map.merge(model, Enum.into(props, @props))
  def children(model, _), do: model
  def children(_), do: []

  def focusable(model), do: Map.get(model, :focusable, fn -> false end).()

  def refocus(model, dir), do: Map.get(model, :refocus, fn model, _dir -> model end).(model, dir)

  def handle(model, event),
    do: Map.get(model, :handle, fn model, _event -> {model, nil} end).(model, event)

  def render(model, canvas, theme),
    do: Map.get(model, :render, fn _model, canvas, _theme -> canvas end).(model, canvas, theme)
end
