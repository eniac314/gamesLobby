defmodule GamesLobbyWeb.PageController do
  use GamesLobbyWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
