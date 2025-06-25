defmodule DeviceApiWeb.UserSocket do
  use Phoenix.Socket

  require Logger

  # A Socket handler
  #
  # It's possible to control the websocket connection and
  # assign values that can be accessed by your channel topics.

  ## Channels
  # Uncomment the following line to define a "room:*" topic
  # pointing to the `DeviceApiWeb.RoomChannel`:
  #
  # channel "room:*", DeviceApiWeb.RoomChannel
  # channel "user:*", DeviceApiWeb.DeviceChannel
  #
  # To create a channel file, use the mix task:
  #
  #     mix phx.gen.channel Room
  #
  # See the [`Channels guide`](https://hexdocs.pm/phoenix/channels.html)
  # for further details.

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error` or `{:error, term}`. To control the
  # response the client receives in that case, [define an error handler in the
  # websocket
  # configuration](https://hexdocs.pm/phoenix/Phoenix.Endpoint.html#socket/3-websocket-configuration).
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.
  # @impl true
  # def connect(%{"deviceId" => device_id}, socket, _connect_info) do
  #   dbg("device_id: #{device_id}")
  #   # DeviceApi.DeviceRegistry.save(device_id, socket.id)
  #   {:ok, assign(socket, :device_id, device_id)}
  # end

  @impl true
  def connect(%{"token" => token, "device_id" => device_id} = _params, socket, %{
        pow_config: config
      }) do
    # dbg(token)
    dbg(DeviceApiWeb.Endpoint.config(:secret_key_base))

    %Plug.Conn{secret_key_base: socket.endpoint.config(:secret_key_base)}
    |> DeviceApiWeb.APIAuthPlug.get_credentials(
      token,
      config
    )
    |> case do
      nil ->
        :error

      {user, metadata} ->
        fingerprint = Keyword.fetch!(metadata, :fingerprint)

        socket =
          socket
          |> assign(:session_fingerprint, fingerprint)
          |> assign(:user_id, user.id)
          |> assign(:device_id, device_id)

        {:ok, socket}
    end
  end

  @impl true
  @spec id(%{
          :assigns => %{:session_fingerprint => any(), optional(any()) => any()},
          optional(any()) => any()
        }) :: <<_::64, _::_*8>>
  def id(%{assigns: %{session_fingerprint: session_fingerprint}}),
    do: "user_socket:#{session_fingerprint}"

  # @impl true
  # def connect(params, socket, _connect_info) do
  #   dbg(params)
  #   {:ok, socket}
  # end

  # Socket IDs are topics that allow you to identify all sockets for a given user:
  #
  # @impl true
  # def id(socket), do: "user_socket:#{socket.assigns.device_id}"

  # @impl true
  # def id(%{assigns: %{session_fingerprint: session_fingerprint}}),
  #   do: "user_socket:#{session_fingerprint}"

  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     Elixir.DeviceApiWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  # @impl true
  # def id(_socket), do: nil

  # def handle_info({:text, message}, state) do
  #   dbg(Jason.decode!(message))
  #   {:push, Jason.encode!(%{status: "ok"}), state}
  # end
end
