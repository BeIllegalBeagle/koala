defmodule Koala.Wallet.Data.Repo.Migrations.CreateWallets do
  use Ecto.Migration

  def change do
    create table(:wallets, primary_key: false) do
          add :id, :uuid, primary_key: true
          add :name, :text
          add :mqtt_wallet_id, :text
          add :mqtt_token, :text
          add :mqtt_token_pass, :text
          add :nonce, :decimal, precision: 12, scale: 2
          add :total_balance, :decimal, precision: 12, scale: 2

          timestamps()
        end
  end
end
