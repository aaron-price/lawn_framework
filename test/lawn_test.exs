defmodule LawnTest do
  use ExUnit.Case
  doctest Lawn

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
    li = Lawn.db_to_list(l)


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
    assert foo8 == %{foo: 8}

    #assert Enum.slice(li, 0..1) == Enum.slice(l, 0..1)

    #queried = Enum.filter(l, fn
    #  ({_table, 1, _}) -> true
    #  (_) -> false
    #end)

    #assert queried == [
    #  {:user, 1, %{foo: 123}},
    #]
  end

end
