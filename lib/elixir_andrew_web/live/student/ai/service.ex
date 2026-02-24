defmodule ElixirAndrewWeb.Live.Student.AI.Service do
  @moduledoc """
  Generic AI service for all educational content generation.
  Handles OpenAI API calls, schema validation, and error handling.
  """
  
  alias LangChain.ChatModels.ChatOpenAI
  alias LangChain.Chains.LLMChain
  alias LangChain.Message
  alias LangChain.Message.ContentPart
  alias ElixirAndrewWeb.Live.AI.PromptBuilder
  alias ElixirAndrewWeb.Live.Student.AI.Schemas

  @doc """
  Generate crossword clues for spelling words.
  Returns {:ok, %{"words" => [%{"word" => "...", "clue" => "..."}]}} or {:error, reason}
  """
  def generate_crossword(words, progress, opts \\ []) do
    max_words = Keyword.get(opts, :max_words, 10)
    
    prompt = PromptBuilder.crossword_prompt(%{
      progress: progress,
      words: words,
      max_words: max_words
    })
    
    # Max tokens for crossword clues: 300 tokens
    ai_opts = Keyword.merge([max_completion_tokens: 300], opts)
    call_ai(prompt, Schemas.CrosswordSchema.schema(), ai_opts)
  end

  @doc """
  Generate definitions for matching game and flashcards.
  Returns {:ok, %{"words" => [%{"word" => "...", "definition" => "..."}]}} or {:error, reason}
  """
  def generate_definitions(words, progress, opts \\ []) do
    prompt = PromptBuilder.matching_prompt(%{
      progress: progress,
      words: words
    })
    
    # Max tokens for definitions: 200 tokens (short definitions only)
    ai_opts = Keyword.merge([max_completion_tokens: 200], opts)
    call_ai(prompt, Schemas.MatchingSchema.schema(), ai_opts)
  end

  defp call_ai(prompt, schema, opts \\ [], retries_left \\ 2)
  
  defp call_ai(prompt, schema, opts, retries_left) do
    case do_call_ai(prompt, schema, opts) do
      {:ok, result} ->
        {:ok, result}
      
      {:error, :invalid_json} when retries_left > 0 ->
        IO.puts("AI call failed: #{inspect(:invalid_json)}. Retrying... (#{retries_left} retries left)")
        call_ai(prompt, schema, opts, retries_left - 1)
      
      {:error, :empty_response} ->
        IO.puts("AI call failed after retries: #{inspect(:empty_response)}")
        call_ai(prompt, schema, opts, retries_left - 1)

      {:error, reason} ->
        IO.puts("AI call failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp do_call_ai(prompt, schema, opts) do
    model = Keyword.get(opts, :model, "gpt-5-nano-2025-08-07")  
    temperature = Keyword.get(opts, :temperature, 1.0)
    max_completion_tokens = Keyword.get(opts, :max_completion_tokens, 200)


    # Configure OpenAI with response_format for structured output
    llm = ChatOpenAI.new!(%{
      model: model,
      temperature: temperature,
      max_completion_tokens: max_completion_tokens,
      stream: false,
      receive_timeout: 60_000,
      retry: false,
      max_retries: 3,
      response_format: %{
        type: "json_schema",
        json_schema: %{
          name: "response",
          strict: true,
          schema: schema
        }
      }
    })
    
    chain = 
      %{llm: llm}
      |> LLMChain.new!()
      |> LLMChain.add_messages([
        Message.new_system!(
          """
          You are an ESL educational content generator.
          You MUST return ONLY valid JSON.
          Do NOT include markdown, explanations, or extra text.
          Output must strictly match the provided JSON schema.
          """
        ),
        Message.new_user!(prompt)
      ])
    
    case LLMChain.run(chain) do
      {:ok, result} ->
        with {:ok, text} <- extract_text(result),
             {:ok, parsed} <- parse_and_validate(text, schema) do
          {:ok, parsed}
        end
        
        {:error, _chain, %LangChain.LangChainError{message: message}} ->
          {:error, {:api_error, message}}
        
        {:error, reason} ->
          {:error, {:api_error, reason}}
    end
  end

  defp extract_text(result) do
    case result.last_message.content do
      nil ->
        {:error, :empty_response}

      content_parts when is_list(content_parts) ->
        case Enum.find(content_parts, &(&1.type == :output_text)) do
          %ContentPart{content: text} when is_binary(text) and text != "" ->
            {:ok, text}

          _ ->
            {:error, :invalid_json}
        end

      text when is_binary(text) and text != "" ->
        {:ok, text}

      _ ->
        {:error, :invalid_json}
    end
  end

  defp parse_and_validate("", _schema), do: {:error, :empty_response}

  defp parse_and_validate(response_text, schema) do
    IO.inspect(response_text, label: "Raw AI Response")
    with {:ok, json} <- Jason.decode(response_text),
        {:ok, repaired} <- repair_keys(json),
        :ok <- validate_schema(repaired, schema) do
      {:ok, repaired}
    else
      {:error, _} = err -> err
    end
  end

  defp repair_keys(%{"clues" => clues}), do: {:ok, %{"words" => clues}}
  defp repair_keys(json), do: {:ok, json}

  defp validate_schema(data, schema) do
    case ExJsonSchema.Validator.validate(schema, data) do
      :ok -> :ok
      {:error, _errors} -> {:error, :schema_validation_failed}
    end
  end
end