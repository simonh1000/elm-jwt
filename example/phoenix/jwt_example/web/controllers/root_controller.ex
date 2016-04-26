
defmodule JwtExample.RootController do
  use JwtExample.Web, :controller

  plug :action

  def index(conn, _params) do
      conn
        |> put_layout(false)
        |> render("./elm.html")
    # redirect conn, to: "/elm.html"
  end
end
