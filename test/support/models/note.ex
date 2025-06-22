defmodule Tenant.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field(:body, :string)
    belongs_to(:parent, Tenant.Note)
    has_many(:children, Tenant.Note, foreign_key: :parent_id)
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, ~w(body))
    |> cast_assoc(:parent)
    |> cast_assoc(:children)
    |> validate_required(:body)
  end
end
