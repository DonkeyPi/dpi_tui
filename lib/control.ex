defmodule Ash.Tui.Control do
  @callback init(opts :: map()) :: model :: map()
  @callback handle(model :: map(), event :: any()) :: {model :: map(), cmd :: any()}
  @callback render(model :: map(), canvas :: map(), theme :: function()) :: canvas :: map()
  @callback bounds(model :: map()) :: {integer(), integer(), integer(), integer()}
  @callback visible(model :: map()) :: true | false
  @callback update(model :: map(), Keyword.t()) :: any()
  # bypassed by non input controls like nil, label, and frame
  @callback focusable(model :: map()) :: true | false
  @callback focused(model :: map(), true | false) :: model :: map()
  @callback focused(model :: map()) :: true | false
  @callback findex(model :: map()) :: integer()
  # only used by button, ignored by all other controls
  @callback shortcut(model :: map()) :: any()
  # only used by panel, ignored by all other controls
  @callback children(model :: map()) :: Keyword.t()
  @callback children(model :: map(), Keyword.t()) :: any()
  @callback refocus(model :: map(), dir :: any()) :: model :: map()
  @callback modal(model :: map()) :: true | false
  # The init | update mechanism is enough to support enabled control
  # @callback enabled(model :: map()) :: true | false

  def init(module, opts \\ []), do: {module, module.init(opts)}

  def merge(map, props) do
    for {key, value} <- props, reduce: map do
      map ->
        if !Map.has_key?(map, key), do: raise("Invalid prop #{key}: #{inspect(value)}")
        Map.put(map, key, value)
    end
  end

  def coalesce(map, key, value) do
    case {Map.has_key?(map, key), Map.get(map, key)} do
      {true, nil} -> Map.put(map, key, value)
      _ -> map
    end
  end

  def tree({module, model}, ids, map \\ %{}) do
    map =
      for {id, momo} <- module.children(model), reduce: map do
        map -> tree(momo, [id | ids], map)
      end

    Map.put(map, ids, {module, model})
  end
end
