defmodule Lawn do
  import Lawn.Utils.Maps
  alias Lawn.Utils.Commands

  @doc """
  merges is a list of db maps
  updates is a list of tuples like {path, function}
  puts is a list of tuples like {path, value}
  deletes is a list of paths
  creates is a list of tuples like {changeset, tablename}

  Note that :creates cannot be resolved without inserting it into the db.
  We have no :id at this point so it cannot work.
  """
  defstruct [
    current: %{}, # For quick access to simple variables like current_user_id,
    db: %{},      # The meat of every lawn.
    pre_db: nil,  # After making changes to a lawn, you can always find the original db here.
    put: %{},
    merge: %{},
    update: %{},
    create: %{},
    delete: [],
    message: "",  # End-user-friendly message to display
    status: :ok  # if you like pattern matching on (:ok | :error) here it is.
  ]

  def new(map \\ %{}) do
    struct(__MODULE__)
    |> Map.put(:db, map)
  end

  def merge_lawns(li), do: deep_merge(li)
  def merge_lawns(left, right), do: deep_merge(left, right)

  def db_to_list(lawn) do
    Enum.reduce(lawn.db, [], fn ({table, rows}, acc) ->
      Enum.map(rows, fn ({id, row}) -> {table, id, row} end)
      |> Enum.concat(acc)
    end)
  end

  def list_to_db(db_list) do
    Enum.reduce(db_list, %{}, fn ({table, id, row}, acc) ->
      puts_in(acc, [table, id], row)
    end)
  end

  def list_of_maps_to_lawn(li, tablename) do
    table = Enum.reduce(li, %{}, fn (%{id: id} = item, acc) -> Map.put(acc, id, item) end)
    Map.put(%{}, tablename, table)
    |> Lawn.new()
  end


  @doc """
    mutate(%Lawn{}, (:put | :update | :merge | delete), List.t()) :: %Lawn{}
    mutate(%Lawn{}, (:put | :update | :merge | delete), List.t(), (value | fun)) %Lawn{}
  """
  def mutate(lawn, cmd, path), do: Commands.mutate(lawn, cmd, path)
  def mutate(lawn, cmd, path, v), do: Commands.mutate(lawn, cmd, path, v)


  @doc """
    query(%Lawn{}, List.t(), endpoint \\ :db)
  """
  def query(lawn, path, endpoint \\ :db), do: Commands.query(lawn, path, endpoint)



  #############################
  ## Implementing Enumerable ##
  defimpl Enumerable, for: __MODULE__ do
    def count(map) do
      n = Enum.reduce(map.db, 0, fn ({_tablename, table}, acc) ->
        Enum.count(table) + acc
      end)
      {:ok, n}
    end

    def member?(map, {key, value}) do
      cond do
        !Map.has_key?(map.db, key) -> {:ok, false}
        !Map.has_key?(map.db[key], value) -> {:ok, false}
        true -> {:ok, true}
      end
    end
    def member?(map, {tablename, id, row}) do
      cond do
        !Map.has_key?(map.db, tablename) -> {:ok, false}
        !Map.has_key?(map.db[tablename], id) -> {:ok, false}
        !match?(^row, map.db[tablename][id]) -> {:ok, false}
        true -> {:ok, true}
      end
    end
    def member?(_map, _other) do
      {:ok, false}
    end

    def slice(lawn) do
      li = Lawn.db_to_list(lawn)
      size = Enum.count(li)
      {:ok, size, &Enumerable.List.slice(li, &1, &2, size)}
    end

    def reduce(lawn, acc, fun) do
      case Enumerable.List.reduce(Lawn.db_to_list(lawn), acc, fun) do

        {status, li} when is_list(li) -> {status, Lawn.list_to_db(li) |> elem(2)}

        {status, {_table, _id, item}} -> {status, item}

        x -> x

      end
    end
  end
  ## Done Implementing Enumerable ##
  ##################################



  ##################################
  ## Implement Access ##
  @behaviour Access

  def fetch(term, key) do
    Map.fetch(term, key)
  end

  def get_and_update(data, key, function) do
    Map.get_and_update(data, key, function)
  end

  def pop(data, key) do
    Map.pop(data, key)
  end
  ## Done Implementing Access ##
  ##################################

end
