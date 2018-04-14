defmodule GamesLobbyWeb.LobbyChannel do 

use GamesLobbyWeb, :channel 

  def join("lobby:" <> _subtopic, _params, socket) do 
	  send(self(), :after_join)
    {:ok, socket}
  end 
  

  def handle_info(:after_join, socket) do 
    push(socket, "greetings", %{content: "Joined in all right!"})
    IO.inspect(socket)
    {:noreply, socket}
  end  

end 