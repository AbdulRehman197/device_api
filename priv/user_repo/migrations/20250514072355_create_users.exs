defmodule DeviceApi.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :email, :string, null: false
      add :password_hash, :string
      add :firstname, :string
      add :lastname, :string
      add :publickey, :map
      add :devices, {:array, :string}
      add :masterkeyexam, :string

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
