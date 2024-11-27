# Load Balancer

Load balancer for a distributed CDN network in Elixir.

## Features

- Redirects user requests to the nearest CDN server based on geographical location.
- Allows dynamic registration of CDN servers.
- Displays the current registry of CDN servers.
- Provides a health check endpoint.

## Endpoints

### Health Check

- GET /
  - Verifies that the load balancer is running.

### Register a CDN Server

FOR CDN SERVERS APPLICATION ONLY

- POST /cdn/register/:city
  - Registers a new CDN server for a specific city.
  - Request Body (JSON): { "ip": "000.00.00.00" }

### View CDN Registry

- GET /cdn/registry
  - Displays the list of currently registered CDN servers.

### Redirect to the Nearest CDN

- ANY /\*path
  - Redirects the request to the nearest CDN server based on simulated location defined in `config.exs`

## Instructions

1. Start the Origin Server

   Make sure the origin server is running at <http://localhost:4000> before starting the load alancer.

2. Start the Load Balancer

   Use the following command to start the server:

   ```bash
   mix run --no-halt
   ```

3. Access the Load Balancer

   - Test the redirection:
     Open <http://localhost:8000/snake> in your browser.
   - Register CDN servers or check the registry using the endpoints listed above.
