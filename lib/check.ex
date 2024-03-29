defmodule Dpi.Tui.Check do
  def assert_string(name, value) do
    if !is_binary(value), do: raise("#{name} not string: #{inspect(value)}")
  end

  def assert_boolean(name, value) do
    if !is_boolean(value), do: raise("#{name} not boolean: #{inspect(value)}")
  end

  def assert_atom(name, value) do
    if !is_atom(value), do: raise("#{name} not atom: #{inspect(value)}")
  end

  def assert_integer(name, value) do
    if !is_integer(value), do: raise("#{name} not integer: #{inspect(value)}")
  end

  def assert_function(name, value, arity) do
    if !is_function(value), do: raise("#{name} not function: #{inspect(value)}")
    {:arity, value} = Function.info(value, :arity)
    if value != arity, do: raise("#{name} not arity #{arity}: #{inspect(value)}")
  end

  def assert_map(name, value) do
    if !is_map(value), do: raise("#{name} not map: #{inspect(value)}")
  end

  def assert_list(name, value) do
    if !is_list(value), do: raise("#{name} not list: #{inspect(value)}")
  end

  def assert_in_list(name, value, list) do
    case Enum.find_index(list, fn e -> e == value end) do
      nil -> raise("#{name} not in #{inspect(list)}: #{inspect(value)}")
      _ -> nil
    end
  end

  def assert_is_key(name, value, map) do
    case Map.has_key?(map, value) do
      false -> raise("#{name} not key of #{inspect(map)}: #{inspect(value)}")
      _ -> nil
    end
  end

  def assert_in_range(name, value, range) do
    if !(value in range), do: raise("#{name} not in #{inspect(range)}: #{inspect(value)}")
  end

  def assert_point_2d(name, value) do
    case value do
      {x, y} when is_integer(x) and is_integer(y) -> nil
      _ -> raise("#{name} not {integer, integer}: #{inspect(value)}")
    end
  end

  def assert_color(name, value) do
    case value do
      {r, g, b} when r in 0..255 and g in 0..255 and b in 0..255 ->
        nil

      c when c in 0..255 ->
        nil

      _ ->
        raise("#{name} not a valid 0..255 or {0..255, 0..255, 0..255} color: #{inspect(value)}")
    end
  end

  def assert_gte(name, value, limit) do
    if !is_integer(value), do: raise("#{name} not integer: #{inspect(value)}")
    if value < limit, do: raise("#{name} not >= #{limit}: #{inspect(value)}")
  end

  def assert_equal(name, value, expected) do
    if !is_integer(value), do: raise("#{name} not integer: #{inspect(value)}")
    if value != expected, do: raise("#{name} not == #{expected}: #{inspect(value)}")
  end
end
