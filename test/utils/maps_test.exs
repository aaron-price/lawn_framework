defmodule Lawn.Utils.MapsTest do
  use ExUnit.Case
  alias Lawn.User
  alias Lawn.Utils.Maps
  doctest Maps

  @bobs_neighbour %User{
    name: "",
    address: %{
      neighbours: %{left: %{first_name: "Bob"}, right: %{}},
      city: "",
      number: 0
    }
  }
  @bob_path [:address, :neighbours, :left, :first_name]
  @struct %User{}

  test "Arbitrary get_and_update_in_struct" do
    u = @struct
        |> Maps.get_and_update_in_struct(@bob_path, fn _x -> "Bob" end)

    assert u == @bobs_neighbour
  end

  test "Struct put_in" do
    assert @bobs_neighbour == Maps.put_in_p(@struct, @bob_path, "Bob")
  end

  test "Struct get_in" do
    assert "Bob" == Maps.get_in_p(@bobs_neighbour, @bob_path)
  end

  test "Struct update_in" do
    assert "BOB" == Maps.update_in_p(@bobs_neighbour, @bob_path, fn x -> String.upcase(x) end)
                    |> Maps.get_in_p(@bob_path)
  end

  test "Struct delete_in" do
    li = [:a, :b, :c, :d]
    all_but_last = Enum.slice(li, 0..-2)
    assert all_but_last == [:a, :b, :c]
    m = Maps.delete_in_p(@bobs_neighbour, [:address, :neighbours, :left, :first_name])
    assert Maps.get_in_p(m, [:address, :neighbours, :left, :first_name]) == nil
    assert Maps.get_in_p(m, [:address, :neighbours, :left]) == %{}
  end
end
