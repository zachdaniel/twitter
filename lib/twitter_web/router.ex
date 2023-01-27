defmodule TwitterWeb.Router do
  use TwitterWeb, :router
  use AshAuthentication.Phoenix.Router
  import AshAuthentication.Phoenix.LiveSession
  import AshAdmin.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {TwitterWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :load_from_session
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    # Pipe it through your browser pipeline
    pipe_through [:browser]

    ash_admin("/admin")
  end

  scope "/", TwitterWeb do
    pipe_through :browser

    reset_route []

    sign_in_route overrides: [
                    TwitterWeb.AuthOverrides,
                    AshAuthentication.Phoenix.Overrides.Default
                  ]

    sign_out_route AuthController
    auth_routes_for Twitter.Accounts.User, to: AuthController

    scope "/", TweetLive do
      ash_authentication_live_session :authenticated_tweets_root,
        on_mount: {AshHqWeb.LiveUserAuth, :live_user_required} do
        live "/", Index, :index
      end
    end

    scope "/tweets", TweetLive do
      ash_authentication_live_session :authenticated_tweets,
        on_mount: {AshHqWeb.LiveUserAuth, :live_user_required} do
        live "/", Index, :index
        live "/new", Index, :new
        live "/:id/edit", Index, :edit

        live "/:id", Show, :show
        live "/:id/show/edit", Show, :edit
      end
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", TwitterWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:twitter, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: TwitterWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
