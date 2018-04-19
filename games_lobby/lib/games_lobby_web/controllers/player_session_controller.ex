defmodule GamesLobbyWeb.PlayerSessionController do
  use GamesLobbyWeb, :controller

  alias GamesLobbyWeb.Plugs.PlayerSignInPlug
  alias GamesLobby.Accounts.Player

  def new(conn, _) do 
  	render(conn, "new.html")
  end
  
  def create(conn, %{"session" => %{"username" => user, "password" => pass}}) do 
    case sign_in(conn, user, pass, repo: GamesLobby.Repo) do 
    	{:ok, conn} -> 
    		conn 
    		|> put_flash(:info, "Welcome back!")
    		|> redirect(to: page_path(conn, :index))
    	{:error, _reason, conn} -> 
    		conn
    		|> put_flash(:error, "Invalid username/password")
    		|> render("new.html")
    end 
  end

  def delete(conn, _) do 
  	conn 
  	|> sign_out()
  	|> redirect(to: player_session_path(conn, :new))
  end 

  defp sign_in(conn, username, given_pass, opts) do 
  	repo = Keyword.fetch!(opts, :repo)
  	player = repo.get_by(Player, username: username)

  	cond do 
  		player && Comeonin.Bcrypt.checkpw(given_pass, player.password_digest) -> 
  			{:ok, PlayerSignInPlug.call(conn, player)}
  		player -> 
  			{:error, :unauthorized, conn}
  		true -> 
  			Comeonin.Bcrypt.dummy_checkpw()
  			{:error, :not_found, conn}
  	end
  end

  defp sign_out(conn) do 
    # assign(conn, :current_player, nil)
  	configure_session(conn, drop: true)
  end


end 