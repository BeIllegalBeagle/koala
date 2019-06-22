# Koala - Light-Wallet for the nano cryptocurrency

## Setup

A postgres setup is needed with the username koala and password eucyltpe
and certificate file and key file for SSL is needed in the home directory of your computer

### Create a new wallet

**new_wallet_seed/2**

Stores wallet seed with password and aes encryption
proceeds to create a nano account stored in postgres with canoe tokens
finally creates canoe account and registers said nano account with canoe
If not password is provided for the second argument, it is "koala" by default

```elixir
    Koala.Interface.new_wallet_seed(wallet_name, password)
```
### Starting Koala Genserver

**koala_start/2**

This function starts the koala Genserver with an existing wallet created with 
a wallet name used wth the **new_wallet_seed/2** function

```elixir
    Koala.Interface.koala_start(wallet_name, password)
```

### Delete Wallet and end Koala Genserver

```elixir
def deps do
[
{:koala, "~> 0.1.0"}
]
end
```

### Send nano

```elixir
    Koala.Wallet.send_nano(wallet_name, recipient, from_address, amount_in_raw)
```

### Create new nano address

```elixir
    Koala.Wallet.new_account(wallet_name)
```

### Delete nano address

```elixir
    Koala.Wallet.delete_account.(wallet_name, address_name)
```


