defmodule DeviceDBOps do
  @moduledoc """
  Performs CRUD operations on device in-memory DBs managed by DeviceDBManager.
  Uses proper Exqlite API: prepare, bind, step, release.
  """

  alias Exqlite.Sqlite3
  alias DeviceDBManager

  # Helper to get connection or return error
  defp with_conn(device_id, fun) do
    case DeviceDBManager.get_db(device_id) do
      {:ok, conn} ->
        fun.(conn)

      {:error, _} = err ->
        err
    end
  end

  # Executes a statement with binding and releases afterward
  defp exec_stmt(conn, sql, params \\ []) do
    with {:ok, stmt} <- Sqlite3.prepare(conn, sql),
         :ok <- Sqlite3.bind(stmt, params),
         step_result <- Sqlite3.step(conn, stmt),
         :ok <- Sqlite3.release(conn, stmt) do
      case step_result do
        :done -> :ok
        :row -> {:error, :unexpected_row}
        other -> {:error, other}
      end
    else
      error -> error
    end
  end

  # Executes a query that returns one row
  defp query_one(conn, sql, params \\ []) do
    with {:ok, stmt} <- Sqlite3.prepare(conn, sql),
         :ok <- Sqlite3.bind(stmt, params),
         step_result <- Sqlite3.step(conn, stmt) do
      case step_result do
        :row ->
          {:ok, row} = Sqlite3.columns(conn, stmt)
          :ok = Sqlite3.release(conn, stmt)
          {:ok, row}

        :done ->
          :ok = Sqlite3.release(conn, stmt)
          {:error, :not_found}

        other ->
          :ok = Sqlite3.release(conn, stmt)
          {:error, other}
      end
    else
      error -> error
    end
  end

  # Executes a query that returns all rows
  defp query_all(conn, sql, params \\ []) do
    with {:ok, stmt} <- Sqlite3.prepare(conn, sql),
         :ok <- Sqlite3.bind(stmt, params),
         step_result <- Sqlite3.step(conn, stmt) do
      case step_result do
        :row ->
          {:ok, rows} = Sqlite3.columns(conn, stmt)
          :ok = Sqlite3.release(conn, stmt)
          {:ok, rows}

        :done ->
          :ok = Sqlite3.release(conn, stmt)
          {:ok, []}

        other ->
          :ok = Sqlite3.release(conn, stmt)
          {:error, other}
      end
    end
  end

  ## ====== PacketTable ======

  def insert_packet(device_id, core_action_type, doer_id, workspace_id) do
    sql = """
    INSERT INTO PacketTable (Core_Action_Type, Doer_ID_User_ID, WorkSpace_ID)
    VALUES (?, ?, ?);
    """

    with_conn(device_id, fn conn ->
      exec_stmt(conn, sql, [core_action_type, doer_id, workspace_id])

      {:error, {:row, [row_id]}} = query_one(conn, "SELECT last_insert_rowid();")

      {:error, {:row, [packet_id | _]}} =
        query_one(conn, "SELECT * FROM PacketTable WHERE id = ?;", [row_id])

      {:ok, packet_id}
    end)
  end

  def get_packet_by_id(device_id, id) do
    sql = "SELECT * FROM PacketTable WHERE id = ?;"

    with_conn(device_id, fn conn ->
      query_one(conn, sql, [id])
    end)
  end

  def fetch_all_packets(device_id) do
    sql = "SELECT * FROM PacketTable;"

    with_conn(device_id, fn conn ->
      query_one(conn, sql)
    end)
  end

  def update_packet(device_id, id, core_action_type, doer_id, workspace_id) do
    sql = """
    UPDATE PacketTable SET Core_Action_Type = ?, Doer_ID_User_ID = ?, WorkSpace_ID = ?
    WHERE id = ?;
    """

    with_conn(device_id, fn conn ->
      exec_stmt(conn, sql, [core_action_type, doer_id, workspace_id, id])
    end)
  end

  def delete_packet(device_id, id) do
    sql = "DELETE FROM PacketTable WHERE id = ?;"

    with_conn(device_id, fn conn ->
      exec_stmt(conn, sql, [id])
    end)
  end

  def get_all_packets(device_id) do
    get_all_rows(device_id, "PacketTable")
  end

  ## ====== Details ======

  def insert_detail(device_id, packet_id, encrypted_data) do
    sql = "INSERT INTO Details (PacketTable_ID, Detail_Encrypted_Data) VALUES (?, ?);"

    with_conn(device_id, fn conn ->
      exec_stmt(conn, sql, [packet_id, encrypted_data])
    end)
  end

  def get_detail_by_packet_id(device_id, packet_id) do
    sql = "SELECT * FROM Details WHERE PacketTable_ID = ?;"

    with_conn(device_id, fn conn ->
      query_one(conn, sql, [packet_id])
    end)
  end

  def update_detail(device_id, packet_id, new_data) do
    sql = "UPDATE Details SET Detail_Encrypted_Data = ? WHERE PacketTable_ID = ?;"

    with_conn(device_id, fn conn ->
      exec_stmt(conn, sql, [new_data, packet_id])
    end)
  end

  def delete_detail(device_id, packet_id) do
    sql = "DELETE FROM Details WHERE PacketTable_ID = ?;"

    with_conn(device_id, fn conn ->
      exec_stmt(conn, sql, [packet_id])
    end)
  end

  def get_all_details(device_id) do
    get_all_rows(device_id, "Details")
  end

  ## ====== DatabaseRef ======

  def insert_database_ref(device_id, name, source_fk) do
    sql = "INSERT INTO DatabaseRef (Source_Device_DB_Name, Source_Device_FK) VALUES (?, ?);"

    with_conn(device_id, fn conn ->
      exec_stmt(conn, sql, [name, source_fk])
    end)
  end

  def get_database_ref_by_id(device_id, id) do
    sql = "SELECT * FROM DatabaseRef WHERE id = ?;"

    with_conn(device_id, fn conn ->
      query_one(conn, sql, [id])
    end)
  end

  def update_database_ref(device_id, id, name, source_fk) do
    sql = """
    UPDATE DatabaseRef SET Source_Device_DB_Name = ?, Source_Device_FK = ?
    WHERE id = ?;
    """

    with_conn(device_id, fn conn ->
      exec_stmt(conn, sql, [name, source_fk, id])
    end)
  end

  def delete_database_ref(device_id, id) do
    sql = "DELETE FROM DatabaseRef WHERE id = ?;"

    with_conn(device_id, fn conn ->
      exec_stmt(conn, sql, [id])
    end)
  end

  def get_all_database_refs(device_id) do
    get_all_rows(device_id, "DatabaseRef")
  end

  @allowed_tables ~w(PacketTable Details DatabaseRef)

  def get_all_rows(device_id, table_name) when table_name in @allowed_tables do
    with_conn(device_id, fn conn ->
      sql = "SELECT * FROM #{table_name};"

      with {:ok, stmt} <- Sqlite3.prepare(conn, sql),
           {:ok, rows} <- Sqlite3.fetch_all(conn, stmt),
           :ok <- Sqlite3.release(conn, stmt) do
        {:ok, rows}
      else
        error -> error
      end
    end)
  end

  def get_all_rows(_, _), do: {:error, :invalid_table}
end
