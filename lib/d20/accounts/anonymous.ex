defmodule D20.Accounts.Anonymous do
  @moduledoc """
  Public profile data for an anonymous visitor.

  Anonymous data is derived from a stable anonymous id stored in the browser
  session. The id is the source of truth; this struct is a deterministic
  projection used for UI and runtime context.
  """

  @enforce_keys [:id, :display_name, :avatar]
  defstruct [:id, :display_name, :avatar]

  @typedoc "Anonymous id string. Generated ids use the `anon` TypeID prefix."
  @type id :: String.t()
  @type t :: %__MODULE__{id: id(), display_name: String.t(), avatar: String.t()}

  @adjectives ~w(
    Able Agile Alert Ample Apt Balanced Bold Brave Bright Brilliant Calm Capable
    Careful Champion Charming Cheerful Clever Confident Creative Curious Daring
    Devoted Eager Earnest Elegant Excellent Fair Faithful Fine Fresh Friendly
    Gentle Gifted Glad Graceful Grand Happy Hardy Helpful Honest Hopeful Humble
    Jolly Joyful Keen Kind Lively Loyal Lucky Merry Mighty Nimble Noble Open
    Patient Peaceful Playful Pleasant Polite Proud Quick Radiant Ready Reliable
    Resolute Smart Spirited Steady Strong Sunny Swift Thoughtful True Trusty
    Upbeat Valiant Vibrant Warm Wise Worthy
  )

  @nouns ~w(
    Ant Ape Badger Bat Bear Beetle Bison Boar Bobcat Buffalo Cat Cobra Cougar
    Coyote Crane Crow Deer Dolphin Dove Dragonfly Duck Eagle Elk Falcon Ferret
    Finch Fox Frog Gecko Goat Goose Hare Hawk Heron Horse Hound Jaguar Jay Koala
    Lemur Leopard Lion Lizard Lynx Mantis Mole Moose Moth Mouse Newt Orca Otter
    Owl Panda Panther Parrot Pigeon Puma Rabbit Raven Rook Salmon Seal Shark
    Sparrow Spider Stag Swan Tiger Toad Trout Turtle Viper Vulture Weasel Whale
    Wolf Wren Yak Zebra
  )

  @avatar_fallback :robohash
  @avatar_size 80
  @prefix "anon"

  @spec new() :: t()
  def new do
    @prefix
    |> TypeID.new()
    |> TypeID.to_string()
    |> from_id()
  end

  @spec from_id(String.t()) :: t()
  def from_id(id) when is_binary(id) and byte_size(id) > 0 do
    seed = :crypto.hash(:sha256, "anonymous:" <> id)

    %__MODULE__{id: id, display_name: display_name(seed), avatar: avatar_url(id)}
  end

  defp display_name(seed) do
    adjective = pick(@adjectives, seed, 0)
    noun = pick(@nouns, seed, 4)

    "#{adjective} #{noun}"
  end

  defp avatar_url(id) do
    NeoFaker.Gravatar.display("anonymous-#{id}@d20.local",
      fallback: @avatar_fallback,
      force_default: true,
      rating: :g,
      size: @avatar_size
    )
  end

  defp pick(values, seed, offset) do
    <<_::binary-size(offset), value::32, _::binary>> = seed
    Enum.at(values, rem(value, length(values)))
  end
end
