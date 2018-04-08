defmodule GamesLobby.Repo.Migrations.AddFieldsToPlayerAccounts do
  use Ecto.Migration

  def change do
  	alter table(:players) do 
  		add :password_digest, :string
  	end 

  	create unique_index(:players, [:username])

  end
end
