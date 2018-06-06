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

  def handle_in("set_player_piece", %{"player_id" => player_id, "piece" => piece}, socket) do 
    {:hexaboard, game_id} = socket.assigns.game_id
    piece = %{value: piece["value"], player_id: piece["player_id"]}

    GameServer.set_player_piece(game_id, player_id, piece)
    
    GameServer.compute_turns(game_id)
    
    game = GameServer.get_encodable_state(game_id)
    avl_turns = game.available_turns
    turn_sel_ord = game.turn_selection_order
    playing_order = game.playing_order
    players = game.players

    if GameServer.pieces_all_set?(game_id) do 
      broadcast!(socket, 
                "pieces_all_set",
                 %{available_turns: avl_turns,
                   turn_selection_order: turn_sel_ord,
                   playing_order: playing_order}
                 )
    
    end

    push(socket, "piece_picked_up", %{players: players})
    broadcast!(socket, "players_update", %{players: players})   

    {:noreply, socket}
  end   
  

  def handle_in("turn_selected", %{"turn" => turn}, socket) do
    {:hexaboard, game_id} = socket.assigns.game_id
    
    GameServer.select_turn(game_id, turn)
    game = GameServer.get_encodable_state(game_id)

    avl_turns = game.available_turns
    turn_sel_ord = game.turn_selection_order
    playing_order =game.playing_order

    turns_info = %{available_turns: avl_turns,
                  turn_selection_order: turn_sel_ord,
                  playing_order: playing_order}
    

    if GameServer.turns_all_set?(game_id) do 
      broadcast!(socket, "turns_all_set", turns_info)
    else
      broadcast!(socket, "turn_selected", turns_info) 
    end 
    
    {:noreply, socket}
  end
  

  def handle_in("put_down_piece", %{"player_id" => player_id, "pos_x" => pos_x, "pos_y" => pos_y}, socket) do
    {:hexaboard, game_id} = socket.assigns.game_id

    GameServer.put_down_piece(game_id, player_id, {pos_x, pos_y})
    game = GameServer.get_encodable_state(game_id)

    broadcast!(socket, "piece_down", %{game_state: game})

    if GameServer.game_over?(game_id) do
       broadcast!(socket, "game_over", %{})
    else if GameServer.round_over?(game_id) do 
           broadcast!(socket, "round_over", %{})
         end 
    end 

    {:noreply, socket}
  end
end 