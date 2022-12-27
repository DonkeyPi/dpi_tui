defmodule Ash.Tui.Events do
  defmacro __using__(_) do
    quote do
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
      @ev_kp_home_shift %{type: :key, action: :press, key: :home, flag: :shift}
      @ev_kp_end_shift %{type: :key, action: :press, key: :end, flag: :shift}

      # add :none to make it handler order insensitive
      @ev_kp_fnext %{type: :key, action: :press, key: :tab, flag: :none}
      @ev_kp_fprev %{type: :key, action: :press, key: :tab, flag: :shift}
      # easy to disable second focus prev trigger
      @ev_kp_fprev2 %{type: :key, action: :press, key: :tab, flag: :control}
      @ev_kp_enter %{type: :key, action: :press, key: :return, flag: :none}
      @ev_kp_trigger %{type: :key, action: :press, key: :return, flag: :control}
      @ev_ms_trigger %{type: :mouse, action: :press, key: :bleft, flag: :control}
      @ev_ms_trigger2 %{type: :mouse, action: :press2, key: :bleft, flag: :none}

      @ev_mp_left %{type: :mouse, action: :press, key: :bleft, flag: :none}

      @ev_ms_up %{type: :mouse, action: :scroll, dir: :up, flag: :none}
      @ev_ms_down %{type: :mouse, action: :scroll, dir: :down, flag: :none}
      @ev_ms_pup %{type: :mouse, action: :scroll, dir: :up, flag: :control}
      @ev_ms_pdown %{type: :mouse, action: :scroll, dir: :down, flag: :control}

      def ev_mp_left(x, y),
        do: %{type: :mouse, action: :press, key: :bleft, x: x, y: y, flag: :none}

      def ev_kp_data(data), do: %{type: :key, action: :press, key: data, flag: :none}
    end
  end
end
