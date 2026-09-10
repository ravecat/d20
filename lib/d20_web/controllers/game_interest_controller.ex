defmodule D20Web.GameInterestController do
  use D20Web, :controller

  alias D20.Games.Interests

  @spec create(Plug.Conn.t(), Plug.Conn.params()) :: Plug.Conn.t()
  def create(conn, %{"slug" => slug}) do
    case Interests.request(conn.assigns.current_user, slug) do
      result when result in [:ok, {:error, :game_available}] ->
        conn |> put_status(303) |> redirect(to: ~p"/games/#{slug}")

      {:error, %Ecto.Changeset{}} ->
        conn
        |> assign_errors(%{message: "Could not save your request. Please try again."})
        |> put_status(303)
        |> redirect(to: ~p"/games/#{slug}")

      {:error, _reason} ->
        conn |> put_resp_content_type("text/html") |> send_resp(:not_found, "Not Found")
    end
  end
end
