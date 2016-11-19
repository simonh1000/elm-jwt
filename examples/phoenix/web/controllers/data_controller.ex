defmodule JwtExample.DataController do
  use JwtExample.Web, :controller

  alias JwtExample.User

  # Check user authenticated, otherwise halt
  plug Guardian.Plug.EnsureAuthenticated, handler: __MODULE__

  def index(conn, _params) do
      user = Guardian.Plug.current_resource(conn)

      render(conn, "data.json", user: user)

    #   error_changeset =
    #       User.changeset(%User{email: "fake-email"})
      #
    #   conn
    #   |> put_status(:unprocessable_entity)
    #   |> render(JwtExample.ChangesetView, "error.json", changeset: error_changeset)
  end

  def index_error(conn, _params) do
      error_changeset =
          User.changeset(%User{}, %{email: "fake-email"})

      conn
      |> put_status(:unprocessable_entity)
      |> render(JwtExample.ChangesetView, "error.json", changeset: error_changeset)
  end

  def unauthenticated(conn, _params) do
      conn
      |> put_status(401)
      |> render("error.json", message: "Authentication required")
  end

end
