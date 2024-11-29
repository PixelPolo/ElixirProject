# ===========
# Build Stage
# ===========
FROM elixir:1.17-alpine as build

# Set the environment to production
ENV MIX_ENV=prod

# Install build tools and dependencies
RUN apk add --no-cache build-base git

# Set the working directory inside the container
WORKDIR /app

# Copy the project files into the container
COPY . .

# Install dependencies, compile the project, and build the release
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix compile && \
    mix release

# =================
# Deployment Stage
# =================
FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache libstdc++ ncurses

# Set runtime environment variables with default values
ENV REPLACE_OS_VARS=true \
    PORT=8000 \
    SIMULATED_COORDS_LAT=0.00 \
    SIMULATED_COORDS_LON=0.00

# Set the working directory inside the container
WORKDIR /opt/app

# Copy the built release from the build stage
COPY --from=build /app/_build/prod/rel/loadbalancer .

# Add a start script to dynamically set variables
COPY <<EOF /start.sh
#!/bin/sh
if [ -z "$SIMULATED_COORDS_LAT" ] || [ -z "$SIMULATED_COORDS_LON" ]; then
  echo "Error: SIMULATED_COORDS_LAT and SIMULATED_COORDS_LON are required"
  exit 1
fi

echo "Starting Load Balancer with coordinates LAT=$SIMULATED_COORDS_LAT, LON=$SIMULATED_COORDS_LON"
exec bin/loadbalancer start
EOF

RUN chmod +x /start.sh

# Expose the port used by the Load Balancer
EXPOSE 8000

# Use the start script as the entrypoint
ENTRYPOINT ["/start.sh"]
