defmodule D20Web.ModuleController do
  use D20Web, :controller

  alias D20.Games.Registry
  alias D20.Sessions
  alias D20.Sessions.Session
  alias D20Web.Module

  @spec options(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def options(conn, %{"slug" => slug}) do
    with {:ok, %Registry.Entry{}} <- Registry.fetch(slug) do
      send_resp(conn, :no_content, "")
    else
      {:error, reason} -> send_error(conn, reason)
    end
  end

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"slug" => slug} = params) do
    with {:ok, entry} <- Registry.fetch(slug),
         {:ok, %Session{} = session} <- ensure_session(conn, entry, params) do
      json(conn, %{session: session.id, bootstrap: Module.connection(conn, slug, session.id)})
    else
      {:error, reason} -> send_error(conn, reason)
    end
  end

  defp ensure_session(_conn, %Registry.Entry{slug: slug}, %{"session" => session_id}) do
    case Sessions.get(session_id) do
      {:ok, {%Session{} = session, ^slug}} -> {:ok, session}
      {:ok, {%Session{}, _other_slug}} -> {:error, :session_not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  defp ensure_session(conn, %Registry.Entry{slug: slug, engine: engine}, params) do
    attrs = Map.get(params, "attrs", %{})

    Sessions.create(slug, engine, conn.assigns.current_scope.actor.id, attrs)
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
