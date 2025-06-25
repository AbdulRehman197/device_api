defmodule WorkspaceDevices do
  @moduledoc """
  Manage devices related to each workspace using ETS.
  """

  # Public API

  @doc """
  Initializes an ETS table for the given workspace ID.
  """
  def init_table(workspace_id) when is_binary(workspace_id) do
    table_name = make_table_name(workspace_id)
    dbg(:ets.info(table_name))

    if :ets.info(table_name) == :undefined do
      :ets.new(table_name, [:bag, :public, :named_table])
    end

    :ok
  end

  @doc """
  Adds a device ID to the given workspace ID.
  """
  def add_device(workspace_id, device_id) do
    table_name = make_table_name(workspace_id)
    init_table(workspace_id)
    :ets.insert(table_name, {workspace_id, device_id})
  end

  @doc """
  Lists all device IDs for a given workspace ID.
  """
  def get_devices(workspace_id) do
    table_name = make_table_name(workspace_id)
    init_table(workspace_id)

    case :ets.lookup(table_name, workspace_id) do
      [] -> []
      entries -> Enum.map(entries, fn {_key, device_id} -> device_id end)
    end
  end

  @doc """
  Removes a specific device from a workspace.
  """
  def remove_device(workspace_id, device_id) do
    table_name = make_table_name(workspace_id)
    :ets.delete_object(table_name, {workspace_id, device_id})
  end

  @doc """
  Deletes all devices under the workspace (by deleting the ETS table).
  """
  def delete_workspace(workspace_id) do
    table_name = make_table_name(workspace_id)
    :ets.delete(table_name)
  end

  # Internal Helpers

  defp make_table_name(workspace_id) when is_binary(workspace_id) do
    prefix = String.slice(workspace_id, 0, 3)
    String.to_atom("W" <> prefix)
  end
end
