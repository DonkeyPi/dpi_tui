defmodule Ash.Tui.Term do
  # Starts the term driver.
  @callback start(opts :: keyword()) :: state :: any()

  # Extracts the initialized option from opaque state.
  @callback opts(state :: any()) :: opts :: keyword()

  # Encodes command in the term languages
  @callback encode(command :: atom(), param :: any()) :: data :: binary()

  # Writes encoded data to the term
  @callback write(state :: any(), chardata :: iodata()) :: :ok

  defp get(key), do: Process.get({__MODULE__, key})
  defp put(key, data), do: Process.put({__MODULE__, key}, data)

  def start(module, opts) do
    put(:module, module)
    state = module.start(opts)
    put(:state, state)
    :ok
  end

  def opts(), do: get(:state) |> get(:module).opts()
  def encode(cmd, param), do: get(:module).encode(cmd, param)
  def write(chardata), do: get(:state) |> get(:module).write(chardata)
end
