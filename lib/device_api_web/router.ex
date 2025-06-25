defmodule DeviceApiWeb.Router do
  use DeviceApiWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug Pow.Plug.Session, otp_app: :device_api
    plug DeviceApiWeb.APIAuthPlug, otp_app: :device_api
  end

  pipeline :api_protected do
    plug Pow.Plug.RequireAuthenticated, error_handler: DeviceApiWeb.APIAuthErrorHandler
  end

  scope "/api", DeviceApiWeb.API do
    pipe_through :api

    post "/users", UserController, :user_exist
    resources "/registration", RegistrationController, singleton: true, only: [:create]
    resources "/session", SessionController, singleton: true, only: [:create, :delete]
    post "/session/renew", SessionController, :renew
    resources "/devices", DeviceController, only: [:index, :create]
  end

  scope "/api", DeviceApiWeb.API do
    pipe_through [:api, :api_protected]

  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:device_api, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: DeviceApiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
