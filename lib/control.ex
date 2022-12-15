defmodule Ash.Tui.Control do
  @callback init(opts :: map()) :: model :: map()
  @callback handle(model :: map(), event :: any()) :: {model :: map(), cmd :: any()}
  @callback render(model :: map(), canvas :: map(), theme :: function()) :: canvas :: map()
  @callback bounds(model :: map()) :: {integer(), integer(), integer(), integer()}
  @callback visible(model :: map()) :: true | false
  @callback update(model :: map(), Keyword.t()) :: any()
  # Bypassed by non input controls like nil, label, and frame.
  @callback focusable(model :: map()) :: true | false
  @callback focused(model :: map(), true | false) :: model :: map()
  @callback focused(model :: map()) :: true | false
  @callback findex(model :: map()) :: integer()
  # Only used by button, ignored by all other controls.
  @callback shortcut(model :: map()) :: any()
  # Only used by panel, ignored by all other controls.
  @callback children(model :: map()) :: Keyword.t()
  @callback children(model :: map(), Keyword.t()) :: any()
  @callback refocus(model :: map(), dir :: any()) :: model :: map()
  @callback modal(model :: map()) :: true | false
  @callback valid(model :: map()) :: true | false
  # No need to add getters/setter for enabled, class, theme, etc.
  # The init | update are the only entry poing needed.

  # Useful to return a momo.
  def init(module, opts \\ []), do: {module, module.init(opts)}

  # Prevent insertion of unknown properties.
  def merge(map, props) do
    for {key, value} <- props, reduce: map do
      map ->
        if !Map.has_key?(map, key), do: raise("Invalid prop #{key}: #{inspect(value)}")
        Map.put(map, key, value)
    end
  end

  # Set default value if currently nil.
  def coalesce(map, key, value) do
    case {Map.has_key?(map, key), Map.get(map, key)} do
      {true, nil} -> Map.put(map, key, value)
      _ -> map
    end
  end

  # Build a model tree to detect node preexistence.
  def tree({module, model}, ids, map \\ %{}) do
    map =
      for {id, momo} <- module.children(model), reduce: map do
        map -> tree(momo, [id | ids], map)
      end

    Map.put(map, ids, {module, model})
  end

  def toclient({x, y, w, h}, mx, my) do
    case mx >= x and mx < x + w and my >= y and my < y + h do
      false -> false
      true -> {mx - x, my - y}
    end
  end
end
