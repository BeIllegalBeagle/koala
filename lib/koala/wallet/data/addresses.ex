defmodule Koala.Wallet.Data.Addresses do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Koala.Wallet.Data.{Addresses, Repo, Wallets, Blocks}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "accounts" do

    belongs_to :wallets, Wallets, type: :binary_id
    field :nonce, :decimal, precision: 12, scale: 2
    field :address, :string
    field :balance, :decimal, precision: 12, scale: 2
    has_many :blocks, Blocks, on_delete: :delete_all


    timestamps()
  end

  @fields ~w(wallets_id balance address nonce)

def changeset(data, params \\ %{}) do
  data
  |> cast(params, @fields)
  |> validate_required([:wallets_id, :address, :balance, :nonce])
  |> foreign_key_constraint(:wallets_id, message: "Select a valid wallet")
end

def account_database_check(wallet_id), do: Repo.all wallet_accounts(wallet_id) ## |> Repo.preload(addresses: :wallets) ##|> wallet_accounts(wallet_id)

def wallet_accounts(wallet_id) do
  from i in Addresses, where: i.wallets_id == ^wallet_id,
  select: %{id: i.id, address: i.address, nonce: i.nonce}
end

def accounts_id_address(address), do: {:ok, Repo.all accounts_id_for_address(address)}

def accounts_id_for_address(address) do
  from i in Addresses, where: i.address == ^address,
  select: %{id: i.id}
end

end
