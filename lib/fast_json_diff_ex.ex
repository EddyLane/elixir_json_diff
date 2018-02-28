defmodule FastJsonDiffEx do
  def generate(old, new, patches \\ [], path \\ "") do
    new_keys = list_or_map_keys_or_indexes(new)

    old_keys =
      list_or_map_keys_or_indexes(old)
      |> Enum.reverse()

    {deleted, patches} =
      Enum.reduce(old_keys, {false, patches}, fn key, {deleted, patches} ->
        IO.inspect(key)

        old_val = item(old, key)

        if has_key_or_index?(new, key) do
          new_val = item(new, key)

          if map_or_list?(old_val) and map_or_list?(new_val) do
            child_patches =
              generate(
                old_val,
                new_val,
                patches,
                path <> "/" <> escape_path_component(key)
              )

            {deleted || false, patches ++ child_patches}
          else
            if new_val !== old_val do
              {deleted || false, patches ++ [patch(:replace, path, key, new_val)]}
            else
              {deleted || false, patches}
            end
          end
        else
          {true, patches ++ [patch(:remove, path, key)]}
        end
      end)

    if !deleted and length(new_keys) == length(old_keys) do
      patches
    end

    Enum.reduce(new_keys, patches, fn key, patches ->
      if !has_key_or_index?(old, key) do
        patches ++ [patch(:add, path, key, item(new, key))]
      else
        patches
      end
    end)
  end

  defp has_key_or_index?(map, key) when is_map(map) and is_binary(key) do
    Map.has_key?(map, key)
  end

  defp has_key_or_index?(list, index) when is_list(list) and is_integer(index) do
    case Enum.at(list, index) do
      nil -> false
      _ -> true
    end
  end

  defp has_key_or_index?(_, _), do: false

  defp patch(:add, path, key, val) do
    %{
      "op" => "add",
      "path" => path <> "/" <> escape_path_component(key),
      "value" => val
    }
  end

  defp patch(:replace, path, key, val) do
    %{
      "op" => "replace",
      "path" => path <> "/" <> escape_path_component(key),
      "value" => val
    }
  end

  defp patch(:remove, path, key) do
    %{
      "op" => "remove",
      "path" => path <> "/" <> escape_path_component(key)
    }
  end

  defp list_or_map_keys_or_indexes(map) when is_map(map), do: Map.keys(map)

  defp list_or_map_keys_or_indexes(list) when is_list(list) do
    0..(length(list) - 1)
    |> Enum.to_list()
  end

  defp map_or_list?(a) when is_list(a) or is_map(a), do: true
  defp map_or_list?(_), do: false

  defp item(enum, key) when is_map(enum), do: Map.fetch!(enum, key)
  defp item(enum, index) when is_list(enum), do: Enum.fetch!(enum, index)

  defp escape_path_component(path) when is_integer(path) do
    path
    |> to_string()
    |> escape_path_component()
  end

  defp escape_path_component(path) when is_binary(path) do
    case {:binary.match(path, "/"), :binary.match(path, "~")} do
      {:nomatch, :nomatch} ->
        path = Regex.replace(~r/~/, path, "~0")
        Regex.replace(~r/\//, path, "~1")

      _ ->
        path
    end
  end

  def test() do
    a = %{
      "firstName" => "Albert",
      "lastName" => "Einstein",
      "phoneNumbers" => [
        %{"number" => "12345"},
        %{"number" => "45353"}
      ]
    }

    b = %{
      "firstName" => "Joachim",
      "lastName" => "Wester",
      "phoneNumbers" => [
        %{"number" => "123"},
        %{"number" => "456"}
      ]
    }

    generate(a, b)
  end
end