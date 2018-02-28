defmodule FastJsonDiffEx do
  def generate(old, new, patches \\ [], path \\ "") do
    IO.puts("GENERATE:")
    IO.inspect({old, new})
    IO.inspect(patches)
    IO.inspect(path)

    {has_deleted, patches} =
      Enum.reduce(old, {false, patches}, fn {key, old_val}, {deleted, patches} ->
        if is_list(new) do
          patch = %{
            "op" => "remove",
            "path" => path <> "/" <> escape_path_component(key)
          }

          {true, patches ++ [patch]}
        else
          new_val = Map.fetch!(new, key)

          if (is_map(old_val) || is_list(old_val)) && (is_map(new_val) || is_list(new_val)) do
            child_patches =
              generate(
                old_val,
                new_val,
                patches,
                path <> "/" <> escape_path_component(key)
              )

            {deleted || false, patches ++ child_patches}
          else
            IO.puts("WOW")
            IO.inspect(old_val)
            IO.inspect(new_val)

            patch = %{
              "op" => "replace",
              "path" => path <> "/" <> escape_path_component(key),
              "value" => new_val
            }

            {deleted || false, patches ++ [patch]}
          end
        end
      end)

    if !has_deleted && length(Map.keys(new)) == length(Map.keys(old)) do
      patches
    end

    patches
  end

  defp escape_path_component(path) do
    match_first = :binary.match(path, "/")
    match_second = :binary.match(path, "~")

    case {match_first, match_second} do
      {:nomatch, :nomatch} ->
        path = Regex.replace(~r/~/, path, "~0")
        Regex.replace(~r/\//, path, "~1")

      _ ->
        path
    end
  end

  def test() do
    # a = %{"hello" => "world"}
    # b = %{"hello" => "world2"}

    a = %{"hello" => ["w", "o", "rld"]}
    b = %{"hello" => ["w", "o", "rld2"]}

    compared = generate(a, b)
    IO.inspect(compared)
  end
end