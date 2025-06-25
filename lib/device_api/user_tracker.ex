# lib/my_app/user_tracker.ex
defmodule DeviceApi.UserTracker do
  use GenServer

  @name __MODULE__

  def start_link(_), do: GenServer.start_link(__MODULE__, %{}, name: @name)

  def init(state), do: {:ok, state}

  def register(user_id, pid), do: GenServer.call(@name, {:register, user_id, pid})
  def unregister(pid), do: GenServer.call(@name, {:unregister, pid})
  def get_pid(user_id), do: GenServer.call(@name, {:get, user_id})

  def handle_call({:register, user_id, pid}, _from, state) do
    {:reply, :ok, Map.put(state, user_id, pid)}
  end

  def handle_call({:unregister, pid}, _from, state) do
    new_state = Enum.reduce(state, %{}, fn {k, v}, acc ->
      if v == pid, do: acc, else: Map.put(acc, k, v)
    end)

    {:reply, :ok, new_state}
  end

  def handle_call({:get, user_id}, _from, state) do
    {:reply, Map.get(state, user_id), state}
  end
end
