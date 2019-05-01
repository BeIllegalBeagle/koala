defmodule Koala.Wallet.Account do
  alias Koala.Wallet.Account, as: Account
  alias Koala.Nano.Tools, as: Tools
  alias Koala.Wallet.Data.Blocks, as: Blocks
  alias Koala.Wallet.Data, as: Data
  use Agent

## feed in wallet name as an Atom
  def start(wallet_name, account_info) do
    name = {:via, Registry, {Koala_Registry, account_info[:address]}}
    Keyword.put(account_info, :wallet_name, wallet_name)
    Agent.start_link(fn -> account_info end, name: name)
    Process.spawn(fn -> Account.loop(account_info[:wallet_name], account_info, name) end, [:link])
  end

  def add_hash(name, hash) do
    Agent.update(name, fn account_info -> [hash | account_info[:hashes]]  end)
  end

  defguard empty(hashes) when hashes !=[""] and hashes !=[]

  def loop(wallet_name, account_info, name) do
    IO.inspect(account_info[:hashes])
    cond do
      empty(account_info[:hashes]) == true->
        cleaned_hashes = List.delete(account_info[:hashes], "")
          [current_hash | rest] = cleaned_hashes
          # IO.inspect account_info

           with {:ok, block} <- sign(
           {
             current_hash,
             account_info[:nonce],
             account_info[:address],
             account_info[:amount],
             account_info[:id]
           }, account_info[:seed]) do

             GenServer.cast(wallet_name, {:new_block, block})
             Data.insert_block(block, account_info[:id])

             else
               :error ->
                 {:error, "blocks failed"}
           end
           {_no, tre} = Keyword.get_and_update(account_info, :hashes, fn current_value -> {current_value, rest} end)
           item = Agent.update(name, fn account_info -> account_info = tre end)

           loop(wallet_name, tre, name)


      empty(account_info[:hashes]) == false->

    end


    # receive do
    #   # {:get, key, caller} ->
    #   #   send caller, Map.get(map, key)
    #   #   loop(map)
    #   {:put, key, value} ->
    #     loop(Map.put(map, key, value))
    # end
  end

  # defp loop(wallet_name, account_info) when account_info[:hashes] == [] do
  #   IO.puts("finishes processing")
  #   # loop(wallet_name, account_info)
  # end


defp sign({hash, nonce, address, amount, account_id}, seed) do

  if Koala.Canoe.is_open!(address) do
    if is_send!(hash) do
      prev_hash = Blocks.get_frontier(account_id)
      IO.inspect(prev_hash)
      {priv, pub} = Tools.seed_account!(seed, nonce)
        |> Tools.send(hash, amount, prev_hash.hash)
    else
      if Blocks.lastest_link(account_id) != hash do
        prev_hash = Blocks.get_frontier(account_id)
        IO.inspect(prev_hash)
        {priv, pub} = Tools.seed_account!(seed, nonce)
          |> Tools.receive(hash, prev_hash.hash)
      else
        IO.inspect("ATTEMPT OF A DUPLICATE BLOCK PROCESS") 
        :error
          #return, as we are in a duplicate hash
      end
    end
  else
    Tools.seed_account!(seed, nonce)
      |> Tools.open_account hash
  end

end

defp is_send!(link) do
  "xrb" == String.slice(link, 0, 3)
end




end
