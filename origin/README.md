# Origin Server

Created a Phoenix project without Ecto and LiveView for static content delivery:

```bash
mix phx.new origin --no-ecto --no-live
```

## Modifications made

### Overview

- **Controller**:
  - Created a new `snake_controller.ex` to handle requests to the `/snake` route.
  
- **Action**:
  - Defined an action inside the controller to serve the `snake.html.heex` template.
  
- **Static Files**:
  - Added `snake.css` and `snake.js` files in the `assets` folder for styling and functionality.
  
- **Configuration**:
  - Updated `config.exs` to ensure the `snake.js` file is included in the esbuild build process.
  - Modified the Tailwind configuration in `config.exs` to include `snake.css` for styling.
  
- **Router**:
  - Introduced a custom logging pipeline for the `/snake` route to log detailed connection information (method, host, and IP address).
  
### Custom Pipeline and Routing

The following code snippet defines the custom pipeline for logging and the `/snake` route:

```elixir
# Custom pipeline for logging requests to /snake
pipeline :snake_pipeline do
  plug :introspect
end

# Log connection details (method, host, and IP address)
defp introspect(conn, _opts) do
  ip = conn.remote_ip |> Tuple.to_list() |> Enum.join(".")
  Logger.info("""
  Verb: #{inspect(conn.method)}
  Host: #{inspect(conn.host)}
  From IP: #{ip}
  """)
  conn
end

# Define /snake route with custom logging pipeline
scope "/snake", OriginWeb do
  pipe_through [:browser, :snake_pipeline]
  get "/", SnakeController, :snake
end
```

## Run without docker

```bash
mix deps.get
mix assets.deploy
mix phx.server
```

## Dockerisation

### Dockerfile with a release

```bash
mix phx.gen.secret
export SECRET_KEY_BASE=...  # Replace with the generated secret
mix deps.get --only prod
MIX_ENV=prod mix compile
MIX_ENV=prod mix assets.deploy
mix phx.gen.release --docker  # create a release and a Dockerfile
```

### How to run

```bash
# Build the Docker image
docker build -t origin .

# Run the Origin server container
docker run -p 4000:4000 --env SECRET_KEY_BASE=$(mix phx.gen.secret) --name origin origin
```

- Note : A `docker-compose.yml` is available for the overall project.
