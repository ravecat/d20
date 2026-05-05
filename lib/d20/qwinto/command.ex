defmodule D20.Qwinto.Command do
  @moduledoc """
  Embedded command schemas for Qwinto game input.
  """

  alias Ecto.Changeset
  alias __MODULE__.{Join, Keep, Reroll, Roll, Skip, Start, Write}

  @type kind :: :join | :start | :roll | :keep | :reroll | :write | :skip
  @type command :: Join.t() | Start.t() | Roll.t() | Keep.t() | Reroll.t() | Write.t() | Skip.t()

  @spec build(kind(), map()) :: {:ok, command()} | {:error, Changeset.t()}
  def build(:join, attrs), do: Changeset.apply_action(Join.changeset(attrs), :join)
  def build(:start, attrs), do: Changeset.apply_action(Start.changeset(attrs), :start)
  def build(:roll, attrs), do: Changeset.apply_action(Roll.changeset(attrs), :roll)
  def build(:keep, attrs), do: Changeset.apply_action(Keep.changeset(attrs), :keep)
  def build(:reroll, attrs), do: Changeset.apply_action(Reroll.changeset(attrs), :reroll)
  def build(:write, attrs), do: Changeset.apply_action(Write.changeset(attrs), :write)
  def build(:skip, attrs), do: Changeset.apply_action(Skip.changeset(attrs), :skip)

  defmodule Join do
    @moduledoc """
    Command for adding a player to a Qwinto setup.
    """

    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false

    embedded_schema do
      field :player_id, :string
    end

    @type t :: %__MODULE__{player_id: String.t() | nil}

    @spec changeset(map()) :: Ecto.Changeset.t()
    def changeset(attrs) do
      %__MODULE__{}
      |> cast(attrs, [:player_id])
      |> validate_required([:player_id])
    end
  end

  defmodule Start do
    @moduledoc """
    Command for starting a valid Qwinto setup.
    """

    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false

    embedded_schema do
    end

    @type t :: %__MODULE__{}

    @spec changeset(map()) :: Ecto.Changeset.t()
    def changeset(attrs) do
      %__MODULE__{}
      |> cast(attrs, [])
    end
  end

  defmodule Roll do
    @moduledoc """
    Command for the active player selecting one to three dice.
    """

    use Ecto.Schema

    import Ecto.Changeset

    alias D20.Qwinto.Constants

    @colors Constants.colors()
    @dice_count_range Constants.dice_count_range()
    @primary_key false

    embedded_schema do
      field :player_id, :string
      field :colors, {:array, Ecto.Enum}, values: @colors
    end

    @type t :: %__MODULE__{
            player_id: String.t() | nil,
            colors: [Constants.color()] | nil
          }

    @spec changeset(map()) :: Ecto.Changeset.t()
    def changeset(attrs) do
      %__MODULE__{}
      |> cast(attrs, [:player_id, :colors])
      |> validate_required([:player_id, :colors])
      |> validate_length(:colors,
        min: Enum.min(@dice_count_range),
        max: Enum.max(@dice_count_range)
      )
      |> validate_change(:colors, fn :colors, colors ->
        if Enum.uniq(colors) == colors, do: [], else: [colors: "has duplicate colors"]
      end)
    end
  end

  defmodule Keep do
    @moduledoc """
    Command for keeping the first roll result.
    """

    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false

    embedded_schema do
      field :player_id, :string
    end

    @type t :: %__MODULE__{player_id: String.t() | nil}

    @spec changeset(map()) :: Ecto.Changeset.t()
    def changeset(attrs) do
      %__MODULE__{}
      |> cast(attrs, [:player_id])
      |> validate_required([:player_id])
    end
  end

  defmodule Reroll do
    @moduledoc """
    Command for replacing the first roll with a second roll.
    """

    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false

    embedded_schema do
      field :player_id, :string
    end

    @type t :: %__MODULE__{player_id: String.t() | nil}

    @spec changeset(map()) :: Ecto.Changeset.t()
    def changeset(attrs) do
      %__MODULE__{}
      |> cast(attrs, [:player_id])
      |> validate_required([:player_id])
    end
  end

  defmodule Write do
    @moduledoc """
    Command for writing the current roll sum into one row slot.
    """

    use Ecto.Schema

    import Ecto.Changeset

    alias D20.Qwinto.Constants

    @colors Constants.colors()
    @slot_range Constants.slot_range()
    @primary_key false

    embedded_schema do
      field :player_id, :string
      field :row, Ecto.Enum, values: @colors
      field :slot, :integer
    end

    @type t :: %__MODULE__{
            player_id: String.t() | nil,
            row: Constants.color() | nil,
            slot: non_neg_integer() | nil
          }

    @spec changeset(map()) :: Ecto.Changeset.t()
    def changeset(attrs) do
      %__MODULE__{}
      |> cast(attrs, [:player_id, :row, :slot])
      |> validate_required([:player_id, :row, :slot])
      |> validate_number(:slot,
        greater_than_or_equal_to: Enum.min(@slot_range),
        less_than_or_equal_to: Enum.max(@slot_range)
      )
    end
  end

  defmodule Skip do
    @moduledoc """
    Command for declining to write during the current roll.
    """

    use Ecto.Schema

    import Ecto.Changeset

    @primary_key false

    embedded_schema do
      field :player_id, :string
    end

    @type t :: %__MODULE__{player_id: String.t() | nil}

    @spec changeset(map()) :: Ecto.Changeset.t()
    def changeset(attrs) do
      %__MODULE__{}
      |> cast(attrs, [:player_id])
      |> validate_required([:player_id])
    end
  end
end
