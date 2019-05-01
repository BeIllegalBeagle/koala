defmodule Koala.Wallet.Data.Blocks do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Koala.Wallet.Data.{Addresses, Repo, Wallets, Blocks}
# make schema for blocks
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "blocks" do
    field :type, :string
    field :work, :string
    field :balance, :decimal, precision: 12, scale: 12
    field :previous, :string
    field :signature, :string
    field :link, :string
    field :hash, :string
    belongs_to :accounts, Addresses, type: :binary_id

    timestamps()
  end

  def get_frontier(account_id), do: Repo.all(frontier_block(account_id)) |> List.first

## of course this would be where i would get the frontier block from, oh and
 ## convert the balance from decimal to int
  def frontier_block(account_id) do
    from i in Blocks,
    where: i.accounts_id == ^account_id,
    select: %{hash: i.hash, date: i.inserted_at, balance: i.balance},
    order_by: [desc: :inserted_at]
  end

  def remove_all_blocks(address) do
    id = Koala.Wallet.Data.account_id(address)
    from(p in Blocks, where: p.accounts_id == ^id) |> Repo.delete_all
     # |> Repo.delete
  end

  def lastest_link(account_id), do: Repo.all(get_previous_hash(account_id)) |> List.first |> Map.values |> List.first
  
  defp get_previous_hash(account_id) do
    from i in Blocks,
    where: i.accounts_id == ^account_id,
    select: %{link: i.link},
    order_by: [desc: :inserted_at]
  end

  def list_hashes?(account_id, hash), do: Repo.all(hash_list(account_id)) |> Enum.member?(hash)

  def hash_list(account_id) do
    from i in Blocks,
    where: i.accounts_id == ^account_id,
    select: %{hash: i.hash},
    order_by: [desc: :inserted_at]
  end

  @fields ~w(accounts_id type work balance previous signature link hash)

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> validate_required([:accounts_id, :type, :work, :balance, :previous, :signature,
    :link, :hash])
    |> foreign_key_constraint(:accounts_id, message: "not a valid account")
  end

end
