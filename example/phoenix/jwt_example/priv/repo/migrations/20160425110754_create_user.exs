defmodule JwtExample.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
        add :email, :string, null: false
        add :password, :string, virtual: true
        add :password_hash, :string

      timestamps
    end

  end
end
