defmodule DeviceApiWeb.API.DeviceController do
  use DeviceApiWeb, :controller
  alias DeviceApi.Devices

  def index(conn, _params) do
    devices = Devices.list_devices()
    json(conn, devices)
  end

  def create(conn, %{"device" => device_params}) do
    case Devices.create_device(device_params) do
      {:ok, device} -> json(conn, device)
      {:error, _changeset} -> conn |> put_status(400) |> json(%{error: "Invalid data"})
    end
  end
end
