defmodule DeviceApi.Users.User do
  use Ecto.Schema
  use Pow.Ecto.Schema

  schema "users" do
    pow_user_fields()
    field :firstname, :string
    field :lastname, :string
    field :username, :string
    field :publickey, :map
    field :devices, {:array, :string}
    field :masterkeyexam, :string
    timestamps()
  end
  def changeset(user_or_changeset, attrs) do
    user_or_changeset
    |> pow_changeset(attrs)
    |> Ecto.Changeset.validate_required([:username])
    |> Ecto.Changeset.unique_constraint(:username)
  end
end
