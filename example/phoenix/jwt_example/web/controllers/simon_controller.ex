defmodule JwtExample.SimonController do
  use JwtExample.Web, :controller

  alias JwtExample.User

  def index(conn, _params) do
    render(conn, "data.json")
  end
end
