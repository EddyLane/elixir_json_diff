defmodule JSONDiff do
  @moduledoc ~S"""
  JSONDiff is an Elixir implementation of the diffing element of the JSON Patch format,
  described in [RFC 6902](http://tools.ietf.org/html/rfc6902).

  This library only handles diffing. For patching, see the wonderful [JSONPatch library](https://github.com/gamache/json_patch_elixir).

  This library only supports add, replace and remove operations.

  It is based on the very fast JavaScript library [JSON-Patch](https://github.com/Starcounter-Jack/JSON-Patch)

  ## Examples
      iex> JSONDiff.diff(%{"a" => 1}, %{"a" => 2})
      [%{"op" => "replace", "path" => "/a", "value" => 2}]
      iex> JSONDiff.diff([1], [2])
      [%{"op" => "replace", "path" => "/0", "value" => 2}]

  ## Installation
      # mix.exs
      def deps do
        [
          {:json_diff, "~> 0.1.0"}
        ]
      end
  """

  def diff(old, new, patches \\ [], path \\ "") do
    {deleted, patches, old_keys} = patches_for_old(old, new, patches, path)
    new_keys = list_or_map_keys_or_indexes(new)

    unless deleted or length(new_keys) != length(old_keys) do
      patches
    end

    Enum.reduce(new_keys, patches, fn key, patches ->
      if !has_key_or_index?(old, key) do
        add_patch(patches, patch(:add, path, key, item(new, key)))
      else
        patches
      end
    end)
  end

  @doc false
  defp patches_for_old(old, new, patches, path) do
    old_keys =
      list_or_map_keys_or_indexes(old)
      |> Enum.reverse()

    {deleted, patches} = Enum.reduce(old_keys, {false, patches}, old_key_reducer(old, new, path))

    {deleted, patches, old_keys}
  end

  @doc false
  defp old_key_reducer(old, new, path) do
    fn key, {deleted, patches} ->
      old_val = item(old, key)

      case has_key_or_index?(new, key) do
        # The key for the old exists in the new
        true ->
          new_val = item(new, key)

          cond do
            # Both are maps or lists, so we need to recurse to check the child values
            map_or_list?(old_val) and map_or_list?(new_val) ->
              child_patches =
                diff(
                  old_val,
                  new_val,
                  [],
                  path_component(path, key)
                )

              patches = add_patch(patches, child_patches)
              {deleted || false, patches}

            # No changes, do nothing
            new_val === old_val ->
              {deleted || false, patches}

            # Changes, replace old value with new value
            true ->
              patches = add_patch(patches, patch(:replace, path, key, new_val))
              {deleted || false, patches}
          end

        # The key for the old does not exist in the new
        false ->
          patches = add_patch(patches, patch(:remove, path, key))
          {true, patches}
      end
    end
  end

  @doc false
  defp add_patch(patches, new_patches) when is_list(new_patches), do: patches ++ new_patches
  defp add_patch(patches, new_patch), do: patches ++ [new_patch]

  @doc false
  defp has_key_or_index?(map, key) when is_map(map) and is_binary(key) do
    Map.has_key?(map, key)
  end

  defp has_key_or_index?(list, index) when is_list(list) and is_integer(index) do
    Enum.at(list, index) != nil
  end

  defp has_key_or_index?(_, _), do: false

  @doc false
  defp patch(:add, path, key, val) do
    %{
      "op" => "add",
      "path" => path_component(path, key),
      "value" => val
    }
  end

  defp patch(:replace, path, key, val) do
    %{
      "op" => "replace",
      "path" => path_component(path, key),
      "value" => val
    }
  end

  defp patch(:remove, path, key) do
    %{
      "op" => "remove",
      "path" => path_component(path, key)
    }
  end

  @doc false
  defp path_component(path, key), do: path <> "/" <> escape_path_component(key)

  @doc false
  defp list_or_map_keys_or_indexes(map) when is_map(map), do: Map.keys(map)

  defp list_or_map_keys_or_indexes(list) when is_list(list) do
    0..(length(list) - 1)
    |> Enum.to_list()
  end

  @doc false
  defp map_or_list?(a) when is_list(a) or is_map(a), do: true
  defp map_or_list?(_), do: false

  @doc false
  defp item(enum, key) when is_map(enum), do: Map.fetch!(enum, key)
  defp item(enum, index) when is_list(enum), do: Enum.fetch!(enum, index)

  @doc false
  def escape_path_component(path) when is_integer(path) do
    path
    |> to_string()
    |> escape_path_component()
  end

  def escape_path_component(path) when is_binary(path) do
    case {:binary.match(path, "/"), :binary.match(path, "~")} do
      {:nomatch, :nomatch} ->
        path

      _ ->
        path = Regex.replace(~r/~/, path, "~0")
        Regex.replace(~r/\//, path, "~1")
    end
  end
end