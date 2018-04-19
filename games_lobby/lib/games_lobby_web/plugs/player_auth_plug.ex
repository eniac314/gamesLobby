defmodule GamesLobbyWeb.Plugs.PlayerAuthPlug do 
  import Plug.Conn

  alias GamesLobby.Accounts.Player
	
  def init(opts) do
    Keyword.fetch!(opts, :repo)
  end
	
  def call(conn, repo) do
    player_id = get_session(conn, :player_id)
    player = player_id && repo.get(Player, player_id)
    # IO.inspect(player)
    assign(conn, :current_player, player)
  end

end