defmodule Koala.Wallet.Data.Repo.Migrations.CreateAddresses do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
          add :address, :text
          add :id, :uuid, primary_key: true
          add :nonce, :decimal, precision: 12, scale: 2
          add :balance, :decimal, precision: 12, scale: 2
          add :wallets_id, references(:wallets, type: :uuid, null: false)
          timestamps()
    end
  end
end
