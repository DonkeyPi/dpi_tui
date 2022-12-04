defmodule Ash.Tui.Const do
  defmacro __using__(_) do
    quote do
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

      @esc "\e"

      @ctl 1
      @alt 2
      @fun 4

      @up 1
      @down 2
      @right 3
      @left 4

      @fi 100
      @f1 101
      @f2 102
      @f3 103
      @f4 104
      @f5 105
      @f6 106
      @f7 107
      @f8 108
      @f9 109
      @f10 110
      @f11 111
      @f12 112

      @home 201
      @hend 202
      @insert 203
      @delete 204
      @backspace 205

      @page 300
      @page_up @page + @up
      @page_down @page + @down

      @arrow 400
      @arrow_up @arrow + @up
      @arrow_down @arrow + @down
      @arrow_right @arrow + @right
      @arrow_left @arrow + @left

      @mouse 500
      @mouse_up @mouse + @up
      @mouse_down @mouse + @down

      @wheel_up 64
      @wheel_down 65

      @shortcuts [@esc, @f1, @f2, @f3, @f4, @f5, @f6, @f7, @f8, @f9, @f10, @f11, @f12]
    end
  end
end
