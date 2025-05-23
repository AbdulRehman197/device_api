defmodule DeviceApi.Users.Users do
  @moduledoc """
  Context module for interacting with the users table.
  """

  alias DeviceApi.UserRepo, as: Repo
  alias DeviceApi.Users.User
  import Ecto.Query, only: [from: 2]
  alias Pow.Ecto.Schema.Password
  # Get user by ID
  def get_user(id), do: Repo.get(User, id)

  # Get user by email (useful for login)
  def get_user_by_email(email), do: Repo.get_by(User, email: email)

  def is_user_exist?(username) do
    query = from u in User, where: u.username == ^username
    Repo.exists?(query)
  end

  # Create a user
  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  # Update a user
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  # Delete a user
  def delete_user(%User{} = user), do: Repo.delete(user)

  # List all users
  def list_users(), do: Repo.all(User)

  # Add device ID to user's device list
  def append_device_to_user(%User{} = user, device_id) when is_binary(device_id) do
    current_devices = user.devices || []
    updated_devices = Enum.uniq([device_id | current_devices])

    user
    |> Ecto.Changeset.change(%{devices: updated_devices})
    |> Repo.update()
  end

  # Remove device ID from user's device list
  def remove_device_from_user(%User{} = user, device_id) do
    updated_devices = Enum.filter(user.devices, fn d -> d != device_id end)
    update_user(user, %{devices: updated_devices})
  end

  def authenticate_by_username(username, password) do
    query = from u in User, where: u.username == ^username
    user = Repo.one(query)

    case user do
      nil ->
        {:error, "Invalid username or password"}

      %User{} = user ->
        if Password.pbkdf2_verify(password, user.password_hash) do
          {:ok, user}
        else
          {:error, "Invalid username or password"}
        end
    end
  end
end
