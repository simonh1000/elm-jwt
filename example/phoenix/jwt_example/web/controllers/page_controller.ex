defmodule JwtExample.PageController do
  use JwtExample.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
