defmodule Lawn.Chains do
  alias Lawn.Interceptors, as: I

  def rest, do: %Lawn.Chain{
    interceptors: [
      &I.eat_food/2,
      &I.inc_energy/2
    ]
  }

  def train_speed, do: %Lawn.Chain{
    interceptors: [
      &I.get_hungry/2,
      &I.inc_speed/2,
      &I.dec_energy/2,
    ]
  }
end
