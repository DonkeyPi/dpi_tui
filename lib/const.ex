defmodule Ash.Tui.Const do
  defmacro __using__(_) do
    quote do
      # reverse navigation
      @rtab :shift

      # retrigger action
      @renter :shift

      @shortcuts [:esc, :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10, :f11, :f12]
    end
  end
end
