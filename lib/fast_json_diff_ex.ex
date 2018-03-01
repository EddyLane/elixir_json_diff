defmodule FastJsonDiffEx do
  def generate(old, new, patches \\ [], path \\ "") do
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

  defp patches_for_old(old, new, patches, path) do
    old_keys =
      list_or_map_keys_or_indexes(old)
      |> Enum.reverse()

    {deleted, patches} = Enum.reduce(old_keys, {false, patches}, old_key_reducer(old, new, path))

    {deleted, patches, old_keys}
  end

  defp old_key_reducer(old, new, path) do
    fn key, {deleted, patches} ->
      old_val = item(old, key)

      case has_key_or_index?(new, key) do
        true ->
          new_val = item(new, key)

          cond do
            map_or_list?(old_val) and map_or_list?(new_val) ->
              child_patches =
                generate(
                  old_val,
                  new_val,
                  [],
                  path_component(path, key)
                )

              {deleted || false, add_patch(patches, child_patches)}

            new_val === old_val ->
              {deleted || false, patches}

            true ->
              # Replace value
              {deleted || false, add_patch(patches, patch(:replace, path, key, new_val))}
          end

        false ->
          # Remove value
          {true, add_patch(patches, patch(:remove, path, key))}
      end
    end
  end

  defp add_patch(patches, new_patches) when is_list(new_patches), do: patches ++ new_patches
  defp add_patch(patches, new_patch), do: patches ++ [new_patch]

  defp has_key_or_index?(map, key) when is_map(map) and is_binary(key) do
    Map.has_key?(map, key)
  end

  defp has_key_or_index?(list, index) when is_list(list) and is_integer(index) do
    Enum.at(list, index) != nil
  end

  defp has_key_or_index?(_, _), do: false

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

  defp path_component(path, key), do: path <> "/" <> escape_path_component(key)

  defp list_or_map_keys_or_indexes(map) when is_map(map), do: Map.keys(map)

  defp list_or_map_keys_or_indexes(list) when is_list(list) do
    0..(length(list) - 1)
    |> Enum.to_list()
  end

  defp map_or_list?(a) when is_list(a) or is_map(a), do: true
  defp map_or_list?(_), do: false

  defp item(enum, key) when is_map(enum), do: Map.fetch!(enum, key)
  defp item(enum, index) when is_list(enum), do: Enum.fetch!(enum, index)

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