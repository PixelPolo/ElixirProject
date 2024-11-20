defmodule OriginWeb.Router do
  use OriginWeb, :router

  # Logger
  require Logger

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {OriginWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :snake_pipeline do
    plug :introspect
  end

  # Function plugs to log connexion info
  def introspect(conn, _opts) do
    ip = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")

    Logger.info("""
    Verb: #{inspect(conn.method)}
    Host: #{inspect(conn.host)}
    From IP: #{ip}}
    From IP: #{get(conn)}
    """)

    # Headers: #{inspect(conn.req_headers)}

    # Return the connexion
    conn
  end

  # https://stackoverflow.com/questions/39199899/how-to-get-client-ip-in-phoenix-rest-api
  def get(conn) do
    forwarded_for = List.first(Plug.Conn.get_req_header(conn, "x-forwarded-for"))

    if forwarded_for do
      String.split(forwarded_for, ",")
      |> Enum.map(&String.trim/1)
      |> List.first()
    else
      to_string(:inet_parse.ntoa(conn.remote_ip))
    end
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", OriginWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/snake", OriginWeb do
    pipe_through [:browser, :snake_pipeline]

    get "/", SnakeController, :snake
  end

  # Other scopes may use custom stacks.
  # scope "/api", OriginWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:origin, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: OriginWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
