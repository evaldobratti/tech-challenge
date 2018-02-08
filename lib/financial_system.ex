defmodule FinancialSystem do
  @moduledoc """
  Documentation for FinancialSystem.
  """

  alias Transaction

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
      {:ok, %{system | :accounts => accounts }, List.last(accounts)}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def deposit(system, account, money) do
    {_, _, currency} = money
    deposit = Map.get(system, currency) |> Enum.at(1)

    case Transaction.create(length(system.transactions) + 1, deposit, account, money) do
      {:ok, transaction} -> {:ok, %{system | transactions: system.transactions ++ [transaction]}, transaction }
      {:error, msg} -> {:error, msg}
    end
  end

  def balance(system, account) do
    limit = Account.get_limit(account)

    credits = system.transactions
      |> Enum.filter(fn t -> 
        {_, _, {transaction_account, _}} = t
        transaction_account == account
      end)
      |> Enum.map(fn t -> 
        {_, _, {_, money}} = t
        money
      end)

    #TODO put reduce/sum in money module
    Enum.reduce(credits, {:ok, limit}, fn(x, {:ok, acc}) -> Money.sum(x, acc) end)
  end

end
