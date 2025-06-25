defmodule DeviceApi.RegisteredDevices.Devices do
  use Ecto.Schema
  import Ecto.Changeset

  schema "registered_devices" do
    field :device_id, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(devices, attrs) do
    devices
    |> cast(attrs, [:device_id])
    |> validate_required([:device_id])
  end
end
