defmodule Koala.Interface do
@home_dir System.user_home!()
@koala_dirs ["/Library/Koala", "/Library/Koala/Logs", "/Library/Koala/Seeds"]
alias Koala.Wallet.Repo
alias Koala.Nano.Tools, as: Tools

  ##ToD0
  def check_file_structure do
    case File.exists?(@home_dir <> "/Library/Koala/") do
      :false ->
        for i <- @koala_dirs, do: File.mkdir!(@home_dir <> i)

      :true ->
        {:ok, "Koala library file present"}
      end
  end

  def get_seed(wallet_name, password) do
    {:ok, files} = File.ls @home_dir <> Enum.at(@koala_dirs, 2)

    files_names = for a <- files, do: String.split(a, "_", parts: 2)
    ##a with statement here would be nice
    {:ok, seed} = recur(files_names, "#{wallet_name}.aes", password)
  end

  def burn_seed(wallet_name) do
    {:ok, files} = File.ls @home_dir <> Enum.at(@koala_dirs, 2)

    files_names = for a <- files, do: String.split(a, "_", parts: 2)
    recur(files_names, "#{wallet_name}.aes", "", true)
    :ok
  end

  def koala_start(wallet_name, password \\ "koala") when is_bitstring(wallet_name) do

    case get_seed(wallet_name, password) do
      {:ok, seed} ->
        case Koala.Supervisor.start_child(wallet_name: String.to_atom(wallet_name |> String.capitalize), seed: seed) do
          {:ok, _message} ->
            :ok
            # Koala.Supervisor.start_child(wallet_id: wallet_id, seed: seed)
          {:error, message} ->
            IO.inspect(message)
        end
      {:error, message} ->
        message
      # {:already_started, _pid} ->
      #   {:erro, "already started"}
    end

  end

  defp recur([], _wallet, _password, _delete) do
    {:error, "wallet not found"}
  end

  defp recur([head | tail], wallet, password, delete \\ false) do
    if delete do
      case Enum.member?(head, wallet) do
        true ->
          [iv | _name] = head
          iv_wallet = iv <> "_" <> wallet
          :ok = File.rm(@home_dir <> Enum.at(@koala_dirs, 2) <> "/" <> iv_wallet)
        false ->
          recur(tail, wallet, password, delete)
       end
    else
      case Enum.member?(head, wallet) do
        true ->
          [iv | _name] = head
          iv_wallet = iv <> "_" <> wallet
          {:ok, iv} = Base.decode64(iv)
          {:ok, seed} = File.read(@home_dir <> Enum.at(@koala_dirs, 2) <> "/" <> iv_wallet)
          {:ok, seed = AES256.decrypt(seed, password, iv)}

        false ->
          recur(tail, wallet, password)
      end
    end
  end

  @doc """
    new_wallet_seed/2

    Stores wallet seed with password and aes encryption
    proceeds to create a nano account stored in postgres with canoe tokens
    finally creates canoe account and registers said nano account with canoe

  """

  def new_wallet_seed(wallet_name, password \\ "koala") when is_bitstring(wallet_name) do
    {:ok, files} = File.ls @home_dir <> Enum.at(@koala_dirs, 2)

    files_names = for a <- files, do: String.split(a, "_", parts: 2)
    files_names = Enum.flat_map(files_names, fn [x, y] -> [y] end)
    IO.inspect wallet_name
    case Enum.member?(files_names, "#{wallet_name}.aes") do

      false ->

        seed = make_seed(password)
        result = @home_dir <> Enum.at(@koala_dirs, 2) <> "/#{Enum.at(seed, 0)}" <> "_#{wallet_name}.aes"
          |> File.write!(Enum.at(seed, 1))

        item = Koala.Wallet.Data.insert_wallet([name: String.to_atom(wallet_name |> String.capitalize), nonce: 0, balance: 0])
        tokens = [mqtt_token: item.mqtt_token,
                  mqtt_token_pass: item.mqtt_token_pass,
                  mqtt_wallet_id: item.mqtt_wallet_id
                 ]

        {:ok, seed} = get_seed(wallet_name, password)


        Koala.Canoe.new_account!(tokens)
      true ->

        {:error, "wallet already exists"}
    end

  end

  def kill_koala(wallet_name, [address | accounts]) do
    {:ok, _message} = Koala.Wallet.send_all_nano(wallet_name, address)
    {:ok, message} = Koala.Wallet.delete_account(wallet_name, address)
    kill_koala(wallet_name, accounts)
  end

  def kill_koala(wallet_name, []) do
    _result = Koala.Wallet.Data.burn_koala(wallet_name)
    :ok = burn_seed(wallet_name)

    wallet_name
      |> Koala.Wallet.get_wallet_id
      |> Tortoise.Connection.disconnect # what does this return?

      case pid = Koala.Wallet.get_pid(wallet_name) do
        nil  ->
           "its okay, it's aleady dead"
        pid ->
         :ok = Koala.Supervisor.terminate_child(pid)
      end

  end

  @doc """
    Deletes the blocks, addresses, wallet seed and name assioated with
    the wallet name give.
    * starts with getting a list of all wallets addresses
    * a recursive deletion is then put in place
    * ends with the postgres entry and seed file deleted
  """

  def kill_koala(wallet_name) do
    {:ok, accounts} = Koala.Wallet.accounts(wallet_name)
    kill_koala(wallet_name, accounts)
  end

  defp make_seed(password) do
    seed = Base.encode16(Koala.Nano.Tools.seed) |> AES256.encrypt(password) |> parsing_result()
    case Enum.at(seed, 0) |> String.contains?("/") do
      true ->
        IO.puts "FALSE"
        make_seed(password)
      false ->
        seed
    end

  end

  defp parsing_result(parse) do
    [
      iv = Base.encode64(Keyword.fetch!(parse, :iv)),
      ciph = Keyword.fetch!(parse, :ciphertext)
    ]
    # [iv, ciph]
  end

end
