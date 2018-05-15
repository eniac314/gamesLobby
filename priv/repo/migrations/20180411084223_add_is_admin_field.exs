defmodule GamesLobby.Repo.Migrations.AddIsAdminField do
  use Ecto.Migration

  def change do
  	alter table(:players) do 
  		add :is_admin, :boolean, default: false
  	end
  end
end
