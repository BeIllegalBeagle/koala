defmodule Koala.Canoe.MitoNode do
  use Tesla

  plug Tesla.Middleware.BaseUrl, "http://167.71.53.228:4000/api"
  plug Tesla.Middleware.Headers, [{"authorization", "token xyz"}]
  plug Tesla.Middleware.JSON

  @doc """

    modules currently made only to replace these canoe functions
  """

  def work_generate(hash) do
    {:ok, response} = post("/genrate-work", %{hash: "#{hash}"})
    {:ok, response.body}
  end

  def register_wallet(wallet_id) do
    {:ok, response} = post("/register-wallet", %{wallet_name: "#{wallet_id}"})
  end

  #pass through the wallet object
  # #should be linked to koala genserver
  #   def canoe_start(state_tokens) do
  #
  #     wallet_id = Keyword.fetch!(state_tokens, :mqtt_wallet_id)
  #     {:ok, _pid} = Tortoise.Supervisor.start_child(
  #     client_id: wallet_id,
  #     handler: {Koala.Canoe.Handler, []},
  #     server:
  #       {Tortoise.Transport.SSL,
  #         [host: 'getcanoe.io',
  #          port: 1885,
  #          cacertfile: :certifi.cacertfile(),
  #          verify: :verify_none,
  #          keyfile: @home <> @key,
  #          certfile: @home <> @cert
  #         ]},
  #     keep_alive: 300000,
  #     user_name: Keyword.fetch!(state_tokens, :mqtt_token),
  #     password: Keyword.fetch!(state_tokens, :mqtt_token_pass))
  #   end

    def canoe_start(state_tokens) do

      wallet_id = Keyword.fetch!(state_tokens, :mqtt_wallet_id)

      {:ok, _pid} = Tortoise.Supervisor.start_child(
        client_id: wallet_id,
        handler: {Koala.Canoe.Handler, []},
        server:
          {Tortoise.Transport.Tcp,
            [host: '167.71.53.228',
             port: 1883,
            ]},
        keep_alive: 300000
        )
    end
end
