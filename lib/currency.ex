defmodule Currency do
  @moduledoc """
  Estrutura de dados para representação de moedas segundo ISO 4217
  """

  defstruct code_alpha: nil, code_number: nil, exponent: nil, repr: ""

  @doc """
  Cria uma nova moeda conforme ISO 4217

  ## Paramters
    - code_alpha: código alfabético da moeda
    - code_number: código numéritco (em string) da moeda
    - exponent: quantia de casas decimais da moeda
    - repr: representação da moeda para formatação de dinheiro
  """
  def create(code_alpha, code_number, exponent, repr \\ "") do
    cond do
      not is_binary(code_alpha) -> {:error, "Alphabetic code should be a string"}
      String.length(code_alpha) != 3 -> {:error, "Alphabetic code should have 3 letters"}
      
      not is_binary(code_number) -> {:error, "Numeric code should be a string"}
      Integer.parse(code_number) == :error -> {:error, "Numeric code should have only numbers"}
      String.length(code_number) != 3 -> {:error, "Numeric code should have 3 digits"}
      
      not is_integer(exponent) -> {:error, "Exponent should be an integer"}
      exponent < 0 -> {:error, "Exponent should be positive"}

      true -> {:ok, %Currency{code_alpha: code_alpha, code_number: code_number, exponent: exponent, repr: repr}}
    end
  end

  def factor(currency) do
    trunc(:math.pow(10, currency.exponent))
  end
end
