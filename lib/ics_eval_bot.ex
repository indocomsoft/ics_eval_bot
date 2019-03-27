defmodule IcsEvalBot do
  @moduledoc """
  Documentation for IcsEvalBot.
  """

  @api_base_url "https://wandbox.org/api"
  @compile_path "/compile.json"
  @request_url "#{@api_base_url}#{@compile_path}"

  @command_to_compiler %{"ex" => "elixir-head"}

  @help_message Enum.map(@command_to_compiler, fn {command, compiler} ->
                  "/#{command} code -- #{compiler}\n"
                end)

  use ExGram.Bot, name: Application.get_env(:ics_eval_bot, :name)

  require Logger

  command("start")
  command("help")

  def handle({:command, "help@ics_eval_bot", %{}}, cnt) do
    handle({:command, :help, %{}}, cnt)
  end

  def handle({:command, :help, %{}}, cnt) do
    answer(cnt, @help_message, parse_mode: "markdown")
  end

  def handle({:command, command, %{text: code}}, cnt) do
    compiler = Map.get(@command_to_compiler, command)

    if compiler do
      try do
        {status, output} = run(compiler, code)
        answer(cnt, "Status code: #{status}\nOutput:\n`#{output}`", parse_mode: "markdown")
      rescue
        error ->
          answer(
            cnt,
            "An error occurred: `#{inspect(error)}`.\nPlease contact @indocomsoft about this.",
            parse_mode: "markdown"
          )
      end
    else
      answer(cnt, "Unrecognised command. Run `/help` to get a list of commands.",
        parse_mode: "markdown"
      )
    end
  end

  def handle(message, cnt) do
    Logger.info("Unknown command.")
    Logger.info("message = #{inspect(message)}")
    Logger.info("cnt = #{inspect(cnt)}")
  end

  defp run(compiler, code) do
    body = Jason.encode!(%{compiler: compiler, code: code})
    headers = [{"Content-Type", "application/json"}]
    %HTTPoison.Response{body: body} = HTTPoison.post!(@request_url, body, headers)
    decoded = Jason.decode!(body)
    {decoded["status"], decoded["program_message"]}
  end
end
