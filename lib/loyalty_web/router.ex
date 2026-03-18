defmodule LoyaltyWeb.Router do
  use LoyaltyWeb, :router

  import LoyaltyWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LoyaltyWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Use this pipeline to verify app requests containing api keys
  # x-header-* not bearer tokens
  pipeline :api_key_authenticated do
    plug :accepts, ["json"]
    plug LoyaltyWeb.VerifyApiKeyPipeline
  end

  # api roures for mobile. :api_key_authenticated
  scope "/api/v1", LoyaltyWeb, as: :api_key_authenticated do
    pipe_through [:api, :api_key_authenticated]

    post "/join", Api.V1.LoyaltyController, :join_loyalty
    post "/leave", Api.V1.LoyaltyController, :leave_loyalty
    get "/purchases/:device_id", Api.V1.PurchaseController, :fetch

    post "/device-token", Api.V1.DeviceTokenController, :create

    get "/customer/:device_id", Api.V1.CustomerController, :fetch
    post "/purchase", Api.V1.PurchaseController, :create
    # new
    post "/redeem/reward", Api.V1.PointsController, :redeem
    get "/rewards/:device_id", Api.V1.PointsController, :fetch
    get "/reward_details/:device_id/:reward_id", Api.V1.PointsController, :reward_details

  end


  scope "/", LoyaltyWeb do
    pipe_through :browser
    get "/", PageController, :home
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:loyalty, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: LoyaltyWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", LoyaltyWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{LoyaltyWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      live "/dashboard", DashboardLive.Index
      live "/analytics", AnalyticsLive.Index
      live "/customers", CustomerLive.Index
      live "/loyalty_programs", LoyaltyProgramLive.Index
      live "/loyalty_programs/:id/rewards", RewardLive.Index, :index
      live "/promos", PromoLive.Index
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", LoyaltyWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{LoyaltyWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login , :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
