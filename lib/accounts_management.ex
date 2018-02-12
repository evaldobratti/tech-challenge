defmodule AccountsManagement do
  @moduledoc """
  Administra um conjunto de contas
  """

  @doc """
  Adiciona uma nova a coleção.
  A identificação será o tamanho da coleção + 1

  ## Parameters 
    - accounts: coleção de contas atual
    - name: nome do usuário da conta
    - limit: dinheiro limite da conta
  """
  def add(accounts, name, limit) do
    if Enum.find(accounts, fn existing -> Account.get_name(existing) == name end) do
      {:error, "Already registered account"}
    else
      case Account.create(length(accounts) + 1, name, limit) do
        {:ok, account} -> {:ok, accounts ++ [account]}
        {:error, error} -> {:error, error}
      end
    end
  end
end
