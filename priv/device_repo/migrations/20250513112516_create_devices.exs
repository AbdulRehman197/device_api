defmodule DeviceApi.Repo.Migrations.CreateDevices do
  use Ecto.Migration

  def change do
    create table(:devices) do
      add :device_id, :string
      add :os, :string
      add :browser, :string
      add :latitute, :float
      add :longitute, :float
      add :timezone, :string
      add :users, {:array, :string}

      timestamps(type: :utc_datetime)
    end
  end
end
