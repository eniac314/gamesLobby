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

  

   

end 