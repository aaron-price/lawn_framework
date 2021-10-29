defmodule Lawn.User do
  defstruct [
    name: "",
    address: %{
      city: "",
      number: 0,
      neighbours: %{
        left: %{},
        right: %{}
      }
    }
  ]

  def new(map \\ %{}) do
    struct(__MODULE__)
    |> Map.put(:name, Map.get(map, :name))
    |> Map.put(:address, Map.get(map, :address))
  end


end
