defmodule LawnTest do
  use ExUnit.Case
  doctest Lawn

  @bobs_neighbour %Lawn.User{
    name: "",
    address: %{
      neighbours: %{left: %{first_name: "Bob"}, right: %{}},
      city: "",
      number: 0
    }
  }

  test "Lawn Struct Setup" do
    l = Lawn.new(%{
      user: %{5 => %{foo: 8}, 1 => %{foo: 123}},
      post: %{26 => %{owner_id: 1, body: "Hello"}}
    })

    assert l == %Lawn{
      db: %{post: %{26 => %{body: "Hello", owner_id: 1}}, user: %{1 => %{foo: 123}, 5 => %{foo: 8}}},
    }

    li = Lawn.db_to_list(l)


    assert li == [
      {:user, 1, %{foo: 123}},
      {:user, 5, %{foo: 8}},
      {:post, 26, %{body: "Hello", owner_id: 1}},
    ]

    assert l.db == Lawn.list_to_db(li)
  end


  test "Implementing Enumerable in %Lawn{}" do
    l = Lawn.new(%{
      user: %{
        1 => %{foo: 123},
        5 => %{foo: 8},
      },
      post: %{26 => %{owner_id: 1, body: "Hello"}}
    })
    #li = Lawn.db_to_list(l)


    #assert Enum.count(l) == 3
    #assert Enum.member?(l, {:user, 1}) == true
    #assert Enum.member?(l, {:bats, 1}) == false
    #assert Enum.member?(l, {:user, 1, %{boop: 5}}) == false
    #assert Enum.member?(l, {:user, 1, %{foo: 123}}) == true

    #assert Enum.slice(l, 0..1) == [
    #  {:user, 1, %{foo: 123}},
    #  {:user, 5, %{foo: 8}}
    #]
    foo8 = Enum.find(l, fn
      ({:user, _, %{foo: 8}}) -> true
      (_) -> false
    end)
    assert foo8 == {:user, 5, %{foo: 8}}

  end

  test "Lawn diffs" do
    l = %Lawn{
      db: %{
        user: %{
          1 => %{foo: 123},
          5 => %{foo: 8},
          8 => @bobs_neighbour
        },
        post: %{26 => %{owner_id: 1, body: "Hello"}}
      },
      pre_db: %{
        user: %{
          1 => %{foo: 23},
          5 => %{foo: 8},
          77 => %{foo: 77}
        },
        post: %{26 => %{owner_id: 1, body: "Hello"}}
      }
    }
    assert Lawn.Utils.Maps.diff(l) == %{user: %{1 => %{foo: 100}}}
    #assert 123 == Enum.map(l, fn {_t, _id, row} -> row end)

  end

end
