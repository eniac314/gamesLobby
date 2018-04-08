defmodule GamesLobbyWeb.Plugs.PlayerSignInPlug do 
  import Plug.Conn

  alias GamesLobby.Accounts.Player
	
  def init(player) do
    player
  end
	
  def call(conn, %Player{} = player) do
    conn 
    |> assign(:current_user, player)
    |> put_session(:player_id, player.id)
    |> configure_session(renew: true)
  end

end