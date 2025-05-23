defmodule DeviceApiWeb.DeviceChannel do
  use DeviceApiWeb, :channel
  alias DeviceApi.Devices
  @impl true
  def join("device" <> device_id, payload, socket) do
    dbg(device_id)
    dbg(socket)

    if authorized?(payload) do
      device_id = socket.assigns.device_id
      # dbg(Devices.get_device(device_id))

      case Devices.get_device(device_id) do
        nil ->
          Devices.create_device(%{device_id: device_id, os: "ios", browser: "Chrome"})
        _ ->
          :ok
      end

      socket = assign(socket, :device_id, device_id)

      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    push(socket, "message", %{status: "connected", device_id: socket.assigns.device_id})
    # dbg(socket.id)
    {:noreply, socket}
  end

  @impl true
  def handle_in("send_message", %{"content" => content}, socket) do
    dbg(content)

    broadcast!(socket, "broadcast", %{
      from: socket.assigns.device_id,
      message: content
    })

    {:noreply, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (device:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
