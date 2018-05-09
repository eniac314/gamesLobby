defmodule GamesLobbyWeb.HexaboardChannel do 
  use GamesLobbyWeb, :channel
  alias GamesLobbyWeb.Presence
  alias Hexaboard.GameServer
  alias Mainlobby.ChatServer

  def join("hexaboard:chat:" <> game_id, %{"game_id" => game_id}, socket) do 
    send(self(), {:after_join, "chat"})
    Mainlobby.ChatServer.add_channel({:hexaboard, game_id})
    {:ok, assign(socket, :game_id, {:hexaboard, game_id})}
  end

  def join("hexaboard:game:" <> game_id, _params, socket) do 
    send(self(), {:after_join, "game"})
    {:ok, assign(socket, :game_id, {:hexaboard, game_id})}
  end

  def handle_info({:after_join, "chat"}, socket) do 
    push(socket, "greetings", %{username: socket.assigns.current_player.username})
    
    push(socket, "chat_history", %{chat_history: ChatServer.get_chat_history(:hexaboard)})

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
    push(socket, "greetings", %{username: socket.assigns.current_player.username})
    {:noreply, socket}
  end
  
  def handle_in("new_chat_message", %{"time_stamp" => time_stamp, "author" => author, "message" => message} = new_message, socket) do
    ChatServer.add_message(new_message, socket.assigns.game_id)
    broadcast!(socket, "new_chat_message", %{
      time_stamp: time_stamp,
      author: author,
      message: message,
    })

    {:noreply, socket}
  end

  def handle_in("requesting_gamestate", _params, socket) do
    {:hexaboard, game_id} = socket.assigns.game_id
    if GameServer.game_pid(game_id) do 
      push(socket, "game_state", %{game_state: GameServer.get_encodable_state(game_id)})
    end 
    {:noreply, socket} 
  end  

end 