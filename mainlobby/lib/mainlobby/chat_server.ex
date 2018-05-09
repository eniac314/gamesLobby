defmodule Mainlobby.ChatServer do 
  use GenServer
  alias Mainlobby.Chat 

  @name :chat_server
  

  # Client API
  def start(init_state \\ %{mainlobby: []}) do 
  	IO.puts "Starting the main lobby chat server..."
    GenServer.start_link( __MODULE__, 
    	                  init_state,
    	                  name: @name )
  end

  def stop(reason \\ :normal) do
    GenServer.stop @name, reason, :infinity
  end 
  
  def get_whole_state do 
    GenServer.call @name, :get_whole_state
  end

  def get_chat_history(channel) do
    GenServer.call @name, {:get_chat_history, channel}
  end

  def add_message(message, channel) do
    GenServer.call @name, {:add_message, message, channel}
  end 
  
  def add_channel(channel) do 
    GenServer.call @name, {:add_channel, channel}
  end 

  def delete_channel(channel) do 
    GenServer.call @name, {:delete_channel, channel}
  end 


  # Server callbacks
  def init(init_state) do 
    {:ok, init_state}
  end 

  def handle_call({:add_message, message, channel}, _from, state) do 
    new_state = Chat.add_message(state, message, channel) 
    {:reply, "message added", new_state}
  end 

  def handle_call({:get_chat_history, channel}, _from, state) do 
    history = Chat.get_chat_history(state, channel)
    {:reply, history, state}
  end

  def handle_call(:get_whole_state, _from, state) do 
    whole_state = Chat.get_whole_state(state)
    {:reply, whole_state, state}
  end 
  
  def handle_call({:add_channel, channel}, _from, state) do 
    new_state = Chat.add_channel(state, channel)
    {:reply, "channel added", new_state}
  end
  
  def handle_call({:delete_channel, channel}, _from, state) do 
    new_state = Chat.delete_channel(state, channel)
    {:reply, "channel deleted", new_state}
  end 

end