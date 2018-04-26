defmodule GamesLobbyWeb.LobbyChannel do 

use GamesLobbyWeb, :channel 
alias GamesLobbyWeb.Presence

  def join("lobby:chat", _params, socket) do 
	  send(self(), {:after_join, "chat"})
    {:ok, socket}
  end   

  def join("lobby:mainlobby", _params, socket) do 
    send(self(), {:after_join, "mainlobby"})
    {:ok, socket}
  end

  def handle_info({:after_join, "chat"}, socket) do 
    push(socket, "greetings", %{username: socket.assigns.current_player.username})
    
    push(socket, "chat_history", %{chat_history: Mainlobby.ChatServer.get_chat_history()})

    push(socket, "presence_state", Presence.list(socket))

    {:ok, _} = 
    # track broadcast a diff message to all clients of this channel
      Presence.track(socket, socket.assigns.current_player.username, %{
      	joined_at: inspect(System.system_time(:seconds)),
      	username: socket.assigns.current_player.username
      })

    # IO.inspect(socket)
    {:noreply, socket}
  end
  
  def handle_info({:after_join, "mainlobby"}, socket) do 
    push(socket, "games_meta", %{games_meta: Map.values(Mainlobby.GamesMeta.games_meta)})
    push(socket, "games_setup", %{games_setup: Mainlobby.GameSetupServer.get_games_setup})
    {:noreply, socket}
  end

  def handle_in("new_chat_message", %{"time_stamp" => time_stamp, "author" => author, "message" => message} = new_message, socket) do
    Mainlobby.ChatServer.add_message(new_message)
    broadcast!(socket, "new_chat_message", %{
      time_stamp: time_stamp,
      author: author,
      message: message,
    })

    {:noreply, socket}
  end  
  

  def handle_in("new_game_message", %{"name" => name, "host" => host}, socket) do 
    Mainlobby.GameSetupServer.new_game(safe_atomize(name), host)
    broadcast!(socket, "games_setup", %{games_setup: Mainlobby.GameSetupServer.get_games_setup})
    
    {:noreply, socket}
  end 

  def handle_in("delete_game_message", %{"name" => name, "id" => id}, socket) do
    Mainlobby.GameSetupServer.delete_game({safe_atomize(name), id})
    broadcast!(socket, "games_setup", %{games_setup: Mainlobby.GameSetupServer.get_games_setup})
    
    {:noreply, socket}
  end
  
  def handle_in("join_game_message", %{"player" => player, "game_id" => game_id}, socket) do 
    Mainlobby.GameSetupServer.join_game(player, {safe_atomize(game_id["name"]), game_id["id"]})
    broadcast!(socket, "games_setup", %{games_setup: Mainlobby.GameSetupServer.get_games_setup})
    
    {:noreply, socket}
  end   
  
  def handle_in("leave_game_message", %{"player" => player, "game_id" => game_id}, socket) do 
    Mainlobby.GameSetupServer.leave_game(player, {safe_atomize(game_id["name"]), game_id["id"]})
    broadcast!(socket, "games_setup", %{games_setup: Mainlobby.GameSetupServer.get_games_setup})
    
    {:noreply, socket}
  end

  def handle_in("start_game_message", %{"player" => player, "game_id" => game_id}, socket) do 
    Mainlobby.GameSetupServer.has_started(player, {safe_atomize(game_id["name"]), game_id["id"]})
    if Mainlobby.GameSetupServer.everybody_started?({safe_atomize(game_id["name"]), game_id["id"]}) do 
      broadcast!(socket, "ready_to_launch", %{game_id: game_id})
    else 
      broadcast!(socket, "games_setup", %{games_setup: Mainlobby.GameSetupServer.get_games_setup})
    end 
    {:noreply, socket}
  end

  
  defp safe_atomize(external) do 
    try do 
      String.to_existing_atom(external)
    rescue
      ArgumentError -> 
        :unknown_atom
    end 
  end

end 