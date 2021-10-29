defmodule Lawn.Interceptors do
  @db Lawn.Db.db()
  #@default_lawn Lawn.new(@db)


  def get_wage(%Lawn{current: %{user: uid}} = lawn), do: Map.get(@db.wage, Lawn.query(lawn, [:user, uid, :position]))

  def payday(%Lawn{current: %{user: uid}} = lawn, _chain) do
    Lawn.mutate(lawn, :update, [:user, uid, :cash], fn cash -> cash + get_wage(lawn) end)
  end

  def dec_happiness(%Lawn{current: %{user: _uid, dog: did}} = lawn, _chain) do
    Lawn.mutate(lawn, :update, [:dog, did, :happiness], fn s -> s - 1 end)
  end
  def inc_speed(%Lawn{current: %{user: _uid, dog: did}} = lawn, _chain) do
    Lawn.mutate(lawn, :update, [:dog, did, :speed], fn s -> s + 1 end)
  end
  def get_hungry(%Lawn{current: %{user: _uid, dog: did}} = lawn, _chain) do
    Lawn.mutate(lawn, :update, [:dog, did, :hunger], fn x -> x + 1 end)
  end
  def inc_energy(%Lawn{current: %{user: _uid, dog: did}} = lawn, _chain) do
    Lawn.mutate(lawn, :update, [:dog, did, :energy], fn x -> x + 10 end)
  end
  def dec_energy(%Lawn{current: %{user: _uid, dog: did}} = lawn, _chain) do
    Lawn.mutate(lawn, :update, [:dog, did, :energy], fn x -> x - 5 end)
  end
  def eat_food(%Lawn{current: %{user: uid, dog: did}} = lawn, _chain) do
    {inv_id, _inventory} = Enum.find(@db.inventory, fn {_, %{user_id: owner_id}} -> owner_id == uid end)
    lawn
    |> Lawn.mutate(:update, [:dog, did, :hunger], fn x -> x - 10 end)
    |> Lawn.mutate(:update, [:inventory, inv_id, :amount], fn x -> x - 1 end)
  end
  def buy_item(%Lawn{current: %{user: uid, item: iid}} = lawn, _c) do
    item = @db.item[iid]
    lawn
    |> Lawn.mutate(:update, [:user, uid, :cash], fn x -> x - item.cash end)
  end


  # Trying every combination. Let the tedium begin!
  def cont_reset_lawn(%Lawn{current: %{user: _uid, dog: did}} = lawn, _chain) do
    l = Lawn.mutate(lawn, :update, [:dog, did, :energy], fn x -> x - 5 end)
    {:cont, :reset, l}
  end

  def cont_keep_lawn(%Lawn{current: %{user: _uid, dog: did}} = lawn, _chain) do
    l = Lawn.mutate(lawn, :update, [:dog, did, :energy], fn x -> x - 5 end)
    {:cont, :keep, l}
  end

  def halt_reset_lawn(%Lawn{current: %{user: _uid, dog: did}} = lawn, _chain) do
    l = Lawn.mutate(lawn, :update, [:dog, did, :energy], fn x -> x - 5 end)
    {:halt, :reset, l}
  end

  def halt_keep_lawn(%Lawn{current: %{user: _uid, dog: did}} = lawn, _chain) do
    l = Lawn.mutate(lawn, :update, [:dog, did, :energy], fn x -> x - 5 end)
    {:halt, :keep, l}
  end

  def cont_keep_chain(%Lawn{current: %{user: _uid, dog: _did}} = _lawn, _chain) do
    c = %Lawn.Chain{interceptors: [&__MODULE__.dec_happiness/2]}
    {:cont, :keep, c}
  end

  def cont_reset_chain(%Lawn{current: %{user: _uid, dog: _did}} = _lawn, _chain) do
    c = %Lawn.Chain{interceptors: [&__MODULE__.dec_happiness/2]}
    {:cont, :reset, c}
  end

  def halt_keep_chain(%Lawn{current: %{user: _uid, dog: _did}} = _lawn, _chain) do
    c = %Lawn.Chain{interceptors: [&__MODULE__.dec_happiness/2]}
    {:halt, :keep, c}
  end

  def halt_reset_chain(%Lawn{current: %{user: _uid, dog: _did}} = _lawn, _chain) do
    c = %Lawn.Chain{interceptors: [&__MODULE__.dec_happiness/2]}
    {:halt, :reset, c}
  end


  def cont_keep_li(%Lawn{current: %{user: _uid, dog: _did}} = _lawn, _chain) do
    li = [&__MODULE__.dec_happiness/2]
    {:cont, :keep, li}
  end

  def halt_keep_li(%Lawn{current: %{user: _uid, dog: _did}} = _lawn, _chain) do
    li = [&__MODULE__.dec_happiness/2]
    {:halt, :keep, li}
  end

  def cont_reset_li(%Lawn{current: %{user: _uid, dog: _did}} = _lawn, _chain) do
    li = [&__MODULE__.dec_happiness/2]
    {:cont, :reset, li}
  end

  def halt_reset_li(%Lawn{current: %{user: _uid, dog: _did}} = _lawn, _chain) do
    li = [&__MODULE__.dec_happiness/2]
    {:halt, :reset, li}
  end


end
