defmodule Ash.Tui.Events do
  defmacro __using__(_) do
    quote do
      @shortcuts [:esc, :f1, :f2, :f3, :f4, :f5, :f6, :f7, :f8, :f9, :f10, :f11, :f12]

      @ev_kp_kdown %{type: :key, action: :press, key: :kdown, flag: :none}
      @ev_kp_kright %{type: :key, action: :press, key: :kright, flag: :none}
      @ev_kp_kleft %{type: :key, action: :press, key: :kleft, flag: :none}
      @ev_kp_kup %{type: :key, action: :press, key: :kup, flag: :none}
      @ev_kp_space %{type: :key, action: :press, key: ' ', flag: :none}
      @ev_kp_home %{type: :key, action: :press, key: :home, flag: :none}
      @ev_kp_end %{type: :key, action: :press, key: :end, flag: :none}
      @ev_kp_backspace %{type: :key, action: :press, key: :backspace, flag: :none}
      @ev_kp_delete %{type: :key, action: :press, key: :delete, flag: :none}
      @ev_kp_pdown %{type: :key, action: :press, key: :pdown, flag: :none}
      @ev_kp_pup %{type: :key, action: :press, key: :pup, flag: :none}

      # add :none to make it handler order insensitive
      @ev_kp_fnext %{type: :key, action: :press, key: :tab, flag: :none}
      @ev_kp_fprev %{type: :key, action: :press, key: :tab, flag: :control}
      @ev_kp_enter %{type: :key, action: :press, key: :return, flag: :none}
      @ev_kp_trigger %{type: :key, action: :press, key: :return, flag: :control}

      @ev_mp_left %{type: :mouse, action: :press, key: :bleft}

      @ev_ms_up %{type: :mouse, action: :scroll, dir: :up, flag: :none}
      @ev_ms_down %{type: :mouse, action: :scroll, dir: :down, flag: :none}
      @ev_ms_pup %{type: :mouse, action: :scroll, dir: :up, flag: :control}
      @ev_ms_pdown %{type: :mouse, action: :scroll, dir: :down, flag: :control}

      def ev_mp_left(x, y), do: %{type: :mouse, action: :press, key: :bleft, x: x, y: y}
      def ev_kp_data(data), do: %{type: :key, action: :press, key: data}
    end
  end
end
