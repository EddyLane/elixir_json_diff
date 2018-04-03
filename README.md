# JSONDiff

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
        {:json_diff, "~> 0.1.2"}
      ]
    end

## Authorship and License

JSONDiff is released under the MIT License, available at LICENSE.txt.
