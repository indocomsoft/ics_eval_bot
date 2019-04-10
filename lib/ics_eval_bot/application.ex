defmodule IcsEvalBot.Application do
  @moduledoc false

  @api_base_url "https://wandbox.org/api"
  @compile_path "/list.json"
  @request_url "#{@api_base_url}#{@compile_path}"

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
    load_ets()

    Logger.info("ics_eval_bot started")

    result
  end

  defp load_ets do
    %HTTPoison.Response{body: body} = HTTPoison.get!(@request_url)

    additional_command_to_compiler = %{
      "gcc" => "gcc-head-c",
      "clang" => "clang-head-c",
      "rb" => "ruby-head"
    }

    compilers =
      Jason.decode!(body)
      |> Enum.map(fn %{"name" => name} -> name end)
      |> Enum.filter(&String.ends_with?(&1, "-head"))
      |> Enum.reject(&(&1 == "gcc-head"))
      |> Enum.reject(&(&1 == "clang-head"))

    command_to_compiler =
      Enum.reduce(compilers, additional_command_to_compiler, fn x, acc ->
        Map.put(acc, String.replace_suffix(x, "-head", ""), x)
      end)

    :ets.new(:command_to_compiler, [:named_table])
    :ets.insert(:command_to_compiler, {:command_to_compiler, command_to_compiler})
  end
end
