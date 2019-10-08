defmodule Koala.Canoe do

  use Tesla
  @home System.user_home!()
  @cert "/certificate.pem"
  @key "/key.pem"

  plug Tesla.Middleware.BaseUrl, "https://getcanoe.io"
  plug Tesla.Middleware.Headers, [{"authorization", "token xyz"}]
  plug Tesla.Middleware.JSON
  alias Koala.Wallet
  alias __MODULE__

  def new_account!(wallet) do

    with {:ok, response} <- post("/rpc", %{action: "create_server_account",
                            token: Keyword.fetch!(wallet, :mqtt_token),
                            tokenPass: Keyword.fetch!(wallet, :mqtt_token_pass),
                            wallet: Keyword.fetch!(wallet, :mqtt_wallet_id)})  do
    else
        {:error, response} ->
          response
    end

  end

  defp is_account_open(account, count \\ 1) do

      if Map.values(account) == [""] do
        false
      else
        true
      end
  end

#will get the hash for an recieved block here
  def accounts_pending(accounts) do

    {:ok, response} = post("/rpc", %{action: "accounts_pending", accounts: accounts, count: 5})
    {:error, :econnrefused}
    %{"blocks" => body} = response.body
    #does the account have an open block (or any block?) if so do the open_account thing
    # if hist = []do
    #   Koala.Wallet.open_account
    # end

  end
#will get the info of said hash to be more useful
  def block_info(hash) do
    result = post("/rpc", %{action: "blocks_info", hashes: ["#{hash}"]})
  end

  def block_info_balance(hash) do

    {:ok, response} =  post("/rpc", %{action: "blocks_info", hashes: ["#{hash}"]})
    {:ok, balance} = response.body |> Map.get("blocks")
    |> Map.get(hash)
    |> Map.get("contents")
    |> Jason.decode

    balance = Map.get(balance, "balance")

  end

  def get_balance (hash) do
    {:ok, response} =  post("/rpc", %{action: "blocks_info", hashes: ["#{hash}"]})
    %{^hash => %{"amount" => balance}} = response.body |> Map.get("blocks")
    balance
  end

  def account_history(account, count \\ 5) do
    {:ok, response} = post("/rpc", %{action: "account_history", account: "#{account}", count: count})
    response.body
  end

  def is_open!(account, count \\ 5) do
    {:ok, response} = post("/rpc", %{action: "account_history", account: "#{account}", count: count})

    case Map.has_key?(response.body, "history") do
       true ->
         response.body["history"] != ""
        false ->
          {:error, {!Map.has_key?(response.body, "error"), response.body}}
    end

  end

  def work_generate(hash) do
    {:ok, response} = post("/rpc", %{action: "work_generate", hash: "#{hash}"})
    # Map.get(response.body, "work")
    {:ok, response.body}
  end

  def process(block) do
    block = Map.from_struct(block)
      |> Map.drop([:state])
      |> Map.drop([:hash])
      |> Map.drop([:amount])


    {:ok, block} = Map.new(block, fn {key, value} -> {Atom.to_string(key), value} end)
      |> Jason.encode

    {:ok, response} = post("/rpc", %{action: "process", block: block})
    {:ok, response.body}
  end

#pass through the wallet object
#should be linked to koala genserver
  def canoe_start(state_tokens) do

    wallet_id = Keyword.fetch!(state_tokens, :mqtt_wallet_id)
    {:ok, _pid} = Tortoise.Supervisor.start_child(
    client_id: wallet_id,
    handler: {Koala.Canoe.Handler, []},
    server:
      {Tortoise.Transport.SSL,
        [host: 'getcanoe.io',
         port: 1885,
         cacertfile: :certifi.cacertfile(),
         verify: :verify_none,
         keyfile: @home <> @key,
         certfile: @home <> @cert
        ]},
    keep_alive: 300000,
    user_name: Keyword.fetch!(state_tokens, :mqtt_token),
    password: Keyword.fetch!(state_tokens, :mqtt_token_pass))
  end

  def canoe_sub(state_tokens) do
    wallet_id = Keyword.fetch!(state_tokens, :mqtt_wallet_id)
    Tortoise.Connection.subscribe(wallet_id, {"wallet/#{wallet_id}/block/#", 0})
  end

  def canoe_pub(state_tokens, accounts) do
      wallet_id = Keyword.fetch!(state_tokens, :mqtt_wallet_id)

    {:ok, msg} = Jason.encode(%{name: "Koala", accounts: ["#{accounts}"], "version": 0.15, wallet: wallet_id})

    ##got rid of QoS
    case Tortoise.publish_sync(wallet_id, "wallet/#{wallet_id}/register", msg, qos: 2, timeout: 2000) do
      :ok ->
        :done
      {:error, :timeout} ->
        __MODULE__.canoe_pub(state_tokens, accounts)
      {:error, :canceled} ->
        __MODULE__.canoe_pub(state_tokens, accounts)
    end
  end

end
