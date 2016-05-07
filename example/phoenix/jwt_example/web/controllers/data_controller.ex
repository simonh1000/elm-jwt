defmodule JwtExample.DataController do
  use JwtExample.Web, :controller

  # Check user authenticated, otherwise halt
  plug Guardian.Plug.EnsureAuthenticated, handler: __MODULE__

  def index(conn, _params) do
      user = Guardian.Plug.current_resource(conn)

    #   IO.inspect(user)
      render(conn, "data.json", user: user)
  end

  def unauthenticated(conn, _params) do
      conn
      |> put_status(401)
      |> render("error.json", message: "Authentication required")
  end

end
