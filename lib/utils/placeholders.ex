defmodule Lawn.Utils.Placeholders do

  def get_current_from_strings(v, []), do: v
  def get_current_from_strings(atom_map, [hd | list_of_strings]) do
    case Map.keys(atom_map) |> Enum.find(fn a -> "#{a}" == hd end) do
      nil -> nil
      k ->
        v = Map.get(atom_map, k)
        get_current_from_strings(v, list_of_strings)
    end
  end


  def replace_currents(lawn, li) do
    Enum.map(li, fn
      "@current." <> placeholder ->
        str_li = ["current" | String.split(placeholder, ".")]
        get_current_from_strings(lawn, str_li)
      i -> i
    end)
  end
end
