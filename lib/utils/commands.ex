defmodule Lawn.Utils.Commands do
  alias Lawn.Utils.Maps


  def mutate(%Lawn{db: db, pre_db: pre} = lawn, :put, path, v) do
    path = Lawn.Utils.Placeholders.replace_currents(lawn, path)
    lawn
    |> Map.put(:pre_db, if(is_nil(pre), do: db, else: pre))
    |> Maps.put_in_p([:put, path], v)
    |> Maps.put_in_p([:db | path], v)
  end

  def mutate(%Lawn{db: db, pre_db: pre} = lawn, :update, path, cb) do
    path = Lawn.Utils.Placeholders.replace_currents(lawn, path)
    v = Maps.get_in_p(lawn, [:db | path]) |> cb.()
    lawn
    |> Map.put(:pre_db, if(is_nil(pre), do: db, else: pre))
    |> Maps.put_in_p([:update, path], cb)
    |> Maps.put_in_p([:db | path], v)
  end


  def mutate(%Lawn{db: db, pre_db: pre} = lawn, :merge, path, map) do
    path = Lawn.Utils.Placeholders.replace_currents(lawn, path)
    new_map = Maps.get_in_p(lawn, [:db | path]) |> Maps.deep_merge(map)
    lawn
    |> Map.put(:pre_db, if(is_nil(pre), do: db, else: pre))
    |> Maps.put_in_p([:db | path], new_map)
    |> Maps.put_in_p([:merge, path], map)
  end


  def mutate(%Lawn{db: db, pre_db: pre} = lawn, :create, path, map) do
    path = Lawn.Utils.Placeholders.replace_currents(lawn, path)
    lawn
    |> Map.put(:pre_db, if(is_nil(pre), do: db, else: pre))
    |> Maps.put_in_p([:db | path], map)
    |> Maps.put_in_p([:create, path], map)
  end


  def mutate(%Lawn{db: db, pre_db: pre, delete: dels} = lawn, :delete, path) do
    path = Lawn.Utils.Placeholders.replace_currents(lawn, path)
    new_dels = [path | dels]
    new_db = Maps.delete_in_p(lawn, [:db | path]).db

    lawn
    |> Map.put(:pre_db, if(is_nil(pre), do: db, else: pre))
    |> Maps.put_in_p([:delete], new_dels)
    |> Maps.put_in_p([:db], new_db)
  end


  def query(lawn, path, endpoint \\ :db)
  def query(lawn, path, endpoint) do
    path = Lawn.Utils.Placeholders.replace_currents(lawn, path)
    db = Map.get(lawn, endpoint) || %{}
    query_step(path, db)
  end


  def query_step([], value), do: value
  def query_step([hd | tl], map) do
    value = cond do
      is_atom(hd) -> Maps.get_in_p(map, [hd])
      is_number(hd) -> Maps.get_in_p(map, [hd])
      is_binary(hd) -> Maps.get_in_p(map, [hd])
      is_function(hd) ->
        Enum.reduce(map, [], fn ({id, v}, acc) ->
          if hd.({id, v}) do
            [query_step(tl, v) | acc]
          else
            acc
          end
        end)
      true -> nil
    end

    cond do
      is_map(value) and !Enum.empty?(tl) -> query_step(tl, value)
      true -> value
    end
  end


end
