# CDN

A simple HTTP proxy using Plug to forward requests to an origin server with caching.

## Features

- Acts as a proxy server that forwards requests to an origin server.
- Caches responses to improve performance.
- Registers itself to the Load Balancer for request routing.
- Provides routes to view and manage the cache.

## Endpoints

### Health Check

- GET /
  - Verifies that the CDN server is running.

### Register to Load Balancer

- GET /register
  - Registers the CDN to the Load Balancer using its city and port.

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

## Instructions

1. Start the CDN Server

   Make sure the origin server is running at <http://localhost:4000> before starting the CDN server.

2. Start the Server

   A Run the following command to start the server: A bash A mix run --no-halt A

3. Test the Routes

Use tools like curl or a browser to interact with the endpoints.

Example to test /snake:

```bash
curl http://localhost:<>/snake
```

## Configuration

- The CDN server uses the following environment variables (set in config.exs):

  - :port

    - The port on which the CDN server listens (e.g., 9000).

  - :city
    - The city where the CDN is located, used during registration.
