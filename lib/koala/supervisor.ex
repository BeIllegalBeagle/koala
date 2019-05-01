defmodule Koala.Supervisor do
  use DynamicSupervisor


  def start_link(opts) do
    DynamicSupervisor.start_link(__MODULE__, opts, name: opts[:name])
  end

  def child_spec(opts) do
    opts = Keyword.put_new(opts, :name, __MODULE__)
    DynamicSupervisor.child_spec(opts)
  end

  def start_child(supervisor \\ __MODULE__, opts) do
      spec = {Koala.Wallet , opts}
      DynamicSupervisor.start_child(supervisor, spec)
    end

    def terminate_child(supervisor \\ __MODULE__, pid) do
        DynamicSupervisor.terminate_child(supervisor, pid)
    end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
