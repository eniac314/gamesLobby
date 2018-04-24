defmodule Hexaboard do
  use Application
  
  def start(_type, _args) do 
    IO.puts("Starting the hexaboard application...")
    children = [
      {Registry, keys: :unique, name: Hexaboard.GameRegistry},
      Hexaboard.GameSupervisor
    ]
    
    opts = [strategy: :one_for_one, name: Hexaboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
