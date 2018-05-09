defmodule Hexaboard.GameServer do 
  alias Hexaboard.Game 

  use GenServer

  require Logger

  # Client API
  
  @doc """
  Starts the genServer.

  ## Examples 
      iex> {answer, _pid} = Hexaboard.GameServer.start
      iex> answer == :ok
      true
  """
  def start(name, init_state \\ nil) do
    
    init_state = 
      case init_state do
        {size, players} -> {size, players, name}
        players -> {6, players, name}
      end


    # if Mix.env != :test do
    IO.puts "Starting the game server for game #{name}..."
    # end 
    GenServer.start_link(__MODULE__, 
    	                 init_state, 
    	                 name: via_tuple(name))
  end 
  
  @doc """
  Stops the genServer.

  ## Examples 
      iex> Hexaboard.GameServer.start
      iex> Hexaboard.GameServer.stop
      :ok
  """
  def stop(name, reason \\ :normal) do 
  	GenServer.stop via_tuple(name), reason, :infinity
  end

  def get_state(name) do
    GenServer.call via_tuple(name), :get_state 
  end

  def get_encodable_state(name) do
    GenServer.call via_tuple(name), :get_encodable_state 
  end  

  def set_player_piece(name, player_id, piece) do 
  	GenServer.call via_tuple(name), {:set_player_piece, player_id, piece}
  end 

  def compute_turns(name) do 
  	GenServer.call via_tuple(name), :compute_turns
  end 

  def select_turn(name, turn) do 
    GenServer.call via_tuple(name), {:select_turn, turn}
  end

  def put_down_piece(name, player_id, position) do 
  	GenServer.call via_tuple(name), {:put_down_piece, player_id, position}
  end

  @doc """
  Returns a tuple used to register and lookup a game server process by name.
  """
  def via_tuple(game_name) do
    {:via, Registry, {Hexaboard.GameRegistry, game_name}}
  end  
  
  # def my_game_name do
  #   Registry.keys(Hexaboard.GameRegistry, self()) |> List.first
  # end
  
  @doc """
  Returns the `pid` of the game server process registered under the 
  given `game_name`, or `nil` if no process is registered.
  """
  def game_pid(game_name) do
    game_name
    |> via_tuple() 
    |> GenServer.whereis()
  end

  # Server callbacks

  def init(init_state) do 
    new_state = Game.new_game(init_state)
    {:ok, new_state}
  end

  def handle_call(:get_state, _from, state) do
    game_state = Game.game_state(state) 
    {:reply, game_state, game_state}
  end

  def handle_call(:get_encodable_state, _from, state) do
    game_state = Game.encodable_state(state) 
    {:reply, game_state, state}
  end

  def handle_call({:set_player_piece, player_id, piece}, _from, state) do
    case Game.set_player_piece(player_id, piece, state) do 
      {:ok, new_game} -> 
        {:reply, new_game, new_game}
       _ -> 
       	{:reply, state, state}
    end 
  end

  def handle_call(:compute_turns, _from, state) do
    case Game.compute_turns(state) do 
      {:ok, new_game} -> 
        {:reply, new_game, new_game}
       _ -> 
        {:reply, state, state}
    end
  end

  def handle_call({:select_turn, turn}, _from, state) do
    case Game.select_turn(turn, state) do 
      {:ok, new_game} -> 
        {:reply, new_game, new_game}
       _ -> 
        {:reply, state, state}
    end
  end 

  def handle_call({:put_down_piece, player_id, position}, _from, state) do
    case Game.put_down_piece(player_id, position, state) do 
      {:ok, new_game} -> 
        {:reply, new_game, new_game}
       _ -> 
        {:reply, state, state}
    end
  end

  



end