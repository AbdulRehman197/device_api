defmodule DeviceApiWeb.DeviceChannel do
  use DeviceApiWeb, :channel
  alias DeviceApi.UserTracker
  alias DeviceApi.Users.Users
  @impl true
  def join("user:" <> user_id, _payload, socket) do
    dbg(self())
    dbg(socket.channel_pid)
    dbg(user_id)
    UserTracker.register(user_id, socket.channel_pid)
    send(self(), :after_join)
    {:ok, socket}
  end

  @impl true
  def terminate(_reason, socket) do
    dbg(socket.channel_pid)
    UserTracker.unregister(socket.channel_pid)
    :ok
  end

  @impl true
  def handle_info(:after_join, socket) do
    case DeviceDBManager.get_db(socket.assigns.device_id) do
      {:error, reason} ->
        {:ok, _conn} = DeviceDBManager.create_db(socket.assigns.device_id)
        dbg(reason)

      {:ok, conn} ->
        dbg(conn)
    end

    # push(socket, "message", %{status: "connected", device_id: socket.assigns.device_id})
    # dbg(socket.id)
    {:noreply, socket}
  end

  @impl true
  def handle_in("new_packet", %{"packet" => content}, socket) do
    device_id = socket.assigns.device_id

    broadcast_from!(socket, "broadcast", %{
      from: device_id,
      packet: content
    })

    {:noreply, socket}
    # {:reply, :ok, socket}
  end

  @impl true
  def handle_in("ack", %{"packet" => content}, socket) do
    dbg(content)
    dbg(socket.assigns.device_id)
    dbg(socket.assigns.user_id)
    device_id = socket.assigns.device_id

    %{
      "core" => core,
      "details" => details,
      "doreId" => dore_id,
      "packetNo" => packet_no,
      "workspaceId" => workspace_id
    } = content

    {:ok, packet_no} = DeviceDBOps.insert_packet(device_id, core, dore_id, workspace_id)
    dbg(packet_no)
    DeviceDBOps.insert_detail(device_id, packet_no, details)

    case Users.get_user(socket.assigns.user_id) do
      nil ->
        :ok

      user ->
        save_ref_to_other_databases(user.devices, device_id, packet_no)
    end

    {:noreply, socket}
  end

  # Add authorization logic here as required.
  # defp authorized?(_payload) do
  #   true
  # end

  def save_ref_to_other_databases(deivces, device_id, packet_no) do
    Enum.each(deivces, fn device ->
      # dbg(device)

      if device != device_id do
        dbg(device)

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
