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
    plug :fetch_flash
    # plug :protect_from_forgery
    # plug :put_secure_browser_headers
  end

  pipeline :api_auth do
      plug Guardian.Plug.VerifyHeader, realm: "Bearer"
      plug Guardian.Plug.LoadResource
  end

  scope "/api", JwtExample do
    # The api stack requires Authentication.
    pipe_through [ :api, :api_auth ]

    resources "/data", DataController, only: [:index, :update]
    get "/data_error", DataController, :index_error

    resources "/users", UserController, except: [:new, :edit]
  end

  scope "/sessions", JwtExample do
      pipe_through :api

      post "/", SessionController, :create, only: [:new, :create, :delete]
  end

  scope "/", JwtExample do
    pipe_through :browser # Use the default browser stack

    get "/*path", PageController, :index
    # get "/", PageController, :index
  end


end
