defmodule Account do
  @moduledoc """
  Representa uma conta.
  """

  @doc """
  Cria uma nova conta.
  A conta poderá ter um limite, que possibilitará a conta ficar negativa até esse valor.
  A conta assumirá como moeda de transação a moeda do dinheiro informado como limite.

  ## Parameters
    - id: identificação da conta
    - owner_name: nome do usuário da conta
    - limit: limite da conta. A moeda desse dinheiro será usado como moeda nativa da conta.
  """
  def create(id, owner_name, {_, _, currency} = limit) do
    cond do
      owner_name == nil -> {:error, "Name should not be nil"}
      !is_binary(owner_name) -> {:error, "Name should be a string"}
      String.length(owner_name) == 0 -> {:error, "Name should not be empty"}
      Money.is_negative(limit) -> {:error, "Limit should not be negative"}
      true -> {:ok, {id, owner_name, limit, currency}}
    end
  end

  def get_id(account) do
    elem(account, 0)
  end

  def get_name(account) do
    elem(account, 1)
  end

  def get_native_currency(account) do
    elem(account, 3)
  end

  def get_limit(account) do
    elem(account, 2)
  end
end
