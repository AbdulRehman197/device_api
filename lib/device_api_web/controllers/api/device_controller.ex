defmodule DeviceApiWeb.API.DeviceController do
  use DeviceApiWeb, :controller
  alias DeviceApi.Devices

  def index(conn, _params) do
    devices = Devices.list_devices()
    json(conn, devices)
  end

  def create(conn, %{"device" => device_params}) do
    device_id = generate()
    device_params = Map.put(device_params, "device_id", device_id)
    case Devices.create_device(device_params) do
      {:ok, device} -> json(conn, device.device_id)
      {:error, _changeset} -> conn |> put_status(400) |> json(%{error: "Invalid data"})
    end
  end

  def generate do
    # Convert to hex string
    :base64.encode(:crypto.strong_rand_bytes(32))
  end
end
