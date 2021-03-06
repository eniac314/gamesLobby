defmodule Mainlobby.GameSetup do 
  
  def new_games_setup do
    %{ next_id: 0
     }
  end
  
  def get_games_setup(games_setup) do 
    Map.delete(games_setup, :next_id)
    |> Enum.filter(fn ({_k,v}) -> not v.ready end )
    |> Enum.reduce(%{}, fn({k,v}, acc) -> 
                             {k2, v2} = stringify_game_id({k,v})
                             Map.put(acc, k2, v2) end
                  )
  end 
  
  def get_players(games_setup, game_id) do 
    host = get_in(games_setup, [game_id, :host])
    joined = get_in(games_setup, [game_id, :joined])
    [host | joined]
  end 


  def new_game(games_setup, game_name, player) do
    next_id = games_setup.next_id
    new_game = %{ game_meta: Mainlobby.GamesMeta.games_meta[game_name], 
                  joined: [],
                  has_started: [],
                  has_loaded: [],
                  host: player,
                  ready: false
                }
    game_id = {game_name, next_id}
    
    Map.put(games_setup, game_id, new_game)
    |> Map.update!(:next_id, &(&1 + 1))
  end

  def delete_game(games_setup, game_id) do 
    Map.delete(games_setup, game_id)
  end 
  
  def leave_game(games_setup, game_id, player) do 
    update_in(games_setup, [game_id, :joined], &(List.delete(&1,player)))
  end

  def join_game(games_setup, game_id, player) do 
    max_players = games_setup[game_id].game_meta.max_players
    already_in = length(games_setup[game_id].joined)
    if games_setup[game_id].host == nil or (already_in >= max_players) do 
      games_setup
    else 
      update_in(games_setup, [game_id, :joined], &([player | &1]))
    end
  end

  def has_started(games_setup, game_id, player) do 
    joined = get_in(games_setup, [game_id, :joined])

    if Enum.member?(joined, player) or (player == get_in(games_setup, [game_id, :host])) do  
      update_in(games_setup, [game_id, :has_started], &([player | &1]))
    else 
      games_setup
    end 
  end
  
  def has_loaded(games_setup, game_id, player) do 
    has_loaded = get_in(games_setup, [game_id, :has_loaded])

    if Enum.member?(has_loaded, player) do  
      update_in(games_setup, [game_id, :has_loaded], &([player | &1]))
    else 
      games_setup
    end 
  end

  def game_ready(games_setup, game_id) do
    put_in(games_setup, [game_id, :ready], true)
  end 

  def game_ready?(games_setup, game_id) do
    get_in(games_setup, [game_id, :ready])
  end  

  def everybody_started?(games_setup, game_id) do 
    joined = [get_in(games_setup, [game_id, :host]) | get_in(games_setup, [game_id, :joined])]
    has_started = get_in(games_setup, [game_id, :has_started])
    
    has_started? = 
      fn (player, acc) -> 
          acc and Enum.member?(has_started, player)
      end 
    
    Enum.reduce(joined, true, has_started?)
    
  end  

  def everybody_loaded?(games_setup, game_id) do 
    has_started = get_in(games_setup, [game_id, :has_started])
    has_loaded = get_in(games_setup, [game_id, :has_loaded])
    has_loaded? = 
      fn (player, acc) -> 
          acc and Enum.member?(has_loaded, player)
      end 
    
    Enum.reduce(has_started, true, has_loaded?)
    
  end  


  def game_id_to_string({game_name, id}) do 
    n = to_string game_name
    id = to_string id
    "#{n} #{id}"
  end 
  
  defp stringify_game_id({k, v}) do 
    {n,id} = k
    str = game_id_to_string({n, id})
    {str, Map.put(v, :game_id, str) }
  end 
end
