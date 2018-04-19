defmodule GamesLobbyWeb.LobbyChannel do 

use GamesLobbyWeb, :channel 
alias GamesLobbyWeb.Presence

  def join("lobby:" <> _subtopic, _params, socket) do 
	  send(self(), :after_join)
    {:ok, socket}
  end 
  

  def handle_info(:after_join, socket) do 
    push(socket, "greetings", %{username: socket.assigns.current_player.username})
    
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
   

  def handle_in("new_chat_message", %{"time_stamp" => time_stamp, "author" => author, "message" => message}, socket) do
    broadcast!(socket, "new_chat_message", %{
      time_stamp: time_stamp,
      author: author,
      message: message,
    })

    {:noreply, socket}
  end  

end 