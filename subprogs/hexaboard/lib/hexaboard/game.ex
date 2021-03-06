defmodule Hexaboard.Game do
	alias Hexaboard.Board
	alias Hexaboard.Shifumi
	alias Hexaboard.Player
	alias Hexaboard.Cell

	defp initial_state({n, players, name}) do 
    nbr_players = length(players)
    %{ board: Board.board_with_edge(n),
       players: Enum.zip(Range.new(1, nbr_players), players)
                |> Enum.map(fn({id, n}) -> {id, %Player{id: id, name: n, deck: Range.new(0,14) |> MapSet.new}} end)
                |> Map.new,
       turn_selection_order: [],
       playing_order_buffer: [],
       playing_order: [],
       available_turns: MapSet.new(Range.new(1,nbr_players)),
       board_size: n,
       game_name: name
     }
  end

  def new_game(init_state) do 
  	if init_state != nil do 
  	  initial_state(init_state)
    else initial_state({6,["tom","jerry"],"default"})
    end  
  end

  def game_state(game) do 
    game
  end 

  def encodable_state(game) do 
    game = compute_scores(game)

    encodable_cell = 
      fn (%{state: state} = cell) -> 
        case state do 
          :empty -> cell
          
          {:unplayable, color} -> 
            %{cell | state: %{unplayable: color}}
          
          {:contain, piece} -> 
            %{cell | state: %{contain: piece}}
        end
      end    

    encodable_board = 
      Map.values(game.board)
      |> Enum.map(encodable_cell)

    encodable_players = 
      game.players
      |> Enum.map(fn({_k,p}) -> 
                    %{ p | deck: MapSet.to_list(p.deck)} end)
      |> Enum.reduce(%{}, fn(p,acc) ->
                             Map.put(acc, p.name, p) end)

    %{game | board: encodable_board,
             players: encodable_players,
             available_turns: MapSet.to_list(game.available_turns)
     } 
     |> Map.put(:game_over, game_over?(game))
  end 
  
  def pieces_all_set?(game) do 
    not Enum.any?(game[:players], fn({_id, %Player{piece: piece}}) -> piece == nil end)
  end 

  def compute_turns(game) do
  	players = game[:players]

    nbr_players = Enum.count(players)
    
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
  		                       turn_selection_order: turn_selection_order,
                             available_turns: MapSet.new(Range.new(1,nbr_players)),
                             playing_order_buffer: []
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
		    new_available_turns = MapSet.delete(game[:available_turns], turn) 
		    new_turn_selection_order = xs
        new_playing_order_buffer = [ %{id: player_id, turn: turn} | game.playing_order_buffer ]
        playing_order = Enum.sort_by(new_playing_order_buffer, fn(x) -> Map.get(x, :turn) end)
                        |> Enum.map(fn(p) -> Map.get(p, :id) end)

		    new_game = %{ game | available_turns: new_available_turns,
		                         playing_order_buffer: new_playing_order_buffer,
                             playing_order: playing_order,
		                         turn_selection_order: new_turn_selection_order
		                 }
		    
		    {:ok, new_game}
    end
  end

  def turns_all_set?(game) do 
    Enum.count(game.players) == length(game.playing_order)
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

            new_playing_order = 
              case game.playing_order do 
                [] -> []
                [_x | xs] -> xs
              end 

            new_game = %{ game | board: new_board, playing_order: new_playing_order }
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

  def round_over?(game) do 
    game.playing_order == []
  end 

  def game_over?(game) do 
    Enum.reduce(game.players, true, fn({_id,p}, acc) -> acc and MapSet.size(p.deck) == 0 and p.piece == nil end)
  end 

end