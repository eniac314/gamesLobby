defmodule Mainlobby.GameSetupServer do 

  use GenServer
  alias Mainlobby.GameSetup
  
  @name :game_setup_server

  # Client API 

  def start(_init_state \\ []) do 
    IO.puts "Starting the game setup server..."
    GenServer.start_link(__MODULE__, [], name: @name)
  end
  
  def get_games_setup do 
    GenServer.call @name, :get_games_setup
  end 
  
  def get_players(game_id) do
    GenServer.call @name, {:get_players, game_id}
  end 

  def new_game(game_name, player) do 
    GenServer.call @name, {:new_game, game_name, player}
  end

  def delete_game(game_id) do
    GenServer.call @name, {:delete_game, game_id}
  end 
  
  def leave_game(player, game_id) do 
    GenServer.call @name, {:leave_game, game_id, player}
  end 

  def join_game(player, game_id) do 
    GenServer.call @name, {:join_game, game_id, player}
  end  

  def has_started(player, game_id) do 
    GenServer.call @name, {:has_started, game_id, player}
  end

  def has_loaded(player, game_id) do 
    GenServer.call @name, {:has_loaded, game_id, player}
  end
  
  def game_ready(game_id) do 
    GenServer.call @name, {:game_ready, game_id}
  end
  
  def game_ready?(game_id) do 
    GenServer.call @name, {:game_ready?, game_id}
  end

  def everybody_started?(game_id) do 
    GenServer.call @name, {:everybody_started?, game_id}
  end

  def everybody_loaded?(game_id) do 
    GenServer.call @name, {:everybody_loaded?, game_id}
  end  

  # Server callbacks

  def init(_init_state) do 
    new_state = GameSetup.new_games_setup
    {:ok, new_state}
  end

  def handle_call(:get_games_setup, _from, state) do 
    games_setup = GameSetup.get_games_setup(state)
    {:reply, games_setup, state}
  end
  
  def handle_call({:get_players, game_id}, _from, state) do 
    players = GameSetup.get_players(state, game_id)
    {:reply, players, state}
  end

  def handle_call({:new_game, game_name, player}, _from, state) do
    new_state = GameSetup.new_game(state, game_name, player)
    {:reply, new_state, new_state}
  end 
  
  def handle_call({:delete_game, game_id}, _from, state) do
    new_state = GameSetup.delete_game(state, game_id)
    {:reply, new_state, new_state}
  end

  def handle_call({:leave_game, game_id, player}, _from, state) do 
    new_state = GameSetup.leave_game(state, game_id, player)
    {:reply, new_state, new_state}
  end

  def handle_call({:join_game, game_id, player}, _from, state) do 
    new_state = GameSetup.join_game(state, game_id, player)
    {:reply, new_state, new_state}
  end

  def handle_call({:has_started, game_id, player}, _from, state) do 
    new_state = GameSetup.has_started(state, game_id, player)
    {:reply, new_state, new_state}
  end

  def handle_call({:has_loaded, game_id, player}, _from, state) do 
    new_state = GameSetup.has_loaded(state, game_id, player)
    {:reply, new_state, new_state}
  end

  def handle_call({:game_ready, game_id}, _from, state) do 
    new_state = GameSetup.game_ready(state, game_id)
    {:reply, new_state, new_state}
  end

  def handle_call({:game_ready?, game_id}, _from, state) do 
    bool = GameSetup.game_ready?(state, game_id)
    {:reply, bool, state}
  end

  def handle_call({:everybody_started?, game_id}, _from, state) do 
    bool = GameSetup.everybody_started?(state, game_id)
    {:reply, bool, state}
  end

  def handle_call({:everybody_loaded?, game_id}, _from, state) do 
    bool = GameSetup.everybody_loaded?(state, game_id)
    {:reply, bool, state}
  end

end 
