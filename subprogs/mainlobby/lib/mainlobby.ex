defmodule Mainlobby do
  use Application
  
  def start(_type, _args) do 
    IO.puts("Starting the mainlobby application...")
    children = [
      Mainlobby.MainlobbySupervisor
    ]
    
    opts = [strategy: :one_for_one, name: Mainlobby.Supervisor]
    res = Supervisor.start_link(children, opts)
    Mainlobby.MainlobbySupervisor.start_chat()
    Mainlobby.MainlobbySupervisor.start_game_setup()
    res
  end
end

