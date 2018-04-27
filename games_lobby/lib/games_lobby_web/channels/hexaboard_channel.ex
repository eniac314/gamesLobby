defmodule GamesLobbyWeb.HexaboardChannel do 
  use GamesLobbyWeb, :channel
  alias GamesLobbyWeb.Presence

  def join("hexaboard:chat", _params, socket) do 
    send(self(), {:after_join, "chat"})
    {:ok, socket}
  end

end 