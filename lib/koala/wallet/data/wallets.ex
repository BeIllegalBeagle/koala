defmodule Koala.Wallet.Data.Wallets do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Koala.Wallet.Data.{Wallets, Addresses, Repo}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "wallets" do
    field :name, :string
    field :nonce, :decimal, precision: 12, scale: 2
    field :total_balance, :decimal, precision: 12, scale: 2
    field :mqtt_wallet_id, :string
    field :mqtt_token, :string
    field :mqtt_token_pass, :string
    has_many :accounts, Addresses, on_delete: :delete_all

    timestamps()
  end

  @fields ~w(name nonce total_balance mqtt_token mqtt_wallet_id mqtt_token_pass)

  def changeset(data, params \\ %{}) do
    data
    |> cast(params, @fields)
    |> validate_required([:name, :nonce, :total_balance, :mqtt_token, :mqtt_wallet_id, :mqtt_token_pass])
  end

  def wallet_database_check(wallet_name), do: Repo.all find_wallet(wallet_name)


  ##### TO DO ####
  #1 get the balance from accounts
  defp find_wallet(wallet_name) do
    from i in Wallets,
    # NO ASSOSCIATIVE WALLET
    # join: ii in InvoiceItem, on: ii.item_id == i.id,
    where: i.name == ^wallet_name,
    select: %{id: i.id, name: i.name, nonce: i.nonce, total_balance: i.total_balance, mqtt_token: i.mqtt_token,
     mqtt_wallet_id: i.mqtt_wallet_id, mqtt_token_pass: i.mqtt_token_pass}
    # group_by: i.id
    # order_by: [desc: sum(field(ii, ^type))]
  end

  #
  # def create(params) do
  #   cs = changeset(%Invoice{}, params)
  #   |> validate_item_count(params)
  #   |> put_assoc(:invoice_items, get_items(params))
  #
  #   if cs.valid? do
  #     Repo.insert(cs)
  #   else
  #     cs
  #   end
  # end
  #
  # defp get_items(params) do
  #   items = items_with_prices(params[:invoice_items] || params["invoice_items"])
  #   Enum.map(items, fn(item)-> InvoiceItem.changeset(%InvoiceItem{}, item) end)
  # end
  #
  # ##Need to know what this is for
  # defp items_with_prices(items) do
  #   item_ids = Enum.map(items, fn(item) -> item[:item_id] || item["item_id"] end)
  #   q = from(i in Item, select: %{id: i.id, price: i.price}, where: i.id in ^item_ids)
  #   prices = Repo.all(q)
  #
  #   Enum.map(items, fn(item) ->
  #     item_id = item[:item_id] || item["item_id"]
  #     %{
  #        item_id: item_id,
  #        quantity: item[:quantity] || item["quantity"],
  #        price: Enum.find(prices, fn(p) -> p[:id] == item_id end)[:price] || 0
  #      }
  #   end)
  # end
  #
  #
  # defp validate_item_count(cs, params) do
  #   items = params[:invoice_items] || params["invoice_items"]
  #
  #   if Enum.count(items) <= 0 do
  #     add_error(cs, :invoice_items, "Invalid number of items")
  #   else
  #     cs
  #   end
  # end

end
