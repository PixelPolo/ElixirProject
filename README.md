# CDN Content Delivery Network for Static Web Resources

This project is a simulation of a small-scale Content Delivery Network (CDN) for delivering static web resources. It demonstrates the use of Elixir and Phoenix to implement distributed systems concepts.

## Features

- **Origin Server**: A Phoenix application that hosts and serves static web resources (HTML, CSS, JS).
- **CDN Edge Servers**: Multiple edge servers implemented in Elixir with caching capabilities to store and serve content.
- **Load Balancer**: An entry-point server that redirects clients to the nearest edge server based on geolocation.

## Architecture

The project mimics the behavior of a real-world CDN:

1. **Origin Server**: Stores the original content.
2. **Edge Servers**: Serve cached content or request it from the origin server if unavailable.
3. **Load Balancer**: Redirects clients to the nearest edge server based on geolocation (Haversine formula).

## Objectives

- Understand CDN technology and distributed systems concepts.
- Explore Elixir, Phoenix, and relevant libraries like Plug, Cachex, and HTTPoison.
- Simulate geolocation-based routing for efficient content delivery.

## How to build and run each docker images

```bash
# Origin server
mix phx.gen.release --docker   # create a release
docker build -t origin .    # build a docker image with the tag origin
docker images      # check the list of images
docker run -p 4000:4000 --env SECRET_KEY_BASE=$(mix phx.gen.secret) --name origin origin

# Loadbalancer server : Simulation with a client from Lausanne
docker run -d --name loadbalancer-lausanne -p 8000:8000 \
    -e SIMULATED_COORDS_LAT=46.5197 \
    -e SIMULATED_COORDS_LON=6.6323 \
    loadbalancer

# CDN servers
docker run -d -p 9001:9001 -e CITY=Lausanne -e PORT=9001 --name lausanne-cdn cdn
docker run -d -p 9002:9002 -e CITY=Paris -e PORT=9002 --name paris-cdn cdn
docker run -d -p 9003:9003 -e CITY=Washington -e PORT=9003 --name washington-cdn cdn
```

## How to run all the project with docker compose

```bash
docker-compose up --build -d
docker-compose down --rmi all --volumes
```
