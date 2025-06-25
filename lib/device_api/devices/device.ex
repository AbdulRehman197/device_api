defmodule DeviceApi.Devices.Device do
  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder,
           only: [:device_id, :os, :browser, :latitute, :longitute, :timezone, :users]}

  schema "devices" do
    field :device_id, :string
    field :os, :string
    field :browser, :string
    field :latitute, :float
    field :longitute, :float
    field :timezone, :string
    field :ip, :string
    field :users, {:array, :string}

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(device, attrs) do
    device
    |> cast(attrs, [:device_id, :os, :browser, :latitute, :longitute, :timezone, :ip])
    |> validate_required([:device_id, :os, :browser])
  end
end
