defmodule Ash.Tui.Layouts do
  defmacro __using__(_) do
    quote do
      @english 0
      @latam 1
    end
  end
end
