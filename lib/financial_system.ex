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
      |> Map.put(currency, Enum.take(accounts, -3) |> List.to_tuple())
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
    money_currency = Money.get_currency(money)
    account_currency = Account.get_native_currency(account)
    cond do
      money_currency != account_currency -> {:error, "This account operate with #{account_currency.code_alpha}, you can't directly operate with #{money_currency.code_alpha} in it"}
      !is_registered_account(system, account) -> {:error, "Not registered account"}
      true ->
        deposit = get_deposit_account(system, money_currency)

        case Transaction.create(length(system.transactions) + 1, deposit, account, money) do
          {:ok, transaction} -> {:ok, %{system | transactions: system.transactions ++ [transaction]}, transaction }
          {:error, msg} -> {:error, msg}
        end
    end
  end

  def withdraw(system, account, money) do
    money_currency = Money.get_currency(money)
    account_currency = Account.get_native_currency(account)

    #TODO refactor this code and unify with deposit
    cond do
      money_currency != account_currency -> {:error, "This account operate with #{account_currency.code_alpha}, you can't directly operate with #{money_currency.code_alpha} in it"}
      !is_registered_account(system, account) -> {:error, "Not registered account"}
      true ->
        withdraw = get_withdraw_account(system, money_currency)
        account_limit = Account.get_limit(account)

        funds = balance(system, account)
        {:ok, funds} = Money.sum(funds, account_limit)
        {:ok, funds} = Money.sum(funds, Money.negative(money))

        cond do
          Money.is_negative(funds) -> {:error, "No sufficient funds"}
          true ->
            case Transaction.create(length(system.transactions) + 1, account, withdraw, money) do
              {:ok, transaction} -> {:ok, %{system | transactions: system.transactions ++ [transaction]}, transaction }
              {:error, msg} -> {:error, msg}
            end
        end
    end
  end

  defp get_deposit_account(system, currency) do
    {_, deposit, _} = Map.get(system, currency)
    deposit
  end

  defp get_withdraw_account(system, currency) do
    {_, _, withdraw} = Map.get(system, currency)
    withdraw
  end

  def is_registered_account(system, account) do
    Enum.member?(system.accounts, account)
  end

  def balance(system, account) do
    currency = Account.get_native_currency(account)
    zero = Money.create(0, currency)
    
    credits = system
      |> transactions_envolving(account)
      |> Enum.map(fn t -> 
        case t do
          {_, {^account, debit}, _} -> debit
          {_, _, {^account, credit}} -> credit
        end
      end)

    #TODO put reduce/sum in money module
    {:ok, balance} = Enum.reduce(credits, zero, fn(x, {:ok, acc}) -> Money.sum(x, acc) end)
    balance
  end

  def transactions_envolving(system, account) do
    Enum.filter(system.transactions, fn t ->
      case t do
        {_, {^account, _}, {_, _}} -> true
        {_, {_, _}, {^account, _}} -> true
        _ -> false
      end
    end)
  end

end
