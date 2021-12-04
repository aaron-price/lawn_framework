defmodule Lawn.Utils.Maps do

  @doc """
  Half the time I'll be working with unknown structs, so implementing Access for everything is unfeasible.
  Instead, I create my own version which works on anything.

  It ALSO assumes everything is a map, when in doubt.
  Much like `mkdir -p` in bash, you can give a path that doesn't exist, and it will create maps all the way down.
  """
  def get_and_update_in_struct(strct, [], _cb), do: strct
  def get_and_update_in_struct(strct, [last_key], cb) do
    old_value = Map.get(strct, last_key)
    Map.put(strct, last_key, cb.(old_value))
  end
  def get_and_update_in_struct(strct, [hd | tl], cb) do
    old_branch = if Map.has_key?(strct, hd), do: Map.get(strct, hd), else: %{}
    new_branch = __MODULE__.get_and_update_in_struct(old_branch, tl, cb)
    Map.put(strct, hd, new_branch)
  end

  @doc """
  Like `mkdir -p` + Kernel.put_in, update_in, and delete_in, but it works on any struct
  """
  def put_in_p(struct, li, v), do: get_and_update_in_struct(struct, li, fn _ -> v end)
  def update_in_p(struct, li, cb), do: get_and_update_in_struct(struct, li, cb)
  def delete_in_p(struct, li) do
    all_but_last = Enum.slice(li, 0..-2)
    last = List.last(li)
    get_and_update_in_struct(struct, all_but_last, fn m ->
      Map.delete(m, last)
    end)
  end

  def get_in_p(end_result, []), do: end_result
  def get_in_p(struct, [hd | tl]) do
    case Map.get(struct, hd) do
      nil -> nil
      x -> get_in_p(x, tl)
    end
  end

  @doc """
  ## Examples
    iex> m1 = %{user: %{1 => %{age: 20, color: :blue}}}
    iex> m2 = %{dog: %{}, user: %{1 => %{age: 21}}}
    iex> Lawn.Utils.Maps.deep_merge(m1, m2)
    %{user: %{1 => %{age: 21, color: :blue}}, dog: %{}}

    iex> m1 = %{user: %{1 => %{age: 20, color: :blue}}}
    iex> m2 = %{dog: %{8 => %{name: "Rover"}}}
    iex> m3 = %{dog: %{}, user: %{1 => %{age: 21}}}
    iex> Lawn.Utils.Maps.deep_merge([m1, m2, m3])
    %{user: %{1 => %{age: 21, color: :blue}}, dog:  %{8 => %{name: "Rover"}}}


  """
  def deep_merge(li) when is_list(li) do
    Enum.reduce(li, %{}, fn (m, acc) -> deep_merge(acc, m)  end)
  end
  def deep_merge(m), do: m
  def deep_merge(left, right) do
    Map.merge(left, right, &deep_resolve/3)
  end

  # Key exists in both maps, and both values are maps as well.
  # These can be merged recursively.
  defp deep_resolve(_key, left = %{}, right = %{}) do
    deep_merge(left, right)
  end

  # Key exists in both maps, but at least one of the values is
  # NOT a map. We fall back to standard merge behavior, preferring
  # the value on the right.
  defp deep_resolve(_key, _left, right) do
    right
  end

  def updates_in(db, []), do: db
  def updates_in(db, [{path, upd_cb} | list_of_updates]) do
    #update_in(db, path, upd_cb)
    get_and_update_in_struct(db, path, upd_cb)
    |> updates_in(list_of_updates)
  end


  @doc """
  ## Examples

    iex> db = %{dog: %{1 => %{name: "A"}}}
    iex> puts = [{[:dog, 1, :name], "B"}]
    iex> Lawn.Utils.Maps.puts_in(db, puts)
    %{dog: %{1 => %{name: "B"}}}
  """
  def puts_in(db, []), do: db
  def puts_in(db, [{path, value} | tl]) do
    new_db = get_and_update_in_struct(db, path, fn _ -> value end)
    puts_in(new_db, tl)
  end
  def puts_in(db, path, value) do
    get_and_update_in_struct(db, path, fn _ -> value end)
  end


  #def puts_in(db, []), do: db
  #def puts_in(db, [{path, value} | list_of_puts]) do
  #  elem(__MODULE__.get_and_update_in_struct(db, path, fn _ -> {nil, value} end), 1)

  #  #put_in(db, path, value)
  #  |> puts_in(list_of_puts)
  #end

  @doc """
  ## Examples

    iex> db = %{dog: %{1 => %{name: "A"}}}
    iex> deletes = [[:dog, 1, :name]]
    iex> Lawn.Utils.Maps.deletes_in(db, deletes)
    %{dog: %{1 => %{}}}
  """
  def deletes_in(db, []), do: db
  def deletes_in(db, [path | deletes]) do
    last = List.last(path)
    {_, pre_path} = List.pop_at(path, -1)
    get_and_update_in_struct(db, pre_path, &(Map.delete(&1, last)) )
    |> deletes_in(deletes)
  end


  def diff(lawn) do
    pre_lawn = Lawn.new(Map.get(lawn, :pre_db))
    diff_li = Enum.reduce(lawn, [], fn ({table, id, row}, acc) ->
      row_map = if is_struct(row), do: Map.from_struct(row), else: row

      diff_row = Enum.reduce(row_map, %{}, fn
        ({row_k, row_v}, row_acc) ->
          pre_v = Lawn.query(pre_lawn, [table, id, row_k])
          cond do
            !is_number(row_v) or !is_number(pre_v) -> row_acc
            row_v == pre_v -> row_acc
            true -> Map.put(row_acc, row_k, row_v - pre_v)
          end
        (_, row_acc) -> row_acc
      end)

      cond do
        Enum.empty?(diff_row) -> acc
        true -> [{table, id, diff_row} | acc]
      end
    end)

    Lawn.list_to_db(diff_li)
  end

end
