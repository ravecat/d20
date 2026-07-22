defmodule D20.FormTest do
  use ExUnit.Case, async: true

  alias D20.KoalaRescueClub.Game, as: KoalaGame

  test "builds an empty form for changesets without fields" do
    changeset = Ecto.Changeset.cast({%{}, %{}}, %{}, [])

    assert D20.Form.to_form(changeset) == %{}
  end

  test "builds form data from enum changeset fields" do
    changeset = D20.Game.changeset(KoalaGame)

    assert D20.Form.to_form(changeset) == %{
             opponent: %{
               id: "attrs_opponent",
               name: "opponent",
               type: "enum",
               value: "none",
               required: true,
               values: ["none", "bot_easy", "bot_normal", "bot_hard"],
               errors: []
             },
             sheet: %{
               id: "attrs_sheet",
               name: "sheet",
               type: "enum",
               value: "dharug",
               required: true,
               values: ["dharug", "yugambeh"],
               errors: []
             }
           }
  end
end
