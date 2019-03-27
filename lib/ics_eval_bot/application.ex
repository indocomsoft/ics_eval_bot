defmodule IcsEvalBot.Application do
  @moduledoc false

  use Application

  require Logger

  def start(_type, _args) do
    token = ExGram.Config.get(:ex_gram, :token)

    children = [
      ExGram,
      {IcsEvalBot, [method: :polling, token: token]}
    ]

    opts = [strategy: :one_for_one, name: IcsEvalBot.Supervisor]
    result = Supervisor.start_link(children, opts)

    Logger.info("ics_eval_bot started")

    result
  end
end
