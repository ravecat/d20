defmodule D20.FormTest do
  use ExUnit.Case, async: true

  alias D20.KoalaRescueClub.Game, as: KoalaGame

  test "builds an empty form for changesets without fields" do
    changeset = Ecto.Changeset.cast({%{}, %{}}, %{}, [])

    assert D20.Form.to_form(changeset) == %{}
  end

  test "builds form data from enum changeset fields" do
    assert {:ok, changeset} = D20.Game.attrs(KoalaGame)

    assert D20.Form.to_form(changeset) == %{
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
