defmodule Lawn.Utils.CommandsTest do
  use ExUnit.Case
  alias Lawn.User
  alias Lawn.Utils.Maps
  alias Lawn.Utils.Commands

  @bobs_neighbour %User{
    name: "",
    address: %{
      neighbours: %{left: %{first_name: "Bob"}, right: %{}},
      city: "",
      number: 0
    }
  }
  @bob_path [:user, 1, :address, :neighbours, :left, :first_name]
  @db %{user: %{1 => @bobs_neighbour}}
  @lawn Lawn.new(@db)


  describe "mutate with :put" do

    test "mutate(:put) defines the correct pre_db" do
      assert @lawn.pre_db == nil
      res = Commands.mutate(@lawn, :put, @bob_path, "MISTER BOB")
      assert res.pre_db == @db
    end

    test "mutate(:put) adds an entry in the :put field" do
      assert @lawn.put == %{}
      res = Commands.mutate(@lawn, :put, @bob_path, "MISTER BOB")
      assert res.put == %{[:user, 1, :address, :neighbours, :left, :first_name] => "MISTER BOB"}
    end

    test "mutate(:put) updates the :db fieldi, but not the pre_db" do
      assert @lawn.db.user[1].address.neighbours.left.first_name == "Bob"
      res = Commands.mutate(@lawn, :put, @bob_path, "MISTER BOB")
      assert res.db.user[1].address.neighbours.left.first_name == "MISTER BOB"
      assert res.pre_db.user[1].address.neighbours.left.first_name == "Bob"
    end

  end


  describe "mutate with :update" do

    test "mutate(:update) Applies changes to existing current db" do
      assert @lawn.pre_db == nil
      res = Commands.mutate(@lawn, :update, @bob_path, &String.upcase/1)
      assert res.pre_db == @db
      assert Maps.get_in_p(res, [:db | @bob_path]) == "BOB"
      assert Maps.get_in_p(res, [:pre_db | @bob_path]) == "Bob"
      assert Maps.get_in_p(res, [:update, @bob_path]) == &String.upcase/1
    end

  end


  describe "mutate with :merge" do

    test "mutate(:merge) Applies changes to existing current db" do
      res = Commands.mutate(@lawn, :merge, [:user, 1], %{fav_color: "Green"})
      assert Maps.get_in_p(res, [:db, :user, 1, :fav_color]) == "Green"
      assert Maps.get_in_p(res, [:db, :user, 1, :name]) == ""
      assert Maps.get_in_p(res, [:merge]) == %{
        [:user, 1] => %{fav_color: "Green"}
      }
    end

  end


  describe "mutate with :delete" do

    test "mutate(:delete) removes something at a given path" do
      res = Commands.mutate(@lawn, :delete, @bob_path)

      assert Maps.get_in_p(res, [:db | @bob_path]) == nil
      assert Maps.get_in_p(res, [:delete]) == [ @bob_path ]
    end

  end


  describe "mutate with :create" do

    test "mutate(:create) Create a new entity" do
      res = Commands.mutate(@lawn, :create, [:user, "_id1"], %Lawn.User{name: "My New User"})

      assert Maps.get_in_p(res, [:db, :user, "_id1", :name]) == "My New User"
      assert Maps.get_in_p(res, [:create]) == %{[:user, "_id1"] => %Lawn.User{name: "My New User"}}
    end

  end


  describe "query" do

    test "query default" do
      assert Commands.query(@lawn, @bob_path) == "Bob"

      res = Commands.mutate(@lawn, :put, @bob_path, "MISTER BOB")
      assert Commands.query(res, @bob_path) == "MISTER BOB"

      # Can use a custom endpoint, instead of the usual :db
      assert Commands.query(res, @bob_path, :pre_db) == "Bob"
    end


  end


end
