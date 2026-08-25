defmodule D20Web.ModuleController do
  use D20Web, :controller

  alias D20.Games
  alias D20.Games.Game
  alias D20.Sessions
  alias D20.Sessions.Session
  alias D20Web.Module

  @spec options(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def options(conn, %{"game_id" => game_id}) do
    case Games.get(game_id) do
      {:ok, %Game{}} -> send_resp(conn, :no_content, "")
      {:error, _reason} -> send_error(conn, :game_not_found)
    end
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"game_id" => game_id} = params) do
    with {:ok, game} <- Games.get(game_id),
         {:ok, %Session{} = session} <- ensure_session(conn, game, params) do
      json(conn, %{session: session.id, bootstrap: Module.connection(conn, game.id, session.id)})
    else
      {:error, reason} -> send_error(conn, reason)
    end
  end

  defp ensure_session(_conn, %Game{id: game_id}, %{"session" => session_id}) do
    case Sessions.get(session_id) do
      {:ok, {%Session{} = session, ^game_id}} -> {:ok, session}
      {:ok, {%Session{}, _other_game_id}} -> {:error, :session_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_session(conn, %Game{} = game, params) do
    if Games.session_launch_available?(game) do
      attrs = Map.get(params, "attrs", %{})
      {:ok, engine} = Games.engine(game)

      Sessions.create(game.id, engine, conn.assigns.scope.actor.id, attrs)
    else
      {:error, :forbidden}
    end
  end

  defp send_error(conn, :game_not_found), do: send_resp(conn, :not_found, "Not Found")
  defp send_error(conn, :session_not_found), do: send_resp(conn, :not_found, "Not Found")
  defp send_error(conn, :forbidden), do: send_resp(conn, :forbidden, "Forbidden")

  defp send_error(conn, %Ecto.Changeset{} = changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: translate_errors(changeset)})
  end

  defp send_error(conn, _reason) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{errors: %{detail: "Could not start session"}})
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
