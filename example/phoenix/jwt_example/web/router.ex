defmodule JwtExample.Router do
  use JwtExample.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    # plug :fetch_flash
    # plug :protect_from_forgery
    # plug :put_secure_browser_headers
    plug JwtExample.Auth, repo: JwtExample.Repo
    plug Guardian.Plug.VerifyHeader
    plug Guardian.Plug.LoadResource
  end

  scope "/", JwtExample do
    pipe_through :browser # Use the default browser stack

    get "/elm", RootController, :index
    get "/", PageController, :index
  end


  # Other scopes may use custom stacks.
  scope "/api", JwtExample do
    pipe_through :api

    get "/data", SimonController, :index

    resources "/users", UserController, except: [:new, :edit]
  end

  scope "/sessions", JwtExample do
      pipe_through :api

      post "/", SessionController, :create, only: [:new, :create, :delete]
  end


end
