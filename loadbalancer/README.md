# Loadbalancer

A Load Balancer for managing and forwarding client requests to the nearest CDN.

## Features

- Dynamically registers CDN servers with their locations.
- Redirects client requests to the closest CDN based on geographical location.
- Displays the current status of registered CDNs and their cache.
- Performs periodic health checks on all registered CDNs and updates the registry based on their status.

## Endpoints

### Health Check

- **GET /**
  - Verifies that the Load Balancer is running.

### Register CDN

- **POST /cdn/register/:city**

  - Registers a CDN server with its IP and city.
  - Uses the city name to fetch coordinates (latitude and longitude) from the Nominatim API.

  **Request Body**:

  ```json
  {
    "ip": "127.0.0.1:9001"
  }
  ```

### View CDN Registry

- **GET /cdn/registry**
  - Displays the list of registered CDNs, including:
    - IP address.
    - City.
    - Latitude and longitude.

### Redirect Client Requests

- **MATCH /\*path**
  - Forwards client requests to the nearest CDN based on their geographical location.
  - Uses the Haversine formula to calculate distances between the client and registered CDNs.
  - Responds with a 302 redirect to the nearest CDN.

### View Load Balancer Status

- **GET /status**
  - Displays:
    - The client's simulated location (latitude, longitude, and city).
    - The list of registered CDNs, their cache status, and distances to the client.

## Configuration

- The Load Balancer uses the following environment variables (set in `config.exs`):

  - **`PORT`**

    - The port on which the Load Balancer listens (e.g., 8000).

  - **`SIMULATED_COORDS_LAT`**

    - The simulated latitude for the client.

  - **`SIMULATED_COORDS_LON`**
    - The simulated longitude for the client.

## How to run

This application is provided with a Dockerfile:

```bash
# Get the dependencies
mix deps.get

# Create a docker image
docker build -t loadbalancer .

# Run the Load Balancer container
docker run -d -p 8000:8000 -e SIMULATED_COORDS_LAT=48.8566 -e SIMULATED_COORDS_LON=2.3522 --name loadbalancer loadbalancer
```

- Note : A `docker-compose.yml` is available for the overall project.
