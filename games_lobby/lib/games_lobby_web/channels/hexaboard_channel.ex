defmodule GamesLobbyWeb.HexaboardChannel do 
  use GamesLobbyWeb, :channel
  alias GamesLobbyWeb.Presence

  def join("hexaboard:chat", _params, socket) do 
    send(self(), {:after_join, "chat"})
    Mainlobby.ChatServer.add_channel(:hexaboard)
    {:ok, socket}
  end

  def join("hexaboard:game", _params, socket) do 
    send(self(), {:after_join, "game"})
    {:ok, socket}
  end

  def handle_info({:after_join, "chat"}, socket) do 
    push(socket, "greetings", %{username: socket.assigns.current_player.username})
    
    push(socket, "chat_history", %{chat_history: Mainlobby.ChatServer.get_chat_history(:hexaboard)})

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

  def handle_info({:after_join, "game"}, socket) do 
    {:noreply, socket}
  end

end 