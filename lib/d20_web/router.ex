defmodule D20Web.Router do
  use D20Web, :router

  import D20Web.Module, only: [put_module_cors_headers: 2]
  import D20Web.UserAuth

  pipeline :inertia do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_current_scope_for_actor
    plug :put_actor_token
    plug :fetch_live_flash
    plug :put_root_layout, html: {D20Web.Layouts, :inertia_root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Inertia.Plug
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_current_scope_for_actor
    plug :put_actor_token
    plug :fetch_live_flash
    plug :put_root_layout, html: {D20Web.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :modules do
    plug :put_module_cors_headers
    plug :accepts, ["json"]
    plug :fetch_session
    plug :fetch_current_scope_for_actor
    plug :put_secure_browser_headers
  end

  scope "/", D20Web do
    pipe_through :inertia

    get "/", PageController, :home
    get "/developers", PageController, :developers
    get "/games", PageController, :games
    get "/games/:slug", PageController, :game
    post "/games/:slug/sessions", PageController, :create_game_session
  end

  scope "/developers/specs" do
    get "/:slug/raw", D20Web.Plugs.AsyncApi, :raw
    get "/:slug", D20Web.Plugs.AsyncApi, :reference
  end

  scope "/", D20Web do
    pipe_through :modules

    options "/modules/:slug", ModuleController, :options
    post "/modules/:slug", ModuleController, :create
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:d20, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: D20Web.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", D20Web do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  scope "/", D20Web do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  scope "/", D20Web do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
