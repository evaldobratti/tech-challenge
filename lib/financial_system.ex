defmodule FinancialSystem do
  @moduledoc """
  Documentation for FinancialSystem.
  """

  def create(name) do
    %{name: name, accounts: [], transactions: []}
  end

  def create_currency_control_accounts(system, currency) do
    %{code_alpha: code_alpha} = currency
    with {:ok, zero} <- Money.create(0, currency),
      {:ok, accounts} <- AccountsManagement.add(system.accounts, "bank " <> code_alpha, zero),
      {:ok, accounts} <- AccountsManagement.add(accounts, "deposit " <> code_alpha, zero),
      {:ok, accounts} <- AccountsManagement.add(accounts, "withdrawal " <> code_alpha, zero)
    do
      %{system | :accounts => accounts}
      |> Map.put(currency, Enum.take(accounts, -3))
    else
      {:error, "Already registered account"} -> system
    end
  end

  def add_account(system, account_name, limit) do
    {_, _, currency} = limit

    with system <- create_currency_control_accounts(system, currency),
      {:ok, accounts} <- AccountsManagement.add(system.accounts, account_name, limit)
    do
      {:ok, %{system | :accounts => accounts }}
    else
      {:error, msg} -> {:error, msg}
    end
  end

end
