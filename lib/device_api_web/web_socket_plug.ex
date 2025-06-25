defmodule DeviceApiWeb.WebSocketPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    Phoenix.Endpoint.Cowboy2Handler.upgrade(
      conn,
      DeviceApiWeb.RawSocket,
      [],
      %{compress: false}
    )
  end
end
