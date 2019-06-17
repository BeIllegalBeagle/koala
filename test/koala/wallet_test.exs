defmodule Koala.WalletTest do
  use ExUnit.Case, async: true

  @seed "D33918DE669B5D1E91616766465BF2A1FA8E56BC95C7598EEFC9F7ECAE43816F"
  @private_key "38DFB7F916219E9ABDB82F99EA6AD77A6CE6E516FA45D2ABF0923A6199659948"
  @public_key "xrb_3cdd8jdw7e3y3d9b4tqgmz5hhs9pihihzuj7o6f4f1e5oiazye3qt7fk43bd"

  @koala_password "koala_test"
  @home_dir System.user_home!()
  @koala_dirs ["/Library/Koala", "/Library/Koala/Logs", "/Library/Koala/Seeds"]
  @wallet_name Test_Wallet

  setup do
    # {:ok, state} = Koala.Interface.(wallet_id: @wallet_name, seed: @seed)
    # %{pid: state}
  end

  # test "getting wallet keys from seed and nonce 0" do
  #   assert {@private_key, @public_key} == Koala.Wallet.new_account(@wallet_name, @seed)
  # end
  #
  # test "checking if seed is stored successfully in file" do
  #   name_to_string = String.slice(to_string(@wallet_name), 7..-1)
  #   assert :ok = Koala.Interface.new_wallet_seed(name_to_string, @koala_password)
  # end



end
