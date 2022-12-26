defmodule Ash.Tui.Colors do
  defmacro __using__(_) do
    quote do
      # logo color
      @ash_logo_fore 0x1C

      # basic linux console colors
      @black 0
      @red 1
      @green 2
      @yellow 3
      @blue 4
      @magenta 5
      @cyan 6
      @white 7

      @bright 8

      @black2 @bright + @black
      @red2 @bright + @red
      @green2 @bright + @green
      @yellow2 @bright + @yellow
      @blue2 @bright + @blue
      @magenta2 @bright + @magenta
      @cyan2 @bright + @cyan
      @white2 @bright + @white
    end
  end
end
