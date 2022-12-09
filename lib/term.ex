defmodule Ash.Tui.Term do
  # Starts the term driver.
  @callback start(opts :: keyword()) :: state :: any()

  # Extracts the initialized option from opaque state.
  @callback opts(state :: any()) :: opts :: keyword()

  # Encodes command in the term languages
  @callback encode(command :: atom(), param :: any()) :: data :: binary()

  # Writes encoded data to the term
  @callback write(state :: any(), chardata :: iodata()) :: :ok

  def start(module, opts), do: {module, module.start(opts)}
  def opts({module, state}), do: module.opts(state)
  def encode({module, _}, command, param), do: module.encode(command, param)
  def write({module, state}, chardata), do: module.write(state, chardata)
end
