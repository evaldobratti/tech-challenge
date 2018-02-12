defmodule Transaction do
  @moduledoc """
  Representa uma transação no sistema.
  """

  @doc """
  Valida e cria uma transação utilizando valores dos parametros.
  Uma transação sempre deverá possuír valores, então, dinheiro de origem e dinheiro de destino deverão ser diferentes de zero.

  # Parameters
    - id: identificação da transação
    - from: conta de origem e que receberá débito
    - from_money: dinheiro a ser debitado da conta de origem. Deve ser negativo.
    - to: conta de destino e que recebrá crédito
    - to_money: dinheiro a ser creditado na conta de destino. Deve ser positivo.
  """
  def create(id, from, from_money, to, to_money) do
    with {:ok} <- is_compatible_currencies(from, from_money),
         {:ok} <- is_compatible_currencies(to, to_money),
         {:ok} <- is_compatible_values(from_money, to_money) do
      cond do
        Money.is_positive(from_money) or Money.is_zero(to_money) ->
          {:error, "Debit in a transaction should be negative"}

        Money.is_negative(to_money) or Money.is_zero(to_money) ->
          {:error, "Credit in a transaction must be positive"}

        true ->
          {:ok, {id, {from, from_money}, {to, to_money}}}
      end
    else
      {:error, msg} -> {:error, msg}
    end
  end

  @doc """
    Valida que conta e o dinheiro informado possuem a mesma moeda.
  """
  def is_compatible_currencies(account, money) do
    account_currency = Account.get_native_currency(account)
    money_currency = Money.get_currency(money)

    if account_currency == money_currency do
      {:ok}
    else
      {:error,
       "Account #{Account.get_id(account)} does not operate with #{money_currency.code_alpha}"}
    end
  end

  defp is_compatible_values(from_money, to_money) do
    if Money.get_currency(from_money) == Money.get_currency(to_money) do
        if Money.negative(from_money) == to_money do
          {:ok}
        else
          {:error, "Transactions from same currencies must have same values"}
        end
    else
      {:ok}
    end
  end
end
