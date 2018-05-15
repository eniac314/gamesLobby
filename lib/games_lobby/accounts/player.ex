defmodule GamesLobby.Accounts.Player do
  use Ecto.Schema
  import Ecto.Changeset
  alias GamesLobby.Accounts.Player


  schema "players" do
    field :high_score, :integer, default: 0
    field :username, :string, unique: true
    field :password, :string, virtual: true
    field :password_digest, :string
    field :is_admin, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(%Player{} = player, attrs) do
    player
    |> cast(attrs, [:username, :password, :high_score, :is_admin])
    |> validate_required([:username])
    |> unique_constraint(:username)
    |> validate_length(:password, min: 6, max: 100)
    |> validate_length(:username, min: 2, max: 100)
    |> put_pass_digest()
  end

  # @doc false
  # def registration_changeset(%PLayer{} = player, attrs) do 
  #   player
  #   |> cast(attrs, [:password, :username])
  #   |> validate_constraint(:username)
  #   |> unique_constraint(:username)
  #   |> validate_length(:password, min: 6, max: 100)
  #   |> validate_length(:username, min: 2, max: 100)
  #   |> put_pass_digest()
  # end

  defp put_pass_digest(changeset) do 
    case changeset do 
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_digest, Comeonin.Bcrypt.hashpwsalt(pass))
      _ -> 
        changeset
    end
  end


end
