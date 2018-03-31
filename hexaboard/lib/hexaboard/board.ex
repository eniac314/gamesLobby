defmodule Hexaboard.Board do 

alias Hexaboard.Shifumi
alias Hexaboard.Cell
  
  def hexa_board(n) do 
    
    make_row_top = 
      fn(i) -> 
      	Enum.map(Range.new(0, n + i), fn(j) -> {j, i} end)
      end 

    make_row_bottom = 
      fn(i) -> 
      	Enum.map(Range.new(0, 2 * n + (n - i)), fn(j) -> {j, i} end)
      end 

    top_half = 
      Enum.map(Range.new(0, n), make_row_top)
      |> Enum.concat

    top_bottom = 
      Enum.map(Range.new(n + 1, 2 * n), make_row_bottom)
      |> Enum.concat

    top_half ++ top_bottom
    |> Enum.reduce(%{}, fn({x, y}, acc) -> 
    	                   Map.put(acc, {x, y}, %Cell{x_pos: x, y_pos: y}) end )

  end   
  
  defp update_board_helper(board, cells_todo, cells_done, size) do
    case cells_todo do
      [] -> board
      [c | cs] ->
        case Map.get(c, :state) do 
          {:contain, piece} -> 
            if !(Enum.member?(cells_done, c)) do 
              {new_board, new_cells_todo} = 
                convert_neighbours(piece, neighbours(c, size), board, cells_todo, cells_done)
              update_board_helper(new_board, new_cells_todo, [c | cells_done], size)
                
            else
              update_board_helper(board, cs, cells_done, size)
            end   

            _ -> 
              update_board_helper(board, cs, cells_done, size)
          end
        end
  end 

  defp convert_neighbours(piece, n_list, board, cells_todo, cells_done) do
    case n_list do 
      [] ->  {board, cells_todo}

      [ n | ns ] -> 
        case Map.get(board, n) do
          %Cell{} = n_cell -> 
            case Map.get(n_cell, :state) do 
              {:contain, n_piece} -> 
                if (!Enum.member?(cells_done, n_cell)) 
                  and piece[:player_id] != n_piece[:player_id] do
                    new_n_piece = 
                      %{n_piece | player_id: piece[:player_id]}
                    new_n_cell = 
                      %Cell{n_cell | state: {:contain, new_n_piece}}
                    new_board = 
                      Map.put(board, n, new_n_cell)
                    case Shifumi.shifumi(piece[:value], n_piece[:value]) do 
                      1 -> 
                        convert_neighbours(piece, ns, new_board, cells_todo, cells_done)
                      2 -> 
                        convert_neighbours(piece, ns, new_board, (cells_todo ++ [new_n_cell]), cells_done)
                      _ -> 
                        convert_neighbours(piece, ns, board, cells_todo, cells_done)
                    end 
                else convert_neighbours(piece, ns, board, cells_todo, cells_done)
                end
              _ ->
                convert_neighbours(piece, ns, board, cells_todo, cells_done)
            end 

          nil -> 
            convert_neighbours(piece, ns, board, cells_todo, cells_done)  
        end
    
    end
  end

  def update_board(board, %Cell{} = c, size) do 
    update_board_helper(board, [c], [], size)   
  end

  defp is_edge(n, %Cell{x_pos: x_pos, y_pos: y_pos} = _cell) do 
    x_pos == 0 or y_pos == 0 or y_pos == 2 * n or x_pos == n + y_pos or x_pos + y_pos == 3 * n 
  end 
  
  def board_with_edge(n) do 
    hexa_board(n)
    |> Enum.map(fn({key, cell}) -> 
                      {key, %{ cell | state: if is_edge(n, cell) do 
                                               {:unplayable, :grey}
                                             else cell.state 
                                             end
                              }
                      }
                end) 
    |> Map.new
  end
  
  defp neighbours(%Cell{x_pos: x, y_pos: y}, size) do 
    always = 
      [ {x, y - 1},
        {x - 1, y},
        {x + 1, y},
        {x, y + 1},
      ]
    cond do
      y < size ->  
        [{ x - 1, y - 1} | [{ x + 1, y + 1} | always]]
      y == size -> 
        [{ x - 1, y - 1} | [{ x - 1, y + 1} | always]]  
      true -> 
        [{ x + 1, y - 1} | [{ x - 1, y + 1} | always]]
    end
  end  

end 

