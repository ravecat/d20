defmodule D20Web.GameFavoriteController do
  use D20Web, :controller

  alias D20.Games.Favorites
  alias D20Web.Auth

  @spec update(Plug.Conn.t(), Plug.Conn.params()) :: Plug.Conn.t()
  def update(conn, %{"bgg_id" => value} = params) do
    case Favorites.create(conn.assigns.current_user, String.to_integer(value), params["slug"]) do
      :ok -> redirect_to_response(conn)
      {:error, reason} -> error(conn, reason)
    end
  end

  @spec delete(Plug.Conn.t(), Plug.Conn.params()) :: Plug.Conn.t()
  def delete(conn, %{"bgg_id" => value}) do
    case Favorites.delete(conn.assigns.current_user, String.to_integer(value)) do
      :ok -> redirect_to_response(conn)
      {:error, reason} -> error(conn, reason)
    end
  end

  defp redirect_to_response(conn) do
    conn
    |> put_status(:see_other)
    |> redirect(to: Auth.safe_local_path(conn.params["response_to"], ~p"/"))
  end

  defp error(conn, :authentication_required) do
    conn
    |> assign_errors(%{authentication: "Sign in to save favorites."})
    |> redirect_to_response()
  end

  defp error(conn, reason) do
    conn
    |> assign_errors(%{favorite: error_message(reason)})
    |> redirect_to_response()
  end

  defp error_message(:game_not_found), do: "Game not found."

  defp error_message(:game_identity_changed),
    do: "This game has changed. Refresh the page and try again."
end
