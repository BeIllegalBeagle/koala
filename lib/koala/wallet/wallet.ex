defmodule Koala.Wallet do

  @enforce_keys [:name, :seed]
  @nucleous_wallet "genes"

  # @genesis_address "xrb_1ernxghpo7kyhc6icokqhy5itbkez11e3u3k5utmepjpx97wsqi6pyq134ir"
  ## aws xrb_1ernxghpo7kyhc6icokqhy5itbkez11e3u3k5utmepjpx97wsqi6pyq134ir

  @genesis_address "xrb_1qzfp3op48im348qdybmrheu9dogtopj1jyioguq9pyo5i7mkqgo4jaswp4a"
  ## local xrb_1qzfp3op48im348qdybmrheu9dogtopj1jyioguq9pyo5i7mkqgo4jaswp4 a

  use GenServer
  use Tesla

  alias __MODULE__, as: Wallet
  alias Koala.Wallet.Account, as: Account
  alias Koala.Nano.Tools, as: Tools
  alias Koala.Wallet.Data.{Wallets, Addresses, Blocks}

  @moduledoc """

  This is the main module for interacting with the Wallet after creation from 'Koala.Interface'

  ## Fields

    * name: - name of the wallet
    * id: - postgres UUID/Primarykey of the wallet
    * balance: - amount of nano held
    * accounts: - Array of nano address the wallet currently has // e.g. xrb_34bmpi65zr967cdzy4uy4twu7mqs9nrm53r1penffmuex6ruqy8nxp7ms1h1
    * seed: - Seed of the wallet // e.g. 9F1D53E732E48F25F94711D5B22086778278624F715D9B2BEC8FB81134E7C904
    * tokens: - MQTT and REST tokens created in use of Canoe service when block history or processing is needed
    * nonce: - Account history for the wallet, increases eaach time an address is created

  """

  defstruct [
    name: nil,
    id: nil,
    balance: 0,
    accounts: [],
    seed: nil,
    tokens: [],
    nonce: 0
  ]

  @type t::%Koala.Wallet{
  name: String.t,
  id: String.t,
  balance: Decimal.t,
  nonce: Integer.t,
  seed: String.t,
  accounts: List.t,
  tokens: Keyword.t
}


  def start_link(opts) do

    state = %Wallet{
      name: Keyword.fetch!(opts, :wallet_name),
      seed: Keyword.fetch!(opts, :seed),
      balance: 0,
      id: nil,
      accounts: nil,
      tokens: nil
    }

    GenServer.start_link(__MODULE__, state, name: Keyword.get(opts, :wallet_name))

  end


    @doc """

    Creates a new nano address and registers it with the Canoe service

    ## Returns
      {address, nonce}

    ## Examples

        iex> new_account("test_koala")
        {xrb_1dawphi1qwqjjczs7ranhz1s9uyeee88fx85m8wxq4r1xabdrysnrjpyf5i3, 1}

    """

  def new_account(wallet_name) do

    String.to_atom(wallet_name |> String.capitalize)
      |> GenServer.call({:new_account})
  end

  @doc """
    All nano addresses registred with Canoe are subscripted to with their own MQTT topic from the Canoe
    Broker
  """

  def sub_account(wallet_name) do

    String.to_atom(wallet_name |> String.capitalize)
      |> GenServer.call({:sub_account})
  end

  @doc """
    Publishes with MQTT the nano address to register on Canoe to listen for incoming transactions via a
    MQTT subscription on the address topic.

    Canoe publish payload example - %{name: "Koala", accounts: [accounts], "version": 0.15, wallet: wallet_id}
  """

  def pub_account(wallet_name, account) do

    String.to_atom(wallet_name |> String.capitalize)
      |> GenServer.call({:pub_account, account})
  end

  @doc """
    enter the wallets name and a valid nonce of the address that needs to be looked up and returned

    ## retuens

      * {:ok, address}
      * {:error, message}
  """

  def get_account(wallet_name, nonce) do
    String.to_atom(wallet_name |> String.capitalize)
      |> GenServer.call({:get_account, nonce})
  end

  @doc """
    Deletes and account from the wallet.

    Removes all associated blocks, and the account from
    Postgres. Also removes the assioated 'Koala.Wallet.Account' task
  """

  def delete_account(wallet_name, account) do

    String.to_atom(wallet_name |> String.capitalize)
      |> GenServer.call({:delete_account, account})
  end

  @doc """
    default is 0.00001 Nano
  """
  def send_nano(wallet_name, recipient, from_address, amount \\ 10000000000000000000000000) do
    String.to_atom(wallet_name |> String.capitalize)
      |> GenServer.call({:send_nano, recipient, from_address, amount})
  end

  def send_all_nano(wallet_name, from_address, recipient \\ @genesis_address) do
     case Koala.Wallet.Data.fronteir(from_address) do

       nil ->
         {:ok, "address was not open"}

       {:ok, fronteir} ->
         case fronteir |> Koala.Canoe.block_info_balance |> String.to_integer do


           0 ->
             {:ok, "address was empty"}

          _result ->
            wallet_name
              |> String.capitalize
              |> String.to_atom
              |> GenServer.call({:send_all_nano, recipient, from_address})

        end

        0 ->
          {:ok, "address was empty"}

      end
  end

  def send_newuser_nano(recipient, amount \\ 500000000000000000000000000) do

    String.to_atom(@nucleous_wallet |> String.capitalize)
      |> GenServer.call({:send_initial_nano, recipient, @genesis_address, amount})
  end

  def send_initial_nano(amount, recipient) do

    String.to_atom(@nucleous_wallet |> String.capitalize)
      |> GenServer.call({:send_initial_nano, recipient, @genesis_address, amount})
  end

  def get_pid(wallet_name), do: String.to_atom(wallet_name |> String.capitalize) |> GenServer.call({:get_pid})

  def get_wallet_id(wallet_name), do: String.to_atom(wallet_name |> String.capitalize) |> GenServer.call({:get_wallet_id})


  @doc """
    Gets balance in raw for the address with the specifed nonce. Default is nonce 0
  """

  def get_balance(name, nonce \\ 0) do
    String.to_atom(name |> String.capitalize)
      |> GenServer.call({:get_balance, nonce})
  end


  @doc """
    Used in the `Koala.Wallet` genserver init to start an Account task for each
    address the wallet currently owns
  """

  defp begin_accounts(accounts) do
    {:ok, accounts} = Enum.group_by(state.accounts, &(&1.nonce), &(&1.address))
    |> Map.values
    |> Enum.flat_map(fn x -> x end)
    |> Koala.Canoe.accounts_pending
    |> Map.fetch("blocks")

    accounts = for {a, s} <- accounts, a do if s == "" do {a, [s]} else {a, s} end end

    Enum.each(accounts, fn({address, hashes}) ->

      [who] = Enum.reject(state.accounts, fn (y) -> Map.get(y, :address) != address end)
      nonce = who[:nonce]
      account_info = [seed: state.seed, hashes: hashes, nonce: nonce, address: address, id: who[:id], amoount: nil]

      Account.start(state.name, account_info)

    end)
  end

  @doc """
    Upon initing the function of checking pending nano should be done,
    if there is indeed nano then the account task will be started with
    the hash(s) pending for the address
  """

  def init(state) do
    wallet = Wallets.wallet_database_check(Atom.to_string(state.name))

    case wallet do
      [] ->
        #kinda need to change this to raise error or simply pat match it
        Koala.Wallet.Data.insert_wallet [name: state.name, nonce: state.nonce, balance: state.balance]
        {:error, "ERROR wallet not found in database, creating new wallet"}

      [wallet] ->
        wallet = Map.to_list(wallet)
        tokens = [
                  mqtt_wallet_id: wallet[:mqtt_wallet_id],
                  mqtt_token: wallet[:mqtt_token],
                  mqtt_token_pass: wallet[:mqtt_token_pass]
                 ]
        state = %Wallet{state | tokens: tokens,
                                id: wallet[:id],
                                accounts:  Koala.Wallet.Data.get_accounts(wallet[:id])}

        # {:already_started, #PID<0.512.0>}}
        {:ok, _pid} = Koala.Canoe.canoe_start(state.tokens)
        Process.sleep(2000)
        {:ok, _reference} = Koala.Canoe.canoe_sub(state.tokens)


        state = if state.accounts != [] do

          begin_accounts(state.accounts)

          state

        else state.accounts == []

          {_priv, pub} = Tools.seed_account!(state.seed, 0)
          pub = Tools.create_account!(pub)
          ##to eb in a recur for nonce
          new_acnt = [id: state.id, address: pub, nonce: 0, balance: 0]

          Koala.Wallet.Data.insert_wallet_account(new_acnt)
          Koala.Canoe.canoe_pub(state.tokens, pub)
          Koala.Wallet.Data.update_nonce(Atom.to_string(state.name), Decimal.new(1.0))
          {:ok, _reference} = Koala.Canoe.canoe_sub(state.tokens)

          acnt_id = Koala.Wallet.Data.account_id(pub)
          new_acnt_with_id =  %{id: acnt_id, address: pub, nonce: 0, balance: 0}
          state = %Wallet{state | nonce: 1, accounts: List.insert_at(state.accounts, 0, new_acnt_with_id)}

          begin_accounts(state.accounts)

          state

        end

        {:ok, state}

    end

  end

  def handle_call({:new_account}, _from, state) do

    {_priv, pub} = Tools.seed_account!(state.seed, state.nonce + 1)
    pub = Tools.create_account!(pub)
   #need a more offical way of doing this

    new_acnt = [id: state.id, address: pub, nonce: state.nonce + 1, balance: 0]
    Koala.Wallet.Data.insert_wallet_account(new_acnt)
    new_acnt =  %{id: state.id, address: pub, nonce: state.nonce + 1, balance: 0}
    Koala.Canoe.canoe_pub(state.tokens, pub)
    Koala.Wallet.Data.update_nonce(Atom.to_string(state.name), Decimal.new(state.nonce + 1))
    ##should be updated
    state = %{state | nonce: state.nonce + 1, accounts: List.insert_at(state.accounts, 0, new_acnt)}
    {:reply, {pub, state.nonce}, state}
  end

  def handle_call({:get_account, nonce}, _from, state) do
    result = case Enum.reject(state.accounts, fn (y) ->  nonce != y.nonce end) do
      [result] ->
        {:ok, result.address}
      [] ->
        {:error, "address not found for nonce #{nonce}"}
    end

    {:reply, result, state}
  end




  def handle_call({:delete_account, account}, _from, state) do

    _result = Koala.Wallet.Data.Blocks.remove_all_blocks(account)
    IO.inspect("INFLATION")
    _result = Koala.Wallet.Data.Addresses.remove_address(account)

    result = case Registry.lookup(Koala_Registry, account) do
      [] ->
        {:ok, "Task for #{account} already killed"}
      [{pid, _nil}]  ->
        IO.inspect("The needful #{account}")
        {Agent.stop(pid), "Task killed"}
    end

    state = %{state | accounts: Enum.reject(state.accounts, fn x -> x[:address] == account end) }

    {:reply, result, state}
  end

  def handle_call({:get_balance, nonce}, _from, state) do
    [result] = Enum.reject(state.accounts, fn (y) ->  nonce != y.nonce end)
    result = Map.get(result, :address)
      with  {:ok, hash} <- Koala.Wallet.Data.fronteir(result) do
        current_balance = hash |> Koala.Canoe.block_info_balance
                               |> String.to_integer

        {:reply, current_balance, state}

      else
        0 ->
          {:reply, 0, state}
      end
  end

  def handle_call({:sub_account}, _from, state) do
    Koala.Canoe.canoe_sub(state.tokens)
    {:reply, {"sub finished"}, state}
  end

  def handle_call({:pub_account, account}, _from, state) do
    Koala.Canoe.canoe_pub(state.tokens, account)
    {:reply, {"pub finished"}, state}
  end

  def handle_call({:get_wallet_id}, _from, state) do
    id = Keyword.fetch!(state.tokens, :mqtt_wallet_id)
    {:reply, id, state}
  end

  def handle_call({:get_pid}, _from, state) do
    {:reply, self(), state}
  end

  @doc """
    send to address with specified amount
  """

  def handle_call({:send_nano, recipient, from_address, amount}, _from, state) do
    name = {:via, Registry, {Koala_Registry, from_address}}
    tre = Agent.get(name, fn account_info -> account_info end)
    {_no, tre} = Keyword.get_and_update(tre, :hashes, fn current_value -> {current_value, tre[:hashes] ++ [recipient]} end)
    {_no, tre} = Keyword.get_and_update(tre, :amount, fn current_value -> {current_value, amount} end)
    Agent.update(name, fn account_info -> account_info = tre end)
    Process.spawn(fn -> Account.loop(tre[:wallet_name], tre, name) end, [:link])
    {:reply, {"send complete"}, state}
  end

  @doc """

  """

  def handle_call({:send_all_nano, recipient, from_address}, _from, state) do

    {:ok, current_balance} =  Koala.Wallet.Data.fronteir(from_address)

    current_balance =  current_balance
      |> Koala.Canoe.block_info_balance
      |> String.to_integer

    name = {:via, Registry, {Koala_Registry, from_address}}
    tre = Agent.get(name, fn account_info -> account_info end)
    {_no, tre} = Keyword.get_and_update(tre, :hashes, fn current_value -> {current_value, tre[:hashes] ++ [recipient]} end)
    {_no, tre} = Keyword.get_and_update(tre, :amount, fn current_value -> {current_value, current_balance} end)

    Agent.update(name, fn account_info -> account_info = tre end)
    Process.spawn(fn -> Account.loop(tre[:wallet_name], tre, name) end, [:link])
    {:reply, {:ok, "send all complete"}, state}
  end

  @doc """

  """

  def handle_call({:send_initial_nano, recipient, from_address, amount}, _from, state) do
    name = {:via, Registry, {Koala_Registry, from_address}}
    tre = Agent.get(name, fn account_info -> account_info end)
    {_no, tre} = Keyword.get_and_update(tre, :hashes, fn current_value -> {current_value, tre[:hashes] ++ [recipient]} end)
    {_no, tre} = Keyword.get_and_update(tre, :amount, fn current_value -> {current_value, amount} end)

    Agent.update(name, fn account_info -> account_info = tre end)
    Process.spawn(fn -> Account.loop(tre[:wallet_name], tre, name) end, [:link])
    {:reply, {"send init complete"}, state}
  end

  def handle_cast({:new_block, block}, state) do
    IO.puts "added block"

    {:noreply, []}
  end

  def handle_info({{Tortoise, name}, _ref, :ok}, state) do


    if name == state.tokens[:mqtt_wallet_id] do
      IO.puts("+--- Wallet '#{state.name}' handled with care and connected to Canoe.
        ├── Canoe_wallet_id: " <> name)
      {:noreply, state}
    else


      {:noreply, state}
    end
  end

  def handle_info({{Tortoise, name}, _ref, {:error, reason}}, state) do

    # {{Tortoise, "F116CC38F0CD"}, #Reference<0.263384958.2774532098.244886>, {:error, [access_denied: {"wallet/F116CC38F0CD/block/#", 0}]}}
    # IO.inspect("try ahain")
    # if name == state.tokens[:mqtt_wallet_id] do
    #   IO.puts("+--- Wallet '#{state.name}' handled with care and connected to Canoe.
    #     ├── Canoe_wallet_id: " <> name)
    #   {:noreply, state}
    IO.inspect("+--TRYING TO SUB AGAIN--")
    Koala.Canoe.canoe_sub(state.tokens)

    {:noreply, state}
  end

  def handle_info({:EXIT, pid, :normal}) do

    IO.inspect("DYING, A KOALA")

  end

  def endd(name) do
    name = name |> String.capitalize |> String.to_atom

    pid = Process.whereis(name)
    IO.inspect(pid)
    IO.inspect self()
    DynamicSupervisor.which_children(Koala.Supervisor)
  # :ok = DynamicSupervisor.terminate_child(, pid)
    # GenServer.stop name, :shutdown
    # IO.inspect(name)
    # Supervisor.which_children(Koala.Supervisor)
    # pid = Process.whereis(name)

   # :ok = DynamicSupervisor.terminate_child(Koala.Supervisor, pid)
  end



  def terminate(reason, state) do
    IO.inspect("DYING, A KOALA")
    Tortoise.Connection.disconnect(Keyword.fetch!(state.tokens, :mqtt_wallet_id))

    :shutdown
  end
  # def handle_info({{Tortoise, get_mqtt_token}, _ref, :ok}, state) do
  #   IO.puts("got it lads")
  # end

  # defp get_mqtt_token do
  #   %Wallet{tokens: token} = token
  #   |> Enum.at(1)
  # end



end
