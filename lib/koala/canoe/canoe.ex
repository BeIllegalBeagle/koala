defmodule Koala.Canoe do

  use Tesla
  @home System.user_home!()
  @cert "/certificate.pem"
  @key "/key.pem"

  plug Tesla.Middleware.BaseUrl, "https://getcanoe.io"
  plug Tesla.Middleware.Headers, [{"authorization", "token xyz"}]
  plug Tesla.Middleware.JSON
  alias Koala.Wallet
  alias Koala.Nano.Tools, as: Tools
  alias __MODULE__

  def new_account!(wallet) do

    with {:ok, response} <- Koala.Canoe.MitoNode.register_wallet(Keyword.fetch!(wallet, :mqtt_wallet_id))  do
      case response.body do
        %{"success" => true} ->
          :ok
        %{"error" => message} ->
          :error
      end
    else
        {:error, response} ->
          response
    end

  end

  @doc """
    will get the hash for an recieved block here
  """

  def accounts_pending(accounts) do

    {:ok, response} = post("/rpc", %{action: "accounts_pending", accounts: accounts, count: 4096})
    {:error, :econnrefused}
    %{"blocks" => body} = response.body
    # [acnt] = accounts
    # res = Tools.accounts_pending(acnt)
    # IO.inspect res
    # case res == "" do
    #   true ->
    #     %{"blocks" => ""}
    #   false ->
    #     %{"blocks" => res}
    # end

  end
#will get the info of said hash to be more useful
  def block_info(hash) do
    result = post("/rpc", %{action: "blocks_info", hashes: ["#{hash}"]})
  end

  def amount_from_hash(hash) do
    {:ok, result} = block_info(hash)
    result.body |> Map.get("blocks")
    |> Map.get(hash)
    |> Map.get("amount")
  end

  def account_info(account) do
    {:ok, response} = result = post("/rpc", %{action: "account_info", account: "#{account}"})
    response.body
  end


  def balance_from_address(account) do
    info = account_info(account)
    if !Map.has_key?(info, "error") do
      Map.get(info, "balance")
    else
      "0"
    end

  end

  def account_history(account, count \\ 5) do
    {:ok, response} = post("/rpc", %{action: "account_history", account: "#{account}", count: count})
    response.body
  end

  def is_open!(account) do
    history = account_history(account)
    open = case Map.get(history, "history") do
      nil ->
        false
      acnts ->
        acnts != ""
    end
  end

  def work_generate(hash) do
    # {:ok, response} = post("/rpc", %{action: "work_generate", hash: "#{hash}"})
    # {:ok, response.body}
    Koala.Canoe.MitoNode.work_generate(hash)
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

  def canoe_sub(state_tokens) do
    wallet_id = Keyword.fetch!(state_tokens, :mqtt_wallet_id)
    Tortoise.Connection.subscribe(wallet_id, {"wallet/#{wallet_id}/block/#", 2})
  end

  def canoe_pub(state_tokens, accounts) do
      wallet_id = Keyword.fetch!(state_tokens, :mqtt_wallet_id)

    {:ok, msg} = Jason.encode(%{name: "Koala", accounts: ["#{accounts}"], "version": 0.22, wallet: wallet_id})

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
