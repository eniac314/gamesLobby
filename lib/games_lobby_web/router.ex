defmodule GamesLobbyWeb.Router do
  use GamesLobbyWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug GamesLobbyWeb.Plugs.PlayerAuthPlug, repo: GamesLobby.Repo
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GamesLobbyWeb do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/game", GamesController, :index
    resources "/players", PlayerController
    resources "/sessions", PlayerSessionController, only: [:new, :create, :delete]
    get "/sessions/sign-out", PlayerSessionController, :delete
  end

  # Other scopes may use custom stacks.
  # scope "/api", GamesLobbyWeb do
  #   pipe_through :api
  # end
end
