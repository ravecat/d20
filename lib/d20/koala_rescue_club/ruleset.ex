defmodule D20.KoalaRescueClub.Ruleset do
  @moduledoc """
  Static Koala Rescue Club ruleset data.

  Keep game-wide facts here when they can be answered without mutable game
  state: turn and round limits, die shapes, volunteer die adjustment, bonus
  action kinds, scoring helpers, and map-specific rule differences.

  The supplied PDFs describe rules and map-specific differences, but not a
  machine-readable sheet geometry for areas, tree cells, koala cells, row and
  column bonuses, merit badge requirements, or skybridge graph edges. Those
  coordinates should be added separately before a full game reducer validates
  placements.
  """

  alias D20.KoalaRescueClub.Ruleset.Map1
  alias D20.KoalaRescueClub.Ruleset.Map2

  @min_players 1
  @rounds 1..2
  @turns_per_round 15
  @turn_range 1..30
  @scoring_turns [15, 30]
  @die_value_range 1..6
  @actions [:plant_trees, :rehome_koalas]
  @single_circle_actions [:circle_tree, :circle_koala]
  @bonus_actions [:tree, :koala, :volunteer, :hospital, :skybridge]
  @shape_transforms [:rotate, :flip]
  @tie_breakers [:most_koalas]

  @merit_badge_policy %{
    multiplayer: :first_players_large_others_small,
    solo: :round_1_large_round_2_small
  }

  @shapes %{
    1 => [{0, 0}, {1, 0}],
    2 => [{0, 0}, {1, 0}],
    3 => [{0, 0}, {1, 0}, {2, 0}],
    4 => [{0, 0}, {1, 0}, {0, 1}],
    5 => [{0, 0}, {1, 0}, {2, 0}, {0, 1}],
    6 => [{0, 0}, {1, 0}, {2, 0}, {1, 1}]
  }

  @map_modules %{map_1: Map1, map_2: Map2}
  @map_slugs [:map_1, :map_2]

  @type map_slug :: :map_1 | :map_2
  @type action :: :plant_trees | :rehome_koalas
  @type single_circle_action :: :circle_tree | :circle_koala
  @type bonus_action :: :tree | :koala | :volunteer | :hospital | :skybridge
  @type offset :: {integer(), integer()}
  @type rank ::
          :junior_club_member
          | :club_secretary
          | :club_treasurer
          | :vice_president
          | :president
  @type solo_rating :: %{
          required(:min) => non_neg_integer(),
          required(:max) => non_neg_integer() | nil,
          required(:rank) => rank(),
          required(:label) => String.t()
        }
  @type map_config :: %{
          required(:slug) => map_slug(),
          required(:title) => String.t(),
          required(:initial_volunteers) => non_neg_integer(),
          required(:hospital_scoring) => atom(),
          required(:solo_ratings) => [solo_rating()],
          required(:sheet_geometry) => :not_encoded
        }
  @type hospital :: %{
          required(:filled) => non_neg_integer(),
          required(:size) => pos_integer(),
          required(:score) => integer(),
          optional(:penalty) => integer()
        }
  @type area_score_input :: %{
          required(:trees_complete?) => boolean(),
          required(:koalas_complete?) => boolean()
        }

  @doc "Returns the minimum supported player count."
  @spec min_players() :: pos_integer()
  def min_players, do: @min_players

  @doc "Returns true when the player count is legal for classroom-style play."
  @spec valid_player_count?(term()) :: boolean()
  def valid_player_count?(count), do: is_integer(count) and count >= @min_players

  @doc "Returns the round numbers."
  @spec rounds() :: Range.t()
  def rounds, do: @rounds

  @doc "Returns the number of turns in each round."
  @spec turns_per_round() :: pos_integer()
  def turns_per_round, do: @turns_per_round

  @doc "Returns the complete turn range."
  @spec turn_range() :: Range.t()
  def turn_range, do: @turn_range

  @doc "Returns the turn numbers that trigger round scoring."
  @spec scoring_turns() :: [pos_integer()]
  def scoring_turns, do: @scoring_turns

  @doc "Returns the 1-based round for a valid turn."
  @spec round_for_turn(term()) :: {:ok, pos_integer()} | {:error, :invalid_turn}
  def round_for_turn(turn) when is_integer(turn) and turn in @turn_range do
    {:ok, div(turn - 1, @turns_per_round) + 1}
  end

  def round_for_turn(_turn), do: {:error, :invalid_turn}

  @doc "Returns true when the given turn triggers round scoring."
  @spec scoring_turn?(term()) :: boolean()
  def scoring_turn?(turn), do: turn in @scoring_turns

  @doc "Returns true when the given turn is the final turn."
  @spec final_turn?(term()) :: boolean()
  def final_turn?(turn), do: turn == Enum.max(@turn_range)

  @doc "Returns the die face range."
  @spec die_value_range() :: Range.t()
  def die_value_range, do: @die_value_range

  @doc "Returns true when the value is a legal die face."
  @spec valid_die_value?(term()) :: boolean()
  def valid_die_value?(value), do: is_integer(value) and value in @die_value_range

  @doc "Returns the canonical cell offsets for a die face shape."
  @spec shape_for(term()) :: {:ok, [offset()]} | {:error, :invalid_die_value}
  def shape_for(value) when value in @die_value_range, do: {:ok, Map.fetch!(@shapes, value)}
  def shape_for(_value), do: {:error, :invalid_die_value}

  @doc "Returns the canonical cell offsets for a known die face shape."
  @spec shape_offsets(pos_integer()) :: [offset()]
  def shape_offsets(value), do: Map.fetch!(@shapes, value)

  @doc "Returns the number of cells in a die face shape."
  @spec shape_size(pos_integer()) :: pos_integer()
  def shape_size(value), do: value |> shape_offsets() |> length()

  @doc "Returns shape transforms allowed by the rules."
  @spec shape_transforms() :: [:rotate | :flip]
  def shape_transforms, do: @shape_transforms

  @doc "Applies a volunteer die adjustment, wrapping between 1 and 6."
  @spec adjust_die(term(), term()) :: {:ok, pos_integer()} | {:error, :invalid_die_adjustment}
  def adjust_die(value, delta) when value in @die_value_range and is_integer(delta) do
    adjusted = value - 1 + delta
    {:ok, Integer.mod(adjusted, Enum.count(@die_value_range)) + 1}
  end

  def adjust_die(_value, _delta), do: {:error, :invalid_die_adjustment}

  @doc "Returns the minimum volunteers needed to change one die face into another."
  @spec volunteers_needed(term(), term()) ::
          {:ok, non_neg_integer()} | {:error, :invalid_die_value}
  def volunteers_needed(from, to) when from in @die_value_range and to in @die_value_range do
    distance = abs(to - from)
    {:ok, min(distance, Enum.count(@die_value_range) - distance)}
  end

  def volunteers_needed(_from, _to), do: {:error, :invalid_die_value}

  @doc "Returns all die faces reachable with up to the given number of volunteers."
  @spec reachable_die_values(term(), term()) ::
          {:ok, [pos_integer()]} | {:error, :invalid_volunteers}
  def reachable_die_values(value, volunteers)
      when value in @die_value_range and is_integer(volunteers) and volunteers >= 0 do
    values =
      Enum.filter(@die_value_range, fn candidate ->
        {:ok, needed} = volunteers_needed(value, candidate)
        needed <= volunteers
      end)

    {:ok, values}
  end

  def reachable_die_values(_value, _volunteers), do: {:error, :invalid_volunteers}

  @doc "Returns the two primary turn action kinds."
  @spec actions() :: [action()]
  def actions, do: @actions

  @doc "Returns the fallback single-circle action kinds."
  @spec single_circle_actions() :: [single_circle_action()]
  def single_circle_actions, do: @single_circle_actions

  @doc "Returns the row and column bonus action kinds."
  @spec bonus_actions() :: [bonus_action()]
  def bonus_actions, do: @bonus_actions

  @doc "Returns true when the action is a row or column bonus action."
  @spec bonus_action?(term()) :: boolean()
  def bonus_action?(action), do: action in @bonus_actions

  @doc "Returns the merit badge scoring policy."
  @spec merit_badge_policy() :: map()
  def merit_badge_policy, do: @merit_badge_policy

  @doc "Returns end-game tie breakers in priority order."
  @spec tie_breakers() :: [:most_koalas]
  def tie_breakers, do: @tie_breakers

  @doc "Returns supported map slugs."
  @spec map_slugs() :: [map_slug()]
  def map_slugs, do: @map_slugs

  @doc "Returns all supported map configs."
  @spec maps() :: [map_config()]
  def maps, do: Enum.map(@map_slugs, &map!/1)

  @doc "Fetches a supported map config."
  @spec map(map_slug() | String.t()) :: {:ok, map_config()} | {:error, :unknown_map}
  def map(slug) do
    case normalize_map_slug(slug) do
      {:ok, slug} -> {:ok, map!(slug)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Returns a supported map config or raises when the slug is unknown."
  @spec map!(map_slug()) :: map_config()
  def map!(slug), do: @map_modules |> Map.fetch!(slug) |> apply(:config, [])

  @doc "Returns the solo rating for a supported map and score."
  @spec solo_rating(map_slug() | String.t(), term()) ::
          {:ok, solo_rating()} | {:error, :unknown_map | :invalid_score}
  def solo_rating(slug, score) when is_integer(score) and score >= 0 do
    with {:ok, map} <- map(slug),
         rating when not is_nil(rating) <-
           Enum.find(map.solo_ratings, &score_in_rating?(score, &1)) do
      {:ok, rating}
    else
      {:error, reason} -> {:error, reason}
      nil -> {:error, :invalid_score}
    end
  end

  def solo_rating(_slug, _score), do: {:error, :invalid_score}

  @doc "Scores one area for a round."
  @spec score_area(area_score_input()) :: 0..2
  def score_area(%{trees_complete?: trees_complete?, koalas_complete?: koalas_complete?}) do
    score_if(trees_complete?) + score_if(koalas_complete?)
  end

  @doc "Scores one hospital according to the selected map's hospital policy."
  @spec score_hospital(map_slug() | String.t(), hospital()) ::
          {:ok, integer()} | {:error, :unknown_map | :invalid_hospital}
  def score_hospital(slug, hospital) do
    with {:ok, map} <- map(slug),
         :ok <- validate_hospital(map.hospital_scoring, hospital) do
      {:ok, score_hospital_by_policy(map.hospital_scoring, hospital)}
    end
  end

  defp normalize_map_slug(slug) when is_atom(slug) and slug in @map_slugs, do: {:ok, slug}
  defp normalize_map_slug("map_1"), do: {:ok, :map_1}
  defp normalize_map_slug("map_2"), do: {:ok, :map_2}
  defp normalize_map_slug(_slug), do: {:error, :unknown_map}

  defp score_in_rating?(score, %{min: min, max: nil}), do: score >= min
  defp score_in_rating?(score, %{min: min, max: max}), do: score >= min and score <= max

  defp score_if(true), do: 1
  defp score_if(false), do: 0

  defp validate_hospital(:completed_only, hospital), do: validate_hospital_base(hospital)

  defp validate_hospital(
         :completed_positive_started_incomplete_negative,
         %{penalty: penalty} = hospital
       )
       when is_integer(penalty),
       do: validate_hospital_base(hospital)

  defp validate_hospital(:completed_positive_started_incomplete_negative, _hospital),
    do: {:error, :invalid_hospital}

  defp validate_hospital_base(%{filled: filled, size: size, score: score})
       when is_integer(filled) and filled >= 0 and is_integer(size) and size > 0 and
              is_integer(score),
       do: :ok

  defp validate_hospital_base(_hospital), do: {:error, :invalid_hospital}

  defp score_hospital_by_policy(:completed_only, %{filled: filled, size: size, score: score}) do
    if filled >= size, do: score, else: 0
  end

  defp score_hospital_by_policy(
         :completed_positive_started_incomplete_negative,
         %{filled: filled, size: size, score: score} = hospital
       ) do
    cond do
      filled == 0 -> 0
      filled >= size -> score
      true -> Map.fetch!(hospital, :penalty)
    end
  end
end
