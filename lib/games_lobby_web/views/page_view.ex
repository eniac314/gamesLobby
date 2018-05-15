defmodule GamesLobbyWeb.PageView do
  use GamesLobbyWeb, :view
  
  def ws_url do
    System.get_env("WS_URL") || GamesLobbyWeb.Endpoint.config(:ws_url)
  end
end
