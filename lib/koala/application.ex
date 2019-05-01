defmodule Koala.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Supervisor.Spec, warn: false

  def start(_type, _args) do

    children = [
      Tortoise.Supervisor.child_spec([strategy: :one_for_one, name: Koala_Mqtt]),
      {Koala.Supervisor, [strategy: :one_for_one]},
      {Registry, [keys: :unique, name: Koala_Registry]},
      supervisor(Koala.Wallet.Data.Repo, [])
    ]

    opts = [strategy: :one_for_one, name: Koala]
    Koala.Interface.check_file_structure
    Supervisor.start_link(children, opts)


  end
end
