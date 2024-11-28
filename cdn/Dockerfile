#===========
#Build Stage
#===========
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

#================
#Deployment Stage
#================
FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache libstdc++ ncurses

# Set runtime environment variables with default values
ENV REPLACE_OS_VARS=true \
    PORT=9000 \
    CITY=Fribourg

# Set the working directory inside the container
WORKDIR /opt/app

# Copy the built release from the build stage
COPY --from=build /app/_build/prod/rel/cdn .

# Expose the default port (to be dynamic, this needs runtime adjustment)
EXPOSE 9000

# Add a start script to dynamically set variables
COPY <<EOF /start.sh
#!/bin/sh
if [ -z "$CITY" ]; then
  echo "Error: CITY environment variable is required"
  exit 1
fi
if [ -z "$PORT" ]; then
  echo "Error: PORT environment variable is required"
  exit 1
fi

# Log the startup configuration
echo "Starting CDN for city $CITY on port $PORT"

# Replace the default port in the runtime environment and start the application
exec bin/cdn start
EOF

RUN chmod +x /start.sh

# Use the start script as the entrypoint
ENTRYPOINT ["/start.sh"]
