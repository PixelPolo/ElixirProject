# CDN

A simple HTTP proxy using Plug to forward requests to an origin server with caching.

## Features

- Acts as a proxy server that forwards requests to an origin server.
- Caches responses to improve performance.
- Registers itself to the Loadbalancer for request routing.
- Provides routes to view and manage the cache.

## Endpoints

### Health Check

- GET /
  - Verifies that the CDN server is running.

### Register to Loadbalancer

- GET /register
  - Registers the CDN to the Loadbalancer.

### Proxy Requests with Caching

- GET /snake

  - Fetches resources from the origin server for the /snake path.
  - If the resource is cached, it serves the cached response.
  - Otherwise, it fetches from the origin server, caches the response, and serves it.

- MATCH /\*path
  - Catch-all route for other requests, proxies them to the origin server.
  - Checks the cache before making a request to the origin server.
  - Caches the response for future requests.

### View Cache State

- GET /cache
  - Displays the current cache keys stored in the CDN.

### Clear Cache

- GET /cache/clear
  - Clears all entries in the CDN cache.

## Configuration

- The CDN server uses the following environment variables (set in config.exs):

  - :port

    - The port on which the CDN server listens (e.g., 9000).

  - :city

    - The city where the CDN is located, used during registration.

  - :loadbalancer_url

    - The Loadbalancer server url to register the cdn

  - :origin_url
    - The Origin server url to fetch the resources

## How to run

This application is provided with a Dockerfile :

```bash
# Get the dependencies
mix deps.get

# Create a docker image
docker build -t cdn .

# Generate containers on different ports
docker run -d -p 9001:9001 -e CITY=Lausanne -e PORT=9001 --name lausanne-cdn cdn

docker run -d -p 9002:9002 -e CITY=Paris -e PORT=9002 --name paris-cdn cdn

docker run -d -p 9003:9003 -e CITY=Washington -e PORT=9003 --name washington-cdn cdn
```

* Note : A `docker-compose.yml` is available for the overall project.
