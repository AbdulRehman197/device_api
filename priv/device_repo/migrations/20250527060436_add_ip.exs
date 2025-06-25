defmodule DeviceApi.DeviceRepo.Migrations.AddIp do
  use Ecto.Migration

  def change do
    alter table(:devices) do
      add :ip, :string
    end
  end
end
