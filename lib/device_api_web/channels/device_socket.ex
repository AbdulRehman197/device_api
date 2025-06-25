defmodule DeviceApiWeb.DeviceSocket do
  @behaviour Phoenix.Socket.Transport
  alias DeviceApiWeb.SocketRegistry
  alias DeviceApi.Users.Users

  def child_spec(_opts) do
    Registry.child_spec(keys: :unique, name: SocketRegistry)
  end

  def connect(state) do
    dbg(state)

    %{
      params: %{"token" => token, "device_id" => device_id},
      connect_info: %{pow_config: config}
    } = state

    %Plug.Conn{secret_key_base: DeviceApiWeb.Endpoint.config(:secret_key_base)}
    |> DeviceApiWeb.APIAuthPlug.get_credentials(
      token,
      config
    )
    |> case do
      nil ->
        {:error, Jason.encode!(%{status: "unauthorized"})}

      {user, metadata} ->
        fingerprint = Keyword.fetch!(metadata, :fingerprint)
        dbg(fingerprint)

        state =
          state
          |> Map.put(:assigns, %{})
          |> assign(:session_fingerprint, fingerprint)
          |> assign(:user_id, user.id)
          |> assign(:device_id, String.trim(device_id))

        state = state |> assign(:socket_id, id(state))
        {:ok, state}
    end
  end

  def init(state) do
    # Now we are effectively inside the process that maintains the socket.
    Registry.register(SocketRegistry, state.assigns.device_id, self())

    case DeviceDBManager.get_db(state.assigns.device_id) do
      {:error, _reason} ->
        {:ok, _conn} = DeviceDBManager.create_db(state.assigns.device_id)

      {:ok, _conn} ->
        nil
    end

    # send_private(state.assigns.device_id, state.assigns.device_id, %{
    #   message: "Hello from #{state.assigns.device_id}"
    # })

    {:ok, state}
  end

  def handle_in({text, _opts}, state) do
    dbg(Jason.decode!(text))

    case Jason.decode!(text) do
      %{"event" => "new_packet", "payload" => %{"packet" => msg}} ->
        case WorkspaceDevices.get_devices(msg["workspaceId"]) do
          [] ->
            WorkspaceDevices.add_device(
              msg["workspaceId"],
              state.assigns.device_id
            )

          devices ->
            Enum.each(devices, fn device ->
              if device != state.assigns.device_id do
                send_private(state.assigns.device_id, device, msg)
              end
            end)

            WorkspaceDevices.add_device(
              msg["workspaceId"],
              state.assigns.device_id
            )
        end

      %{"event" => "ack", "payload" => %{"packet" => msg}} ->
        handle_incoming_message(msg, state)
    end

    {:ok, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  # Send outgoing message to socket
  def handle_info({:send_message, msg}, state) do
    dbg(msg)
    {:push, {:text, Jason.encode!(msg)}, state}
  end

  defp send_private(sender, recipient, msg) do
    message = %{"event" => "private", "from" => sender, "packet" => msg}

    case Registry.lookup(SocketRegistry, recipient) do
      [{pid, _}] ->
        send(pid, {:send_message, message})

      [] ->
        dbg("User #{recipient} not found")
    end
  end

  defp broadcast_all(sender, msg) do
    message = %{"event" => "broadcast", "from" => sender, "packet" => msg}

    for device_id <- Registry.select(SocketRegistry, [{{:"$1", :_, :_}, [], [:"$1"]}]) do
      if device_id != sender do
        case Registry.lookup(SocketRegistry, device_id) do
          [{pid, _}] ->
            send(pid, {:send_message, message})

          [] ->
            dbg("User #{device_id} not found")
        end
      end
    end
  end

  @spec id(%{
          :assigns => %{:device_id => any(), optional(any()) => any()},
          optional(any()) => any()
        }) :: binary()
  def id(%{assigns: %{device_id: device_id}}),
    do: device_id

  defp assign(%{assigns: assigns} = state, key, value) do
    updated_assigns = Map.put(assigns, key, value)
    %{state | assigns: updated_assigns}
  end

  defp handle_incoming_message(msg, state) do
    %{
      "core" => core,
      "details" => details,
      "doreId" => doer_id,
      "packetNo" => _packet_no,
      "workspaceId" => workspace_id
    } = msg

    {:ok, packet_no} =
      DeviceDBOps.insert_packet(state.assigns.device_id, core, doer_id, workspace_id)

    DeviceDBOps.insert_detail(state.assigns.device_id, packet_no, details)

    case Users.get_user(state.assigns.user_id) do
      nil ->
        :ok

      user ->
        save_ref_to_other_databases(user.devices, state.assigns.device_id, packet_no)
    end
  end

  def save_ref_to_other_databases(deivces, device_id, packet_no) do
    Enum.each(deivces, fn device ->
      if device != device_id do
        DeviceDBOps.insert_database_ref(
          device,
          device_id,
          packet_no
        )
      end
    end)

    packets = DeviceDBOps.get_all_packets(device_id)
    details = DeviceDBOps.get_all_details(device_id)
    packets_refs = DeviceDBOps.get_all_database_refs(device_id)
    dbg(packets)
    dbg(details)
    dbg(packets_refs)
  end
end
