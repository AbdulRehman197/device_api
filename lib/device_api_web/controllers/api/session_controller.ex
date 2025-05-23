defmodule DeviceApiWeb.API.SessionController do
  use DeviceApiWeb, :controller

  alias DeviceApiWeb.APIAuthPlug
  alias Plug.Conn
  alias DeviceApi.Users.Users
  alias DeviceApi.Devices

  @spec create(Conn.t(), map()) :: Conn.t()
  def create(conn, %{
        "user" =>
          %{
            "username" => username,
            "password" => password
          } = user_params
      }) do
    # authenticate user by username and password
    Users.authenticate_by_username(username, password)
    |> case do
      {:ok, user} ->
        # fetch the pow config associated with the connection
        config = Pow.Plug.fetch_config(conn)
        # assigns the user to the connection
        Pow.Plug.assign_current_user(conn, user, config)
        # |> Pow.Plug.authenticate_user(user_params)
        # create the new session based on the user manually created
        |> APIAuthPlug.create(user, Pow.Plug.fetch_config(conn))
        |> case do
          {conn, user} ->
            # update the device associated with the user
            with {:ok, _user_updated} <-
                   Users.append_device_to_user(
                     user,
                     user_params["device_id"]
                   ),
                 {:ok, _device_updated} <-
                   Devices.update_device_users(
                     user_params["device_id"],
                     Integer.to_string(user.id)
                   ) do
              {:ok, %{message: "User and device updated"}}
            else
              _ ->
                {:error, "Unexpected error"}
            end

            json(conn, %{
              data: %{
                access_token: conn.private.api_access_token,
                renewal_token: conn.private.api_renewal_token
              }
            })
        end

      {:error, reason} ->
        conn
        |> put_status(401)
        |> json(%{error: %{status: 401, message: reason}})
    end
  end

  @spec renew(Conn.t(), map()) :: Conn.t()
  def renew(conn, _params) do
    config = Pow.Plug.fetch_config(conn)

    conn
    |> APIAuthPlug.renew(config)
    |> case do
      {conn, nil} ->
        conn
        |> put_status(401)
        |> json(%{error: %{status: 401, message: "Invalid token"}})

      {conn, _user} ->
        json(conn, %{
          data: %{
            access_token: conn.private.api_access_token,
            renewal_token: conn.private.api_renewal_token
          }
        })
    end
  end

  @spec delete(Conn.t(), map()) :: Conn.t()
  def delete(conn, _params) do
    conn
    |> Pow.Plug.delete()
    |> json(%{data: %{}})
  end
end
