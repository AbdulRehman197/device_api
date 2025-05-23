defmodule DeviceApi.DeviceRegistry do
  use Agent

  def start_link(_), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  def save(device_id, socket_id), do: Agent.update(__MODULE__, &Map.put(&1, device_id, socket_id))

  def get(), do: Agent.get(__MODULE__, & &1)
end
