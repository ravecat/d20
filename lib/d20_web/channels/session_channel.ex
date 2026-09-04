defmodule D20Web.SessionChannel do
  @moduledoc """
  Phoenix channel that serves a single game session to embedded game modules.
  """

  use D20Web, :channel

  alias D20.Accounts
  alias D20.Accounts.Scope
  alias D20.Sessions
  alias D20.Sessions.Session
  alias D20Web.Presence
  alias D20Web.Projection
  alias D20Web.Workspace

  @spec topic(Session.id()) :: String.t()
  def topic(session_id) when is_binary(session_id), do: "session:" <> session_id

  @spec session_id(String.t()) :: {:ok, Session.id()} | {:error, :invalid_topic}
  def session_id("session:" <> session_id) when session_id != "", do: {:ok, session_id}
  def session_id(_topic), do: {:error, :invalid_topic}

  @impl true
  def join(
        "session:" <> session_id,
        _payload,
        %{
          handler: D20Web.ModuleSocket,
          assigns: %{scope: %{session: %{id: session_id}, game: %{id: game_id}}}
        } = socket
      ) do
    case Sessions.get(session_id) do
      {:ok, {session, ^game_id}} -> join_to_session(socket, session)
      {:ok, {_session, _session_game_id}} -> join_error({:error, :forbidden})
      {:error, reason} -> join_error({:error, reason})
    end
  end

  def join("session:" <> _session_id, _payload, %{handler: D20Web.ModuleSocket}) do
    join_error({:error, :forbidden})
  end

  def join(
        "session:" <> session_id,
        _payload,
        %{assigns: %{scope: %{actor: %{id: _actor_id}}}} = socket
      ) do
    case Sessions.get(session_id) do
      {:ok, {session, game_id}} ->
        scope = socket.assigns.scope |> Scope.put_session(session.id) |> Scope.put_game(game_id)

        socket = assign(socket, :scope, scope)

        join_to_session(socket, session)

      {:error, reason} ->
        join_error({:error, reason})
    end
  end

  def join("session:" <> _session_id, _payload, _socket) do
    join_error({:error, :forbidden})
  end

  @impl true
  def handle_info(:after_join, socket) do
    actor_id = Scope.actor_id(socket.assigns.scope)

    attrs =
      actor_id
      |> Accounts.get_user_or_anonymous()
      |> Map.take([:display_name, :avatar])
      |> Map.put(:online_at, System.system_time(:second))

    {:ok, _} = Presence.track(socket, actor_id, attrs)

    {:noreply, socket}
  end

  def handle_info(
        {:close_session, actor_id, session_id},
        %{assigns: %{scope: %Scope{actor: %{id: actor_id}, session: %{id: session_id}}}} = socket
      ) do
    {:stop, :normal, socket}
  end

  def handle_info({:close_session, _actor_id, _session_id}, socket), do: {:noreply, socket}

  def handle_info({:sessions_changed, _actor_id}, socket), do: {:noreply, socket}

  @impl true
  def handle_info({:session, session}, socket) do
    push(socket, "projection", Projection.render(socket.assigns.scope, session))
    {:noreply, socket}
  end

  @impl true
  def handle_in(event, payload, socket) do
    scope = socket.assigns.scope

    with {:ok, %Session{} = session, reply} <- Sessions.dispatch(scope, event, payload),
         {:ok, response} <- Projection.reply(scope, session, reply) do
      {:reply, {:ok, response}, socket}
    else
      {:ok, %Session{}} -> {:reply, :ok, socket}
      {:error, reason} -> {:reply, {:error, %{reason: format_reason(reason)}}, socket}
    end
  end

  defp join_to_session(socket, session) do
    :ok = Workspace.subscribe(socket.assigns.scope)

    case Sessions.attach(socket.assigns.scope) do
      :ok ->
        send(self(), :after_join)
        {:ok, Projection.render(socket.assigns.scope, session), socket}

      {:error, reason} ->
        join_error({:error, reason})
    end
  end

  defp join_error({:error, :forbidden}), do: {:error, %{reason: "forbidden"}}
  defp join_error({:error, :session_not_found}), do: {:error, %{reason: "session_not_found"}}

  defp join_error({:error, reason}) when is_atom(reason),
    do: {:error, %{reason: Atom.to_string(reason)}}

  defp join_error({:error, reason}), do: {:error, %{reason: inspect(reason)}}

  defp format_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp format_reason(%Ecto.Changeset{}), do: "invalid_command"
  defp format_reason(reason), do: inspect(reason)
end
