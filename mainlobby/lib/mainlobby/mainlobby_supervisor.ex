defmodule Mainlobby.MainlobbySupervisor do

  use DynamicSupervisor 

  alias Mainlobby.ChatServer
  alias Mainlobby.GameSetupServer

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc """
  Starts a `ChatServer` process and supervises it.
  """
  def start_chat do
      child_spec = %{
        id: ChatServer, 
        start: {ChatServer, :start, []},
        restart: :transient
      }

      DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Terminates the `ChatServer` process normally. It won't be restarted.
  """
  def stop_chat() do
    child_pid = GenServer.whereis(:chat_server)
    DynamicSupervisor.terminate_child(__MODULE__, child_pid)
  end
  
  def start_game_setup() do 
    child_spec = %{
      id: GameSetupServer,
      start: {GameSetupServer, :start, []},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def stop_game_setup() do
    child_pid = GenServer.whereis(:game_setup_server)
    DynamicSupervisor.terminate_child(__MODULE__, child_pid)
  end 

end

