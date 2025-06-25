defmodule DeviceApi.UserRepo.Migrations.CreateUser do
  use Ecto.Migration
def change do
  create table(:users) do
      add :email, :string
      add :username, :string
      add :password_hash, :string
      add :firstname, :string
      add :lastname, :string
      add :publickey, :map
      add :devices, {:array, :string}
      add :masterkeyexam, :string

      timestamps()
    end

    create unique_index(:users, [:username])
end
end
