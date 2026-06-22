defmodule D20.KoalaRescueClub.Ruleset.Map2 do
  @moduledoc """
  Static Koala Rescue Club Map 2 ruleset data.
  """

  @solo_ratings [
    %{min: 0, max: 15, rank: :junior_club_member, label: "Junior club member. Keep practicing!"},
    %{
      min: 16,
      max: 19,
      rank: :club_secretary,
      label: "Club secretary. You're getting the hang of it!"
    },
    %{
      min: 20,
      max: 23,
      rank: :club_treasurer,
      label: "Club treasurer. You're making a real difference!"
    },
    %{
      min: 24,
      max: 27,
      rank: :vice_president,
      label: "Vice-president. An excellent achievement!"
    },
    %{min: 28, max: nil, rank: :president, label: "President. A champion of Koala Rescue Club!"}
  ]

  @doc """
  Returns Map 2 static rules derived from the supplied rules PDF.
  """
  @spec config() :: map()
  def config do
    %{
      slug: :map_2,
      title: "Map 2 - Yugambeh",
      initial_volunteers: 0,
      hospital_scoring: :completed_positive_started_incomplete_negative,
      solo_ratings: @solo_ratings,
      sheet_geometry: :not_encoded
    }
  end
end
