defmodule DeviceApi.Devices do
  @moduledoc """
  Context module for interacting with the devices table.
  """
  alias DeviceApi.DeviceRepo, as: Repo
  alias DeviceApi.Devices.Device

  # Get a device by ID
  def get_device(device_id) do
    # Repo.get(Device, device_id)
    Repo.get_by(Device, device_id: device_id)
  end

  # Create a new device (only if not exists)
  def create_device(attrs) do
    %Device{}
    |> Device.changeset(attrs)
    |> Repo.insert()
  end

  # Update a device
  def update_device(%Device{} = device, attrs) do
    device
    |> Device.changeset(attrs)
    |> Repo.update()
  end

  # update user id list
  def update_device_users(device_id, user_id) do
    case device = get_device(device_id) do
      nil ->
        {:error, "Device not found"}

      _ ->
        if Enum.member?(device.users, user_id) do
          {:error, "User already exists"}
        else
          current_users = device.users || []
          users = current_users ++ [user_id]

          device
          |> Ecto.Changeset.change(%{users: users})
          |> Repo.update()
        end
    end
  end

  # Upsert: insert if missing, or update if exists
  def upsert_device(attrs) do
    %Device{}
    |> Device.changeset(attrs)
    |> Repo.insert(conflict_target: :id, on_conflict: {:replace_all_except, [:id, :inserted_at]})
  end

  # List all devices
  def list_devices do
    Repo.all(Device)
  end

  # Delete a device
  def delete_device(%Device{} = device) do
    Repo.delete(device)
  end
end
