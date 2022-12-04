defmodule Ash.Tui.Control do
  @callback init(opts :: map()) :: state :: map()
  @callback handle(state :: map(), event :: any()) :: {state :: map(), cmd :: any()}
  @callback render(state :: map(), canvas :: map()) :: canvas :: map()
  @callback bounds(state :: map()) :: {integer(), integer(), integer(), integer()}
  @callback visible(state :: map()) :: true | false
  @callback update(state :: map(), Keyword.t()) :: any()
  # bypassed by non input controls like nil, label, and frame
  @callback focusable(state :: map()) :: true | false
  @callback focused(state :: map(), true | false) :: state :: map()
  @callback focused(state :: map()) :: true | false
  @callback findex(state :: map()) :: integer()
  # only used by button, ignored by all other controls
  @callback shortcut(state :: map()) :: any()
  # only used by panel, ignored by all other controls
  @callback children(state :: map()) :: Keyword.t()
  @callback children(state :: map(), Keyword.t()) :: any()
  @callback refocus(state :: map(), dir :: any()) :: state :: map()
  @callback modal(state :: map()) :: true | false
  # The init | update mechanism is enough to support enabled control
  # @callback enabled(state :: map()) :: true | false

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

  def tree({module, state}, keys, map \\ %{}) do
    map =
      for {key, mote} <- module.children(state), reduce: map do
        map -> tree(mote, [key | keys], map)
      end

    Map.put(map, keys, {module, state})
  end
end
