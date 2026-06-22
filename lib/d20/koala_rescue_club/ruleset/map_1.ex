defmodule D20.KoalaRescueClub.Ruleset.Map1 do
  @moduledoc """
  Static Koala Rescue Club Map 1 ruleset data.
  """

  @solo_ratings [
    %{min: 0, max: 12, rank: :junior_club_member, label: "Junior club member. Keep practicing!"},
    %{
      min: 13,
      max: 16,
      rank: :club_secretary,
      label: "Club secretary. You're getting the hang of it!"
    },
    %{
      min: 17,
      max: 20,
      rank: :club_treasurer,
      label: "Club treasurer. You're making a real difference!"
    },
    %{
      min: 21,
      max: 24,
      rank: :vice_president,
      label: "Vice-president. An excellent achievement!"
    },
    %{min: 25, max: nil, rank: :president, label: "President. A champion of Koala Rescue Club!"}
  ]

  @doc """
  Returns Map 1 static rules derived from the supplied rules PDF.
  """
  @spec config() :: map()
  def config do
    %{
      slug: :map_1,
      title: "Map 1",
      initial_volunteers: 1,
      hospital_scoring: :completed_only,
      solo_ratings: @solo_ratings,
      sheet_geometry: :not_encoded
    }
  end
end
