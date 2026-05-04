defmodule D20.Qwinto.Command do
  @moduledoc """
  Embedded command schemas for Qwinto game input.
  """

  alias Ecto.Changeset
  alias __MODULE__.{Join, Roll, Skip, Start, Write}

  @type kind :: :join | :start | :roll | :write | :skip

  @spec build(kind(), map()) ::
          {:ok, Join.t() | Start.t() | Roll.t() | Write.t() | Skip.t()}
          | {:error, Changeset.t()}
  def build(:join, attrs), do: Changeset.apply_action(Join.changeset(attrs), :join)
  def build(:start, attrs), do: Changeset.apply_action(Start.changeset(attrs), :start)
  def build(:roll, attrs), do: Changeset.apply_action(Roll.changeset(attrs), :roll)
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
    Command for the active player rolling one to three dice.
    """

    use Ecto.Schema

    import Ecto.Changeset

    alias D20.Qwinto.Rules

    @colors Rules.colors()
    @dice_count_range Rules.dice_count_range()
    @dice_value_range Rules.dice_value_range()
    @primary_key false

    embedded_schema do
      field :player_id, :string
      field :colors, {:array, Ecto.Enum}, values: @colors
      field :values, {:array, :integer}
    end

    @type t :: %__MODULE__{
            player_id: String.t() | nil,
            colors: [Rules.color()] | nil,
            values: [integer()] | nil
          }

    @spec changeset(map()) :: Ecto.Changeset.t()
    def changeset(attrs) do
      %__MODULE__{}
      |> cast(attrs, [:player_id, :colors, :values])
      |> validate_required([:player_id, :colors, :values])
      |> validate_dice_count(:colors)
      |> validate_dice_count(:values)
      |> validate_unique_colors(:colors)
      |> validate_dice_values(:values)
      |> validate_matching_lengths(:colors, :values)
    end

    defp validate_dice_count(changeset, field) do
      validate_length(changeset, field,
        min: Enum.min(@dice_count_range),
        max: Enum.max(@dice_count_range)
      )
    end

    defp validate_unique_colors(changeset, field) do
      validate_change(changeset, field, fn ^field, colors ->
        if Enum.uniq(colors) == colors, do: [], else: [{field, "has duplicate colors"}]
      end)
    end

    defp validate_dice_values(changeset, field) do
      validate_change(changeset, field, fn ^field, values ->
        if Enum.all?(values, &(&1 in @dice_value_range)),
          do: [],
          else: [{field, "has invalid dice value"}]
      end)
    end

    defp validate_matching_lengths(changeset, left, right) do
      left_values = get_field(changeset, left)
      right_values = get_field(changeset, right)

      if is_list(left_values) and is_list(right_values) and
           length(left_values) != length(right_values) do
        add_error(changeset, right, "must match #{left} count")
      else
        changeset
      end
    end
  end

  defmodule Write do
    @moduledoc """
    Command for writing the current roll sum into one row slot.
    """

    use Ecto.Schema

    import Ecto.Changeset

    alias D20.Qwinto.Rules

    @colors Rules.colors()
    @slot_range Rules.slot_range()
    @primary_key false

    embedded_schema do
      field :player_id, :string
      field :row, Ecto.Enum, values: @colors
      field :slot, :integer
    end

    @type t :: %__MODULE__{
            player_id: String.t() | nil,
            row: Rules.color() | nil,
            slot: non_neg_integer() | nil
          }

    @spec changeset(map()) :: Ecto.Changeset.t()
    def changeset(attrs) do
      %__MODULE__{}
      |> cast(attrs, [:player_id, :row, :slot])
      |> validate_required([:player_id, :row, :slot])
      |> validate_slot(:slot)
    end

    defp validate_slot(changeset, field) do
      validate_number(changeset, field,
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
