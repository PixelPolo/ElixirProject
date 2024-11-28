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
    SIMULATED_COORDS_LAT=48.8566 \
    SIMULATED_COORDS_LON=2.3522

# Set the working directory inside the container
WORKDIR /opt/app

# Copy the built release from the build stage
COPY --from=build /app/_build/prod/rel/loadbalancer .

# Expose the port used by the Load Balancer
EXPOSE 8000

# Start the application when the container runs
CMD ["bin/loadbalancer", "start"]
