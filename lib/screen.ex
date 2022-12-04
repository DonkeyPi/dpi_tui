defmodule Ash.Tui.Screen do
  # Starts the screen driver.
  @callback start(opts :: keyword()) :: state :: any()

  # Extracts the initialized option from opaque state.
  @callback opts(state :: any()) :: opts :: keyword()
  @callback encode(command :: atom(), param :: any()) :: data :: binary()

  def start(module, opts), do: {module, module.start(opts)}
  def opts({module, state}), do: module.opts(state)
  def encode({module, _}, command, param), do: module.encode(command, param)
  def write({module, state}, data), do: module.write(state, data)
end
