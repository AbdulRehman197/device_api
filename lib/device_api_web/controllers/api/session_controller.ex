defmodule DeviceApiWeb.API.SessionController do
  use DeviceApiWeb, :controller

  alias DeviceApiWeb.APIAuthPlug
  alias Plug.Conn
  alias DeviceApi.Users.Users
  alias DeviceApi.Devices

  @spec create(Conn.t(), map()) :: Conn.t()
  def create(conn, %{"user" => user_params}) do
    conn
    |> Pow.Plug.authenticate_user(user_params)
    |> case do
      {:ok, conn} ->
        dbg(conn.assigns.current_user)

        with {:ok, _user_updated} <-
               Users.append_device_to_user(
                 conn.assigns.current_user,
                 user_params["device_id"]
               ),
             {:ok, _device_updated} <-
               Devices.update_device_users(
                 user_params["device_id"],
                 Integer.to_string(conn.assigns.current_user.id)
               ) do
          {:ok, %{message: "User and device updated"}}
        else
          _ ->
            {:error, "Unexpected error"}
        end

        json(conn, %{
          user: conn.assigns.current_user,
          data: %{
            access_token: conn.private.api_access_token,
            renewal_token: conn.private.api_renewal_token
          }
        })

      {:error, conn} ->
        conn
        |> put_status(401)
        |> json(%{error: %{status: 401, message: "Invalid username or password"}})
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
