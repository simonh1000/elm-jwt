defmodule JwtExample.RootController do
  use JwtExample.Web, :controller

  plug :action

  def index(conn, _params) do
    redirect conn, to: "/elm.html"
  end
end
