defmodule Koala.Canoe.Handler do

  use Tortoise.Handler
  require Logger
  alias Koala.Wallet.Account, as: Account


  defstruct []
  alias __MODULE__, as: State

  def init(_opts) do
    Logger.info("Initializing handler")
    {:ok, %State{}}
  end

  def connection(:up, state) do
    Logger.info("Connection has been established")
    {:ok, state}
  end

  def connection(:down, state) do
    Logger.warn("Connection has been dropped")
    {:ok, state}
  end

  def connection(:terminating, state) do
    Logger.warn("Connection is terminating")
    {:ok, state}
  end

  def subscription(:up, topic, state) do
    Logger.info("Subscribed to #{topic}")
    {:ok, state}
  end

  def subscription({:warn, [requested: req, accepted: qos]}, topic, state) do
    Logger.warn("Subscribed to #{topic}; requested #{req} but got accepted with QoS #{qos}")
    {:ok, state}
  end

  def subscription({:error, reason}, topic, state) do
    Logger.error("Error subscribing to #{topic}; #{inspect(reason)}")
    {:ok, state}
  end

  def subscription(:down, topic, state) do
    Logger.info("Unsubscribed from #{topic}")
    {:ok, state}
  end

  ##WHAT HAPPENS IF THE ACCOUNT IS DELETED??

  def handle_message(topic, publish, state) do
    {:ok, oo} = Jason.decode(publish)
    Logger.info "+--- Incoming Block"
    IO.inspect  oo
    is_send = Map.has_key?(oo, "is_send")
    account = oo["account"]
    ll = Map.get(oo, "block")

    account_link = ll["link_as_account"]
    hash = oo["hash"]

    if is_send do
      ##if it is from an account in this wallet


      id = case Koala.Wallet.Data.account_id_canoe(account) do
        nil ->
          #id the trans is from a foreign place then make the function end here
          Koala.Wallet.Data.account_id(account_link)
        {:ok, final_id} ->
          final_id

      end
      IO.inspect("If of a del'd ID #{id}")


      if Koala.Wallet.Data.does_wallet_have_account?(account_link) do
        IO.inspect("in our wallet")
        case Koala.Wallet.Data.Blocks.list_hashes?(id, hash) do
          true ->
            IO.inspect("TRUE DA?T")

          false ->
            # IO.inspect account_link
            name = {:via, Registry, {Koala_Registry, account_link}}
            tre = Agent.get(name, fn account_info -> account_info end)

            ##if it's empter then spawn process other with just append the Agent
            case Enum.member?(tre[:hashes], hash) do
              false ->
                {_no, tre} = Keyword.get_and_update(tre, :hashes, fn current_value -> {current_value, tre[:hashes] ++ [hash]} end)

                Agent.update(name, fn account_info -> account_info = tre end)
                Process.spawn(fn -> Account.loop(tre[:wallet_name], tre, name) end, [:link])
              true ->
                IO.inspect "ITS ALREADY IN!!"
            end
        end

      else
        IO.inspect("just a confirm message")

      end


    else
      IO.puts("not needed send acknologment")
    end

    IO.puts(account <> "-" <> hash)

    # Logger.info("#{Enum.join(topic, "/")} #{inspect(publish)}")
    {:ok, state}
  end

  def terminate(reason, _state) do
    Logger.warn("Client has been terminated with reason: #{inspect(reason)}")
    :ok
  end
end
