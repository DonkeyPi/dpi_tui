defmodule Ash.Tui.Theme do
  use Ash.Tui.Const

  def get(:default) do
    %{
      back_readonly: @black,
      fore_readonly: @black2,
      back_editable: @black,
      fore_editable: @white,
      back_disabled: @black,
      fore_disabled: @black2,
      back_selected: @white,
      fore_selected: @black,
      back_focused: @blue,
      fore_focused: @white,
      back_notice: @blue,
      fore_notice: @white,
      back_error: @red,
      fore_error: @white,
      # for testing
      not_used: @red
    }
  end

  def get(module), do: module.theme()
end
