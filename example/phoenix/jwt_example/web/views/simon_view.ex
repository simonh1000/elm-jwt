defmodule JwtExample.SimonView do
  use JwtExample.Web, :view

  def render("data.json", %{}) do
    %{"data": "I only replied because you sent a token"}
  end
end
