defmodule Lawn.Db do
  def user, do: %{
    1 => %{id: 1, name: "Bob",        cash: 100,       happiness: 25, position: :worker},
    2 => %{id: 2, name: "Bob's Boss", cash: 1_000_000, happiness: 0,  position: :boss},
    3 => %{id: 3, name: "Alice",      cash: 0,         happiness: 50, position: :unemployed},
  }
  def inventory, do: %{
    1 => %{item_id: 1, amount: 10, user_id: 1},
    2 => %{item_id: 1, amount: 100, user_id: 2},
  }

  def wage, do: %{
    boss: 50,
    worker: 10,
    unemployed: 0
  }

  def items, do: %{
    food:           %{id: 1, cash: 50, happiness: 5},
    lottery_ticket: %{id: 2, cash: 1, happiness: 1},
    speedboat:      %{id: 3, cash: 25000, happiness: 500}
  }
  def dogs, do: %{
    1 => %{id: 1, energy: 100, speed: 1, happiness: 100, owner_id: 1, hunger: 0},
    2 => %{id: 2, energy: 100, speed: 1, happiness: 100, owner_id: 1, hunger: 0},
    3 => %{id: 3, energy: 100, speed: 1, happiness: 100, owner_id: 1, hunger: 0},
    5 => %{id: 4, energy: 100, speed: 1, happiness: 100, owner_id: 2, hunger: 0},
    6 => %{id: 5, energy: 100, speed: 1, happiness: 100, owner_id: 2, hunger: 0},
    7 => %{id: 6, energy: 100, speed: 1, happiness: 100, owner_id: 3, hunger: 0},
  }

  def db, do: %{
    user: user(),
    inventory: inventory(),
    wage: wage(),
    item: items(),
    dog: dogs()
  }
end
