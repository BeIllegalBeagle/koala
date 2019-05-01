defmodule Koala.Wallet.Data.Repo.Migrations.CreateBlocks do
  use Ecto.Migration

  def change do
    create table(:blocks, primary_key: false) do
          add :id, :uuid, primary_key: true
          add :type, :text
          add :work, :text
          add :previous, :text
          add :balance, :decimal, precision: 12, scale: 12
          add :signature, :text
          add :link, :text
          add :hash, :text
          add :accounts_id, references(:accounts, type: :uuid, null: false)
          timestamps()
    end
  end
end
