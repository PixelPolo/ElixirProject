# Load Balancer

Load balancer for a distributed CDN network in Elixir.

## Features

This server redirects requests sent to `http://localhost:8001/snake` to the origin server located at `http://localhost:4000/snake`.

## Instructions

1. **Start the Origin Server**  
   Make sure the origin server is running at `http://localhost:4000` before starting the load balancer.

2. **Start the Load Balancer**  
   Use the following command to start the server:

   ```bash
   mix run --no-halt
   ```

   Go to `http://localhost:8001/snake`.
