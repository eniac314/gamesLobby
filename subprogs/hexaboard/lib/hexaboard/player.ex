defmodule Hexaboard.Player do 
  
  defstruct deck: [], 
            name: "",
            id: nil,
            piece: nil,
            score: 0
  
  @behaviour Access
  def fetch(term, key) do
    case Map.get(term, key, nil) do
     nil -> :error
     value -> {:ok, value} 
    end
  end
  
  def get(structure, key, default \\ nil) do
    case fetch(structure, key) do
     {:ok, value} -> value
     :error       -> default
    end 
  end

  def get_and_update(data, key, function) do 
    case function.(Map.get(data, key)) do 
      {get_value, update_value} -> 
        {get_value, Map.put(data, key, update_value)}
      :pop -> 
        {Map.get(data, key), Map.delete(data,key)}
    end
  end 
  
  def pop(data, key) do 
    case Map.get(data, key) do 
      nil -> 
        {:key_missing, data}
      value -> 
        {value, Map.delete(data,key)}
    end
  end

end