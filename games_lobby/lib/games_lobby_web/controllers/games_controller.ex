defmodule GamesLobbyWeb.GamesController do 
  use GamesLobbyWeb, :controller
  plug :authenticate when action in [:index]
  
  def index(conn,  params) do
    {path, template} = get_path_and_tenplate(params)
    salt = random_string(64)
    
    conn 
    |> assign(:auth_salt, salt)
    |> assign(:auth_token, generate_auth_token(conn, salt))
    |> assign(:custom_css, true)
    |> assign(:elm_app_path, path)
    |> render(template)
  end 

  defp authenticate(conn, _opts) do 
	  if conn.assigns.current_player() do 
	  	conn 
  	else 
	  	conn
	  	|> put_flash(:error, "You must be signed in to access that page.")
	  	|> redirect(to: player_path(conn, :new))
	  	|> halt()
	  end
  end

 defp generate_auth_token(conn, salt) do
  current_player = Map.get(conn.assigns, :current_player)
  # IO.inspect(current_player)
  Phoenix.Token.sign(conn, salt, current_player)
 end

 defp random_string(length) do
  :crypto.strong_rand_bytes(length) |> Base.url_encode64 |> binary_part(0, length)
 end
 
 defp get_path_and_tenplate(params) do 
   case Map.get(params, "game_name") do 
     "hexaboard" -> 
       {"/js/hexaboard.js", "hexaboard.html"}
     _ -> 
       {"/js/app.js", "index.html"} 
   end
 end 


end
