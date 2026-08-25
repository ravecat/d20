defmodule D20Web.Admin.GameLive do
  @moduledoc """
  Update-only Backpex resource for persisted catalog games.
  """

  use Backpex.LiveResource,
    adapter_config: [
      schema: D20.Games.Game,
      repo: D20.Repo,
      update_changeset: &__MODULE__.update_changeset/3
    ],
    init_order: %{by: :id, direction: :asc}

  alias D20.Games.Game
  alias D20.Games.Policy

  @impl Backpex.LiveResource
  def singular_name, do: "Game"

  @impl Backpex.LiveResource
  def plural_name, do: "Games"

  @impl Backpex.LiveResource
  def layout(_assigns), do: {D20Web.Admin.Layouts, :admin}

  @impl Backpex.LiveResource
  def fields do
    [
      id: %{module: Backpex.Fields.Text, label: "ID", readonly: true},
      bgg_id: %{module: Backpex.Fields.Number, label: "BGG ID", index_editable: true},
      stage: %{
        module: Backpex.Fields.Select,
        label: "Stage",
        options: Game |> Ecto.Enum.values(:stage) |> Enum.map(&{Phoenix.Naming.humanize(&1), &1}),
        index_editable: true
      },
      enabled: %{module: Backpex.Fields.Boolean, label: "Enabled", index_editable: true},
      engine: %{
        module: Backpex.Fields.Select,
        label: "Engine",
        options: Game.engines(),
        prompt: "None",
        index_editable: true
      }
    ]
  end

  @impl Backpex.LiveResource
  def item_actions(default_actions), do: Keyword.delete(default_actions, :delete)

  @impl Backpex.LiveResource
  def can?(assigns, action, _item) when action in [:index, :show, :edit] do
    Bodyguard.permit?(Policy, :manage_games, assigns.current_user)
  end

  def can?(_assigns, _action, _item), do: false

  @doc false
  def update_changeset(game_or_changeset, attrs, _metadata) do
    Game.changeset(game_or_changeset, attrs)
  end
end
