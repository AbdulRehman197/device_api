defmodule DeviceApiWeb.API.UserController do
  use DeviceApiWeb, :controller
  alias Plug.Conn

  alias DeviceApi.Users.Users

 @spec user_exist(Conn.t(), map()) :: Conn.t()
  def user_exist(conn, %{"username" => username}) do
    dbg(username)
    case Users.is_user_exist?(username) do
      true -> json(conn, %{exists: true})
      false -> json(conn, %{exists: false})
    end
  end
end
