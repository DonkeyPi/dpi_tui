defmodule Ash.Tui.Term do
  # Starts the term driver.
  @callback start(opts :: keyword()) :: {pid :: pid(), opts :: keyword()}

  # Encodes commands
  @callback encode(cmd :: any(), param :: any()) :: chardata :: iodata()

  # Writes encoded data to the term
  @callback write(pid :: pid(), chardata :: iodata()) :: :ok

  defp get(key), do: Process.get({__MODULE__, key})
  defp put(key, data), do: Process.put({__MODULE__, key}, data)

  def start(module, opts) do
    {pid, opts} = module.start(opts)
    put(:write, fn chardata -> module.write(pid, chardata) end)
    put(:encode, fn cmd, param -> module.encode(cmd, param) end)
    {:ok, opts}
  end

  def encode(cmd, param), do: get(:encode).(cmd, param)
  def set_title(title), do: write(get(:encode).(:title, title))
  def write(chardata), do: get(:write).(chardata)
end
