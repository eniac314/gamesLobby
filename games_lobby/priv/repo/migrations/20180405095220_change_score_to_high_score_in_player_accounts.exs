defmodule GamesLobby.Repo.Migrations.ChangeScoreToHighScoreInPlayerAccounts do
  use Ecto.Migration

  def change do
    rename table("players"), :score, to: :high_score
  end
end
