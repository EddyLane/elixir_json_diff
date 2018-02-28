defmodule FastJsonDiffExTest do
  use ExUnit.Case
  doctest FastJsonDiffEx

  import FastJsonDiffEx

  describe "duplex" do
    test "it should generate replace" do
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

      expected = [
        %{
          "op" => "replace",
          "path" => "/phoneNumbers/1/number",
          "value" => "456"
        },
        %{
          "op" => "replace",
          "path" => "/phoneNumbers/0/number",
          "value" => "123"
        },
        %{"op" => "replace", "path" => "/lastName", "value" => "Wester"},
        %{"op" => "replace", "path" => "/firstName", "value" => "Joachim"}
      ]

      assert generate(a, b) == expected
    end
  end
end