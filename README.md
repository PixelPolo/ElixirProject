# CDN Content Delivery Network for Static Web Resources

This project is a simulation of a small-scale Content Delivery Network (CDN) for delivering static web resources. It demonstrates the use of Elixir and Phoenix to implement distributed systems concepts.

## Features

- **Origin Server**: A Phoenix application that hosts and serves static web resources (HTML, CSS, JS).
- **CDN Edge Servers**: Multiple edge servers implemented in Elixir with caching to store and serve content.
- **Load Balancer**: An entry-point server that redirects clients to the nearest edge server based on geolocation.

## Architecture

The project mimics the behavior of a real-world CDN:

1. **Origin Server**: Stores the original content.
2. **Edge Servers**: Serve cached content or request it from the origin server if unavailable.
3. **Load Balancer**: Redirects clients to the nearest edge server based on geolocation (Haversine formula).

```
                        Clients
                           |
                           v
               +----------------------+
               |     Load Balancer    |
               +----------------------+
                           |
                           v
            +--------------+--------------+
            |              |              |
            v              v              v
   +-------------+   +-------------+   +-------------+
   | Lausanne    |   | Paris       |   | Washington  |
   | CDN server |    | CDN server  |   | CDN server  |
   +-------------+   +-------------+   +-------------+
            |              |              |
            v              v              v
            +--------------+--------------+
                           |
                           v
               +----------------------+
               |     Origin server    |
               +----------------------+
```

## Objectives

- Understand CDN technology and distributed systems concepts.
- Explore Elixir, Phoenix, and relevant libraries like Plug, Cachex, and HTTPoison.
- Simulate geolocation-based routing for efficient content delivery.

## How to run all the project with docker compose

```bash
docker-compose up --build -d
docker-compose down --rmi all
```

## How to interact with the system

1. **Access the Load Balancer**:  
   The load balancer is accessible via [http://localhost:8000](http://localhost:8000).

2. **Check Load Balancer Status**:  
   You can check the status of the load balancer by visiting [http://localhost:8000/status](http://localhost:8000/status).

3. **Play the Game via CDN**:  
   To access the game on the **origin server** through the CDN, go to [http://localhost:8000/snake](http://localhost:8000/snake).

   - **Important**: The game won't be available unless the CDNs are registered.
   - You can also access the game directly without the CDN by visiting [http://localhost:4000/snake](http://localhost:4000/snake).

4. **Register the CDNs**:  
   Before the load balancer can redirect requests to the CDNs, you need to register them. To do this, send a registration request to each CDN:

   - [http://localhost:9001/register](http://localhost:9001/register) for Lausanne CDN.
   - [http://localhost:9002/register](http://localhost:9002/register) for Paris CDN.
   - [http://localhost:9003/register](http://localhost:9003/register) for Washington CDN.

   Once the CDNs are registered, the load balancer can successfully route requests based on geolocation.

5. **View CDN Cache**:  
   You can view the cache for each CDN by visiting the following URLs:

   - [http://localhost:9001/cache](http://localhost:9001/cache) for Lausanne CDN.
   - [http://localhost:9002/cache](http://localhost:9002/cache) for Paris CDN.
   - [http://localhost:9003/cache](http://localhost:9003/cache) for Washington CDN.

6. **Clear CDN Cache**:  
   To clear the cache for each CDN, visit the following URLs:

   - [http://localhost:9001/cache/clear](http://localhost:9001/cache/clear) for Lausanne CDN.
   - [http://localhost:9002/cache/clear](http://localhost:9002/cache/clear) for Paris CDN.
   - [http://localhost:9003/cache/clear](http://localhost:9003/cache/clear) for Washington CDN.

7. **CDN Failure and Heartbeat**:  
   If a CDN goes down (e.g., you stop the Docker container for that CDN), the load balancer will update its registry to reflect the change.  
   This is done via the **heartbeat** mechanism, which periodically checks the health of the registered CDNs. If a CDN becomes unreachable, it is removed from the registry, ensuring that the load balancer only redirects traffic to available CDNs.

   You can observe this process by reload the load balancer's status at [http://localhost:8000/status](http://localhost:8000/status).
