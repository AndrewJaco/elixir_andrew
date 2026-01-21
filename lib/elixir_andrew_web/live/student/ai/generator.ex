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
    
    call_ai(prompt, Schemas.CrosswordSchema.schema())
  end

  @doc """
  Generate definitions for matching game.
  Returns {:ok, %{"words" => [%{"word" => "...", "definition" => "..."}]}} or {:error, reason}
  """
  def generate_definitions(words, progress) do
    prompt = PromptBuilder.matching_prompt(%{
      progress: progress,
      words: words
    })
    
    call_ai(prompt, Schemas.MatchingSchema.schema())
  end

  @doc """
  Generic AI call with schema validation.
  """
  defp call_ai(prompt, schema, opts \\ []) do
    model = Keyword.get(opts, :model, "gpt-4")
    temperature = Keyword.get(opts, :temperature, 0.7)
    
    chain = 
      %{llm: ChatOpenAI.new!(%{model: model, temperature: temperature})}
      |> LLMChain.new!()
      |> LLMChain.add_messages([
        Message.new_system!("You are an ESL educational content generator. Always respond with valid JSON matching the provided schema."),
        Message.new_user!(prompt)
      ])
    
    case LLMChain.run(chain) do
      {:ok, result} ->
        response_text = 
          result.last_message.content
          |> ContentPart.content_to_string()
        
        parse_and_validate(response_text, schema)
      
      {:error, reason} ->
        {:error, {:api_error, reason}}
    end
  end

  defp parse_and_validate(response_text, schema) do
    with {:ok, json} <- Jason.decode(response_text),
         :ok <- validate_schema(json, schema) do
      {:ok, json}
    else
      {:error, %Jason.DecodeError{}} -> {:error, :invalid_json}
      {:error, :schema_validation_failed} -> {:error, :schema_validation_failed}
      _ -> {:error, :invalid_ai_response}
    end
  end

  defp validate_schema(data, schema) do
    case ExJsonSchema.Validator.validate(schema, data) do
      :ok -> :ok
      {:error, _errors} -> {:error, :schema_validation_failed}
    end
  end
end