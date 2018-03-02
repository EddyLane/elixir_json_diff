defmodule JSONDiffTest do
  use ExUnit.Case
  doctest JSONDiff

  import JSONDiff

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

      expected_patches = [
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

      patches = diff(a, b)
      assert patches == expected_patches

      assert {:ok, ^b} = JSONPatch.patch(a, patches)
    end

    test "it should generate replace (escaped chars)" do
      a = %{
        "/name/first" => "Albert",
        "/name/last" => "Einstein",
        "~phone~/numbers" => [
          %{"number" => "12345"},
          %{"number" => "45353"}
        ]
      }

      b = %{
        "/name/first" => "Joachim",
        "/name/last" => "Wester",
        "~phone~/numbers" => [
          %{"number" => "123"},
          %{"number" => "456"}
        ]
      }

      expected_patches = [
        %{
          "op" => "replace",
          "path" => "/~0phone~0~1numbers/1/number",
          "value" => "456"
        },
        %{
          "op" => "replace",
          "path" => "/~0phone~0~1numbers/0/number",
          "value" => "123"
        },
        %{"op" => "replace", "path" => "/~1name~1last", "value" => "Wester"},
        %{"op" => "replace", "path" => "/~1name~1first", "value" => "Joachim"}
      ]

      patches = diff(a, b)

      assert patches == expected_patches
      assert {:ok, ^b} = JSONPatch.patch(a, patches)
    end
  end

  test "it should generate replace (changes in new array cell, primitive values)" do
    a = [1]
    b = [1, 2]

    patches = diff(a, b)

    assert patches == [%{"op" => "add", "path" => "/1", "value" => 2}]
    assert {:ok, ^b} = JSONPatch.patch(a, patches)

    c = [3, 2]

    patches = diff(b, c)
    assert patches == [%{"op" => "replace", "path" => "/0", "value" => 3}]
    assert {:ok, ^c} = JSONPatch.patch(b, patches)

    d = [3, 4]

    patches = diff(c, d)
    assert patches == [%{"op" => "replace", "path" => "/1", "value" => 4}]
    assert {:ok, ^d} = JSONPatch.patch(c, patches)
  end

  test "it should generate replace (changes in new array cell, complex values)" do
    a = [
      %{
        "id" => 1,
        "name" => "Ted"
      }
    ]

    b =
      a ++
        [
          %{
            "id" => 2,
            "name" => "Jerry"
          }
        ]

    patches = diff(a, b)

    assert patches == [
             %{
               "op" => "add",
               "path" => "/1",
               "value" => %{
                 "id" => 2,
                 "name" => "Jerry"
               }
             }
           ]

    assert {:ok, ^b} = JSONPatch.patch(a, patches)
  end

  test "it should generate add" do
    a = %{
      "lastName" => "Einstein",
      "phoneNumbers" => [
        %{"number" => "12345"}
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

    patches = diff(a, b)

    assert patches == [
             %{"op" => "replace", "path" => "/phoneNumbers/0/number", "value" => "123"},
             %{"op" => "add", "path" => "/phoneNumbers/1", "value" => %{"number" => "456"}},
             %{"op" => "replace", "path" => "/lastName", "value" => "Wester"},
             %{"op" => "add", "path" => "/firstName", "value" => "Joachim"}
           ]

    assert {:ok, ^b} = JSONPatch.patch(a, patches)
  end

  test "it should generate remove" do
    a = %{
      "lastName" => "Einstein",
      "firstName" => "Albert",
      "phoneNumbers" => [
        %{"number" => "12345"},
        %{"number" => "4234"}
      ]
    }

    b = %{
      "lastName" => "Wester",
      "phoneNumbers" => [
        %{"number" => "123"}
      ]
    }

    patches = diff(a, b)

    assert patches == [
             %{"op" => "remove", "path" => "/phoneNumbers/1"},
             %{"op" => "replace", "path" => "/phoneNumbers/0/number", "value" => "123"},
             %{"op" => "replace", "path" => "/lastName", "value" => "Wester"},
             %{"op" => "remove", "path" => "/firstName"}
           ]

    assert {:ok, ^b} = JSONPatch.patch(a, patches)
  end

  test "it should generate remove (list indexes should be sorted descending)" do
    a = %{
      "items" => ["a", "b", "c"]
    }

    b = %{
      "items" => ["a"]
    }

    patches = diff(a, b)

    # array indexes must be sorted descending, otherwise there is an index collision in apply
    assert patches == [
             %{"op" => "remove", "path" => "/items/2"},
             %{"op" => "remove", "path" => "/items/1"}
           ]

    assert {:ok, ^b} = JSONPatch.patch(a, patches)
  end
end