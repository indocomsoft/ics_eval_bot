defmodule IcsEvalBot do
  @moduledoc """
  Documentation for IcsEvalBot.
  """

  @api_base_url "https://wandbox.org/api"
  @compile_path "/compile.json"
  @request_url "#{@api_base_url}#{@compile_path}"

  use ExGram.Bot, name: Application.get_env(:ics_eval_bot, :name)

  require Logger

  command("start")
  command("help")

  def handle({:command, "help@ics_eval_bot", %{}}, cnt) do
    handle({:command, :help, %{}}, cnt)
  end

  def handle({:command, :help, %{}}, cnt) do
    help_message =
      command_to_compiler()
      |> Enum.map(fn {command, compiler} ->
        "/#{command} code -- #{compiler}"
      end)
      |> Enum.join("\n")

    reply(cnt, "List of commands:\n#{help_message}")
  end

  def handle({:command, command, %{text: code}}, cnt) do
    compiler = Map.get(command_to_compiler(), command)

    if compiler do
      try do
        {status, output} = run(compiler, code)

        reply(cnt, "Status code: #{status}\nOutput:\n`#{output}`")
      rescue
        error ->
          reply(
            cnt,
            "An error occurred: `#{inspect(error)}`.\nPlease contact @indocomsoft about this."
          )
      end
    else
      reply(cnt, "Unrecognised command. Run `/help` to get a list of commands.")
    end
  end

  def handle(message, cnt) do
    Logger.info("Unknown command.")
    Logger.info("message = #{inspect(message)}")
    Logger.info("cnt = #{inspect(cnt)}")
  end

  defp run(compiler, code) when is_binary(compiler) and is_binary(code) do
    Logger.info("compiler = #{compiler}, code = #{code}")
    body = Jason.encode!(%{compiler: compiler, code: code})
    headers = [{"Content-Type", "application/json"}]
    %HTTPoison.Response{body: body} = HTTPoison.post!(@request_url, body, headers)
    decoded = Jason.decode!(body)
    {decoded["status"], decoded["program_message"]}
  end

  defp reply(cnt = %{update: %{message: %{message_id: message_id}}}, message) do
    answer(cnt, message, reply_to_message_id: message_id, parse_mode: "markdown")
  end

  defp command_to_compiler do
    [{:command_to_compiler, command_to_compiler}] =
      :ets.lookup(:command_to_compiler, :command_to_compiler)

    command_to_compiler
  end
end
