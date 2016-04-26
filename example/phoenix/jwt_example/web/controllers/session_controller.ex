defmodule JwtExample.SessionController do
  use JwtExample.Web, :controller

  alias JwtExample.User
  alias JwtExample.Auth

  def index(conn, _params) do
    render(conn, "data.json")
  end

  # def create(conn, %{"session" => %{"username" => email, "password" => password}}) do
  def create(conn, %{"username" => email, "password" => password}) do
    #   render conn, "data.json"
      case Auth.login_by_username_and_pass(conn, email, password, repo: Repo) do
          {:ok, conn} ->
            #   render conn, "data.json"
              new_conn = Guardian.Plug.api_sign_in(conn, conn.assigns[:current_user])
              jwt = Guardian.Plug.current_token(new_conn)
              claims = Guardian.Plug.claims(new_conn)
            #   exp = Map.get(claims, "exp")

              new_conn
              |> put_resp_header("authorization", "Bearer #{jwt}")
            #   |> put_resp_header("x-expires", exp)
            #   |> render("login.json", jwt: jwt, exp: exp)
              |> render("login.json", jwt: jwt)
          {:error, _reason, conn} ->
              conn
              |> put_status(500)
              |> render("error")
      end
  end
end
