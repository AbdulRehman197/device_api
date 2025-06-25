defmodule DeviceDBManager do
  use GenServer

  @moduledoc """
  Manages in-memory SQLite databases per device using Exqlite.
  Automatically creates three required tables on DB creation.
  """

  alias Exqlite.Sqlite3

  ### Public API ###

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
    # 445
    # {deiceabz123: Ref1,
    # device124: Ref2,
    # device125: Ref3}

  end

  def create_db(device_id) do
    GenServer.call(__MODULE__, {:create_db, device_id})
  end

  def get_db(device_id) do
    GenServer.call(__MODULE__, {:get_db, device_id})
  end

  def update_db(device_id, new_conn) do
    GenServer.call(__MODULE__, {:update_db, device_id, new_conn})
  end

  def delete_db(device_id) do
    GenServer.call(__MODULE__, {:delete_db, device_id})
  end

  ### GenServer Callbacks ###

  def init(state), do: {:ok, state}

  def handle_call({:create_db, device_id}, _from, state) do
    case Map.get(state, device_id) do
      nil ->
        dbg("Creating DB for #{device_id}")

        with {:ok, conn} <- Sqlite3.open(":memory:"),
             :ok <- setup_schema(conn) do
          {:reply, {:ok, conn}, Map.put(state, device_id, conn)}
          # Device 123, Ref 1
          # Device 124, Ref 2
          # Device 125, Ref 3
        else
          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end

      _ ->
        {:reply, {:error, :already_exists}, state}
    end
  end

  def handle_call({:get_db, device_id}, _from, state) do
    case Map.get(state, device_id) do
      nil -> {:reply, {:error, :not_found}, state}
      conn -> {:reply, {:ok, conn}, state}
    end
  end

  def handle_call({:update_db, device_id, new_conn}, _from, state) do
    if Map.has_key?(state, device_id) do
      {:reply, :ok, Map.put(state, device_id, new_conn)}
    else
      {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:delete_db, device_id}, _from, state) do
    case Map.pop(state, device_id) do
      {nil, _} ->
        {:reply, {:error, :not_found}, state}

      {conn, new_state} ->
        Sqlite3.close(conn)
        {:reply, :ok, new_state}
    end
  end

  ### Private helper to setup DB schema ###

  defp setup_schema(conn) do
    with :ok <-
           execute_sql(conn, """
             CREATE TABLE IF NOT EXISTS PacketTable (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               Core_Action_Type TEXT,
               Doer_ID_User_ID TEXT,
               WorkSpace_ID TEXT
             );
           """),
         :ok <-
           execute_sql(conn, """
             CREATE TABLE IF NOT EXISTS Details (
               PacketTable_ID INTEGER,
               Detail_Encrypted_Data TEXT,
               FOREIGN KEY (PacketTable_ID) REFERENCES PacketTable(id)
             );
           """),
         :ok <-
           execute_sql(conn, """
             CREATE TABLE IF NOT EXISTS DatabaseRef (
               id INTEGER PRIMARY KEY AUTOINCREMENT,
               Source_Device_DB_Name TEXT,
               Source_Device_FK INTEGER
             );
           """) do
      :ok
    end
  end

  defp execute_sql(conn, sql) do
    case Sqlite3.execute(conn, sql) do
      :ok -> :ok
      error -> error
    end
  end
end
