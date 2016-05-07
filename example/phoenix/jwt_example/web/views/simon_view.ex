defmodule JwtExample.SimonView do
  use JwtExample.Web, :view

  def render("data.json", %{user: user}) do
    %{"data": "I only replied to #{user.email} because you sent a token"}
  end

  def render("error.json", %{message: msg}) do
    %{"error": msg}
  end
end
