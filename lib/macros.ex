defmodule Ash.Tui.Macros do
  alias Ash.Tui.Checkbox
  alias Ash.Tui.Select
  alias Ash.Tui.Button
  alias Ash.Tui.Frame
  alias Ash.Tui.Input
  alias Ash.Tui.Label
  alias Ash.Tui.Panel
  alias Ash.Tui.Radio
  use Ash.Node

  defmacro panel(id, props) do
    quote do
      id = unquote(id)
      props = unquote(props)
      node(id, Panel, props)
    end
  end

  defmacro panel(id, props, do: body) do
    quote do
      id = unquote(id)
      props = unquote(props)

      node(id, Panel, props) do
        unquote(body)
      end
    end
  end

  defmacro frame(id, props) do
    quote do
      id = unquote(id)
      props = unquote(props)
      node(id, Frame, props)
    end
  end

  defmacro frame(id, props, do: body) do
    quote do
      id = unquote(id)
      props = unquote(props)

      node(id, Frame, props) do
        unquote(body)
      end
    end
  end

  defmacro checkbox(id, props) do
    quote do
      id = unquote(id)
      props = unquote(props)
      node(id, Checkbox, props)
    end
  end

  defmacro select(id, props) do
    quote do
      id = unquote(id)
      props = unquote(props)
      node(id, Select, props)
    end
  end

  defmacro button(id, props) do
    quote do
      id = unquote(id)
      props = unquote(props)
      node(id, Button, props)
    end
  end

  defmacro input(id, props) do
    quote do
      id = unquote(id)
      props = unquote(props)
      node(id, Input, props)
    end
  end

  defmacro label(id, props) do
    quote do
      id = unquote(id)
      props = unquote(props)
      node(id, Label, props)
    end
  end

  defmacro radio(id, props) do
    quote do
      id = unquote(id)
      props = unquote(props)
      node(id, Radio, props)
    end
  end
end
