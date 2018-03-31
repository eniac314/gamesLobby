defmodule Hexaboard.Game do
	alias Hexaboard.Board
	alias Hexaboard.Shifumi
	alias Hexaboard.Player
	alias Hexaboard.Cell

	defp initial_state({n, nbr_players, name}) do 
    %{ board: Board.board_with_edge(n),
       players: Range.new(0, nbr_players - 1)
                |> Enum.map(fn(id) -> {id, %Player{id: id, deck: Range.new(0,14) |> MapSet.new}} end)
                |> Map.new,
       turn_selection_order: [],
       available_turns: MapSet.new(Range.new(1,nbr_players)),
       board_size: n,
       game_name: name
     }
  end

  def new_game(init_state) do 
  	if init_state != nil do 
  	  initial_state(init_state)
    else initial_state({6,2,"default"})
    end  
  end

  def game_state(game) do 
    game
  end 

  def compute_turns(game) do
  	players = game[:players]
    
  	player_turn_score = 
  	  fn({id,player}) -> 
  	  	
  	  	shifumi_match = 
          fn({_id,player2}, acc) -> 
          	piece1 = (Map.get(player, :piece))
          	piece2 = (Map.get(player2, :piece))
          	acc + Shifumi.shifumi(piece1, piece2)
          end

  	  	{id, %{ player | score: Enum.reduce(players, 0, shifumi_match)}}

  	  end

  	if Enum.any?(players, fn({_id, %Player{piece: piece}}) -> piece == nil end) do 
  		{:unset_pieces, game}
  	
  	else new_players = Enum.map(players, player_turn_score)
  	                   |> Map.new
         
         turn_selection_order = Map.values(new_players)
                                |> Enum.sort_by(fn(p) -> Map.get(p, :score) end)
                                |> Enum.reverse
                                |> Enum.map(fn(p) -> Map.get(p, :id) end) 

  		   new_game = %{game | players: new_players, 
  		                       turn_selection_order: turn_selection_order
  		                }
  		 
  		 {:ok, new_game}
    
    end
  end

  def set_player_piece(player_id, piece, game) do 
    new_player = Map.get(game[:players], player_id)
                 |> Map.put(:piece, piece[:value])
                 |> Map.update!(:deck, fn(d) -> MapSet.delete(d,piece[:value]) end) 
    
    current_players = game[:players]
                 
    {:ok, %{ game | players: Map.put(current_players, player_id, new_player) }}
    
  end

  def select_turn(turn, game) do 
    case game[:turn_selection_order] do 
      [] -> {:no_more_turns, game}
      
      [x | xs] ->
		    player_id = x
		    player = Map.get(game[:players], player_id)
		    new_player = %{ player | turn: turn, score: 0}
		    new_players = Map.put(game[:players], player_id, new_player)
		    new_available_turns = MapSet.delete(game[:available_turns], turn) 
		    new_turn_selection_order = xs

		    new_game = %{ game | available_turns: new_available_turns,
		                         players: new_players,
		                         turn_selection_order: new_turn_selection_order
		                 }
		    
		    {:ok, new_game}
    end
  end  

  def put_down_piece(player_id, position, game) do
    case Map.get((game[:players])[player_id], :piece) do 
      nil ->
        {:no_piece, game}
      value -> 
        case Map.get(game[:board], position) do
          %Cell{state: :empty} = cell -> 
        	  
            new_cell_state = {:contain, %{value: value, player_id: player_id}}
        	  new_cell = %{cell | state: new_cell_state}
        	  new_board = Map.put(game[:board], position, new_cell)
        	              |> Board.update_board(new_cell, game[:board_size])

            new_game = %{ game | board: new_board}
                       |> Kernel.put_in([:players, player_id, :piece], nil)
                       |> compute_scores 

        	  {:ok, new_game}
          _ -> 
            {:position_taken, game}
        end
      end 
  end  

  defp compute_scores(game) do

    compute_score = 
      fn(p_id) -> 
        game[:board]
        |> Map.values
        |> Enum.filter(fn(%Cell{state: state}) -> 
                         case state do 
                          {:contain, %{player_id: id}} -> id == p_id
                          _ -> false 
                          end 
                       end)
        |> Enum.count
      end
    
    new_players =      
      game[:players]
      |> Enum.map(fn({id, p}) -> {id, %{p | score: compute_score.(id)}} end)
      |> Map.new
    %{ game | players: new_players }
  end


end