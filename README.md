# LawnFramework
There are several problems I hope to solve with this lib:

- Problem 1: The shape of the data in my App is not consistent across controllers/pages/etc.
- Problem 2: The shape of my DB doesn't match how I use data in my App.
- Problem 3: It's too hard to make a complex, branching pipeline of data transformations, in a safe, 'functional' way.
- Problem 4: Hard to handle errors inside the complex transformation pipelines.

## What is a Lawn?
A struct. %Lawn{}
It has two purposes:
1. Record a *description* of changes you want to make to some data.
2. Store the data before, and after those changes, but store it in a specific shape: %{tablename => %{row_id => %{..row..}}}

## What is a Chain?
A struct. %Lawn.Chain{}
If the lawn represents the data, then the chain is the pipeline of changes.
It contains an :interceptors list, where each 'interceptor' is merely a function that takes a lawn and chain, and returns a new lawn (or other instructions).

## Let's use code examples to understand it
```elixir
# First you create a db map with this shape.
@db %{
  user: %{
    1 => %{name: "Aaron", cash: 100, happiness: 50},
    2 => %{name: "Aaron's Boss", cash: 100000, happiness: 0},
  },
  item_type: %{
    1 => %{name: "Food", price: 10},
    1 => %{name: "Speed Boat", price: 1000},
  }
}

# Now pass it into a new Lawn. Optionally set the :current map with whatever variables you care about
lawn = %Lawn{
  db: @db,
  current: %{user_id: 1}
}

# You can query the data, kind of like Kernel.get_in
assert Lawn.query(lawn, [:user, 1, cash: 100])

# It also implements enumerable, passing in {table, id, row} to the callback functions
aaron = Enum.find(lawn, fn
  ({:user, _id, %{name: "Aaron"}}) -> true 
  (_) -> false
end) 



# Here are some examples of interceptors
# Remember, they are just functions with the contract: (%Lawn{}, %Chain{}) :: %Lawn{} | command_tuple
# Their purpose is to be a single piece of your data transformation pipeline.

def set_happiness_100_interceptor(%{db: _db, current: %{user_id: uid}} = lawn, _chain) do
  # Lawn.mutate returns a new lawn after setting the changes like with Kernel.put_in
  # The difference is that it ALSO permanently records the original lawn so we can roll back to it, 
  # It does a bit more behind the scenes that we'll get to later.
  Lawn.mutate(lawn, :put, [:user, uid, :happiness], 100)
end

# What if you don't want to hard code the value? You can do a lot more than :put.
# There's also :update, :delete, :merge, and :create
def buy_food_interceptor(%{db: db, current: %{user_id: uid}} = lawn, _chain) do
  # First, we find the food item
  {_, food} = Enum.find(db.item_type, fn {_id, item} -> item.name == "Food" end)

  # And the rest is just like update_in.
  Lawn.mutate(lawn, :update, [:user, uid, :cash], fn c -> c - food.price)
end

# A %Chain{} is a struct that contains a list of interceptors
chain = %Lawn.Chain{interceptors: [
  &buy_food_interceptor/2,
  &set_happiness_100_interceptor/2,
]}

# We query the lawn before applying changes
assert Lawn.query(lawn, [:user, 1, :cash]) == 100
assert Lawn.query(lawn, [:user, 1, :happiness]) == 50

# Get a new lawn with the changes
new_lawn = Chain.process_chain(lawn, chain, %{})

# And sure enough they have been applied
assert Lawn.query(new_lawn, [:user, 1, :cash]) == 90
assert Lawn.query(new_lawn, [:user, 1, :happiness]) == 100

# But the original is still there if you look for it.
assert Lawn.query(new_lawn.pre_db, [:user, 1, :cash]) == 100



# So what if you want to apply these changes to your real DB?
# We leave it up to you to define that function, but the data you have available should make it easy enough.
new_lawn == %Lawn{
  ...,
  db: #current db,
  pre_db: #what you started with

  # The operations are all here.
  put: %{
    [:user, 1, :happiness] => 100
  },
  update: %{
    [:user, 1, :cash] => #function
  }
}


# Back to interceptors for a moment, what if you want to do more complex, even branching changes? You can!
# Instead of returning a lawn, they just need to return a tuple
#
# The first element is either :halt, or :cont.
# Just like in Enum.reduce_while, :halt can be used to stop the list of interceptors at the current one.
#
# The second element is either :keep, or :reset.
# This determines whether you should toss out the current lawn and start with a new one, or keep all the changes so far.
#
# And the third/final element is either a Lawn, a new Chain to process, or a list of interceptors to process.
# 
# For example, if I want to halt the current chain, and switch to a new one, while keeping the lawn:
def change_direction_interceptor(lawn, _chain) do
  ...
  {:halt, :keep, %Chain{interceptors: [&new_interceptor/2]}}
end
#
#
# You can also set the :status and :message of a lawn. It does nothing here, but I like to use it with phoenix flash messages.
# E.g. if an interceptor just checks some validation which fails, it might return
def validation_interceptor(lawn, _) do
  ...
  lawn
  |> Lawn.put(:message, "That failed!")
  |> Lawn.put(:status, :error)
end
# Don't use Lawn.mutate for that!


# Alright let's play with queries a bit more.
# A very common pattern is to keep 'id' variables in :current.
# e.g. %Lawn{current: %{user_id: 123}, db: %{user: %{123 => user123}}}
# 
# But did you know you can reference the :current variables in a query path?
#
# Lawn.query(lawn, [:user, "@current.user_id", :name]) == "My user name"

```