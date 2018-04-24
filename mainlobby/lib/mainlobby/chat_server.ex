defmodule Mainlobby.ChatServer do 
  use GenServer
  alias Mainlobby.Chat 

  @name :chat_server
  

  # Client API
  def start(init_state \\ []) do 
  	IO.puts "Starting the main lobby chat server..."
    GenServer.start_link( __MODULE__, 
    	                  init_state,
    	                  name: @name )
  end

  def stop(reason \\ :normal) do
    GenServer.stop @name, reason, :infinity
  end 
  
  def get_chat_history do
    GenServer.call @name, :get_chat_history
  end

  def add_message(message) do
    GenServer.call @name, {:add_message, message}
  end 


  # Server callbacks
  def init(init_state) do 
    {:ok, init_state}
  end 

  def handle_call({:add_message, message}, _from, state) do 
    new_state = Chat.add_message(message,state) 
    {:reply, "message added", new_state}
  end 

  def handle_call(:get_chat_history, _from, state) do 
    history = Chat.get_chat_history(state)
    {:reply, history, state}
  end

end