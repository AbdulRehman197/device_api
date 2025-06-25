defmodule DeviceApiWeb.API.RegistrationController do
  use DeviceApiWeb, :controller

  alias Ecto.Changeset
  alias Plug.Conn
  alias DeviceApi.Devices
  @spec create(Conn.t(), map()) :: Conn.t()
  def create(conn, %{"user" => user_params}) do
    # dbg(user_params)
    [{:app_password, app_password} | _] = Application.get_env(:device_api, :app_password)
    dbg(app_password)
    dbg(user_params["app_password"])

    dbg(
      user_params["app_password"] ==
        app_password
    )

    cond do
      user_params["app_password"] == app_password ->
        user_params = Map.drop(user_params, [:app_password])
        conn
        |> Pow.Plug.create_user(user_params)
        |> case do
          {:ok, user, conn} ->
            Devices.update_device_users(
              user_params["device_id"],
              Integer.to_string(user.id)
            )

            json(conn, %{
              user: user,
              data: %{
                access_token: conn.private.api_access_token,
                renewal_token: conn.private.api_renewal_token
              }
            })

          {:error, changeset, conn} ->
            errors =
              Changeset.traverse_errors(changeset, fn {msg, opts} ->
                Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
                  opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
                end)
              end)

            conn
            |> put_status(500)
            |> json(%{error: %{status: 500, message: "Couldn't create user", errors: errors}})
        end

      true ->
        conn
        |> put_status(401)
        |> json(%{error: %{status: 401, message: "Invalid app password"}})
    end
  end
end
