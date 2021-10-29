defmodule Lawn.Utils.QueryTest do
  use ExUnit.Case
  alias Lawn.Db
  import Lawn.Utils.Placeholders

  setup do
    %{lawn: Lawn.new(Db.db())}
  end

  describe "Lawn.query" do

    test "Establish the basics", %{lawn: lawn} do
      assert Lawn.query(lawn, [:dog, 1, :energy]) == 100
      assert Lawn.query(lawn, [:dog]) |> Map.keys() == [1, 2, 3, 5, 6, 7]
      assert Lawn.query(lawn, [:dog, (fn {id, _dog} -> id in [2, 3] end), :id ]) == [3, 2]
      assert Lawn.query(lawn, [:dog, (fn {id, _dog} -> id == 2 end), :energy ]) == [100]
    end

    test "current shortcut", %{lawn: lawn} do
      assert Lawn.query(lawn, [:dog, 1, :energy]) == 100
      assert Lawn.query(lawn, [:dog, "@current.dog_id", :energy]) == nil

      assert replace_currents(lawn, [:dog, "@current.dog_id"]) == [:dog, nil]
      lawn = Map.put(lawn, :current, %{dog_id: 1})
      assert replace_currents(lawn, [:dog, "@current.dog_id"]) == [:dog, 1]


      assert replace_currents(lawn, [:dog, "@current.dog_id", :energy]) == [:dog, 1, :energy]
      assert Lawn.query(lawn, [:dog, "@current.dog_id", :energy]) == 100
    end


  end
end
