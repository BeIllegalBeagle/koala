defmodule Koala.Wallet.Data do
  @doc """
    walletid_exists!()
    returns :ok if the entered id is stored in postgres and :error if not

    store_new_wallet() take a seed and id, password and store it
  """
  alias Koala.Wallet.Data.{Wallets, Addresses, Blocks, Repo}
  alias Koala.Nano.Tools

  def insert_wallet(wallet) do

    item = Wallets.changeset(%Wallets{}, %{
      name: Atom.to_string(wallet[:name]),
      nonce: wallet[:nonce],
      total_balance: wallet[:balance],
      mqtt_token: Tools.mqtt_token,
      mqtt_wallet_id: Tools.mqtt_id,
      mqtt_token_pass: Tools.mqtt_token})

    item = Koala.Wallet.Data.Repo.insert!(item)

  end

  ##call after deleting flat files


  def burn_koala(name), do: Repo.get_by!(Wallets, name: String.capitalize(name)) |> Repo.delete

  def update_nonce(wallet_name, nonce) do
    {:ok, _changeset} = Repo.get_by(Koala.Wallet.Data.Wallets, name: wallet_name)
     |> Ecto.Changeset.change(%{nonce: nonce})
     |> Repo.update
  end

  def fronteir(address) do
    {:ok, id} = Repo.get_by(Koala.Wallet.Data.Addresses, address: address)
     |> Map.fetch(:id)
     case Blocks.get_frontier(id) do
      nil ->
        0

       id ->
         id |> Map.fetch(:hash)

     end
  end

  def account_id_canoe(address) do
    case Repo.get_by(Koala.Wallet.Data.Addresses, address: address) do
      nil ->
        nil
      id ->
         id |> Map.fetch(:id)
    end
  end

  def account_id(address) do
    {:ok, id} = Repo.get_by(Koala.Wallet.Data.Addresses, address: address)
     |> Map.fetch(:id)
    id
  end

  def insert_wallet_account(wallet) do
    account = Addresses.changeset(%Addresses{}, %{
      wallets_id: wallet[:id],
      nonce: wallet[:nonce],
      address: wallet[:address],
      balance: wallet[:balance]
    })

    account = Repo.insert!(account)

  end

  def insert_block(block, acnt_id) do

    new_block = Blocks.changeset(%Blocks{}, %{
      accounts_id: acnt_id,
      hash: block.hash,
      type: block.type,
      work: block.work,
      balance: Decimal.new("0." <> block.balance),
      previous: block.previous,
      link: block.link,
      signature: block.signature
    })

    new_block = Repo.insert!(new_block)

  end

  def does_wallet_have_account?(account) do
    case Repo.get_by(Addresses, address: account)  do

      nil ->
        false

     id ->

        {:ok, id} = Map.fetch(id, :wallets_id)

        case Repo.get_by(Wallets, id: id) do
          nil ->
            false

          id ->
            {:ok, id} = Map.fetch(id, :id)


        oo = Addresses.account_database_check(id)
         |> Enum.group_by(&(&1[:address]))
         |> Map.keys
         |> Enum.member?(account)


         end



     end

  end

  def get_accounts(wallet_id) do

    accounts = Addresses.account_database_check(wallet_id)
    what = for n <- accounts, do: Map.update!(n, :nonce, &(&1 |> Decimal.to_integer))

  end

end
