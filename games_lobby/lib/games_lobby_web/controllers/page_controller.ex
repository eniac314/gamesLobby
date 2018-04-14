defmodule GamesLobbyWeb.PageController do
  use GamesLobbyWeb, :controller

  plug :authenticate when action in [:index]

  def index(conn, _params) do
    salt = random_string(64)
    
    conn 
    |> assign(:auth_salt, salt)
    |> assign(:auth_token, generate_auth_token(conn, salt))
    |> render("index.html")
  end 

  defp authenticate(conn, _opts) do 
	  if conn.assigns.current_user() do 
	  	conn 
  	else 
	  	conn
	  	|> put_flash(:error, "You must be signed in to access that page.")
	  	|> redirect(to: player_path(conn, :new))
	  	|> halt()
	  end
  end

 defp generate_auth_token(conn, salt) do
  current_player = get_session(conn, :current_player)
  Phoenix.Token.sign(conn, "salt", current_player)
 end

 defp random_string(length) do
  :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
 end


end