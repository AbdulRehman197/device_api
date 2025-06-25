defmodule DeviceApi.UserRepo do
  use Ecto.Repo,
    otp_app: :device_api,
    adapter: Ecto.Adapters.SQLite3
end

defmodule DeviceApi.DeviceRepo do
  use Ecto.Repo,
    otp_app: :device_api,
    adapter: Ecto.Adapters.SQLite3
end


