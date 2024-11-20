defmodule OriginWeb.SnakeController do
  use OriginWeb, :controller

  def snake(conn, _params) do
    render(conn, :snake, layout: false)
  end
end
