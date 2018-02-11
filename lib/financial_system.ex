defmodule FinancialSystem do
  @moduledoc """
  Documentation for FinancialSystem.
  """

  alias Transaction

  def create(name) do
    %{name: name, accounts: [], transactions: [], private_accounts: []}
  end

  def create_currency_control_accounts(system, currency) do
    %{code_alpha: code_alpha} = currency

    if Map.get(system, currency) == nil do
      with {:ok, zero} <- Money.create(0, currency),
          {:ok, accounts} <- AccountsManagement.add(system.accounts, "bank " <> code_alpha, zero),
          {:ok, accounts} <- AccountsManagement.add(accounts, "deposit " <> code_alpha, zero),
          {:ok, accounts} <- AccountsManagement.add(accounts, "withdrawal " <> code_alpha, zero) do
        currency_accounts = Enum.take(accounts, -3)
        private_accounts = system.private_accounts ++ currency_accounts

        %{system | :accounts => accounts, :private_accounts => private_accounts}
        |> Map.put(currency, List.to_tuple(currency_accounts))
      else
        {:error, "Already registered account"} -> system
      end
    else
      system
    end
  end

  def add_account(system, account_name, limit) do
    {_, _, currency} = limit

    with system <- create_currency_control_accounts(system, currency),
         {:ok, accounts} <- AccountsManagement.add(system.accounts, account_name, limit) do
      {:ok, %{system | :accounts => accounts}, List.last(accounts)}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def deposit(system, account, money) do
    case Transaction.is_compatible_currencies(account, money) do
      {:ok} -> deposit_exchange(system, account, money, 1)
      {:error, msg} -> {:error, msg}
    end
  end

  def withdraw(system, account, money) do
    case Transaction.is_compatible_currencies(account, money) do
      {:ok} -> withdraw_exchange(system, account, money, Money.get_currency(money), 1)
      {:error, msg} -> {:error, msg}
    end
  end

  def transfer(system, from, to, money) when not is_list(to) do
    with {:ok} <-valid_transfer(system, from, to),
      {:ok} <- Transaction.is_compatible_currencies(from, money),
      {:ok} <- Transaction.is_compatible_currencies(to, money) do
      transfer(system, from, to, money, true)
    else
      {:error, msg} -> {:error, msg}
    end
  end

  def transfer(system, from, list_to, money) when is_list(list_to) do
    parts = Money.divide(money, length(list_to))

    case transfer_parts(system, from, list_to, parts) do
      {:ok, system, _} -> {:ok, system, Enum.take(system.transactions, -length(list_to))}
      {:error, message} -> {:error, message}
    end
  end

  def deposit_exchange(system, account, money, rate) do
    account_currency = Account.get_native_currency(account)
    money_currency = Money.get_currency(money)
    {:ok, exchanged, _} = Money.exchange(money, account_currency, rate)
    {system, deposit_account} = get_deposit_account(system, money_currency)
    transfer(system, deposit_account, Money.negative(money), account, exchanged, false)
  end

  def withdraw_exchange(system, account, money, currency, rate) do
    {:ok, exchanged, _} = Money.exchange(money, currency, rate)
    {system, withdraw_account} = get_withdraw_account(system, currency)
    transfer(system, account, Money.negative(money), withdraw_account, exchanged, true)
  end

  def transfer_exchange(system, from, to, money, rate) do
    to_currency = Account.get_native_currency(to)
    {:ok, exchanged, _} = Money.exchange(money, to_currency, rate)
    
    with {:ok} <- valid_transfer(system, from, to),
      {:ok} <- Transaction.is_compatible_currencies(from, money),
      {:ok} <- Transaction.is_compatible_currencies(to, exchanged) do
      transfer(system, from, Money.negative(money), to, exchanged, true)
    else
      {:error, msg} -> {:error, msg}
    end
  end

  defp transfer_parts(system, from, [to | others_to], [part | others_parts]) do
    case valid_transfer(system, from, to) do
      {:ok} ->
        case transfer(system, from, to, part, true) do
          {:ok, system, transaction} ->
            if length(others_to) > 0 do
              transfer_parts(system, from, others_to, others_parts)
            else
              {:ok, system, transaction}
            end
          {:error, msg} ->
            {:error, msg}
        end

      {:error, msg} ->
        {:error, msg}
    end
  end

  def valid_transfer(system, from, to) do
    cond do
      is_private_account(system, from) -> {:error, "You cannot transfer using private accounts"}
      is_private_account(system, to) -> {:error, "You cannot transfer using private accounts"}
      true -> {:ok}
    end
  end

  defp is_private_account(system, account) do
    Enum.member?(system.private_accounts, account)
  end

  defp transfer(system, from, to, money, check_funds) do
    transfer(system, from, Money.negative(money), to, money, check_funds)
  end

  defp transfer(system, from, from_money, to, to_money, check_funds) do
    cond do
      !is_registered_account(system, from) ->
        {:error, "Not registered account"}

      !is_registered_account(system, to) ->
        {:error, "Not registered account"}

      true ->
        has_funds =
          if check_funds do
            account_limit = Account.get_limit(from)

            funds = balance(system, from)
            {:ok, funds} = Money.sum(funds, account_limit)
            {:ok, funds} = Money.sum(funds, from_money)
            Money.is_positive(funds) or Money.is_zero(funds)
          else
            true
          end

        cond do
          !has_funds ->
            {:error, "No sufficient funds"}

          true ->
            case Transaction.create(length(system.transactions) + 1, from, from_money, to, to_money) do
              {:ok, transaction} ->
                {:ok, %{system | transactions: system.transactions ++ [transaction]}, transaction}

              {:error, msg} ->
                {:error, msg}
            end
        end
    end
  end

  defp get_deposit_account(system, currency) do
    system = create_currency_control_accounts(system, currency)
    {_, deposit, _} = Map.get(system, currency)
    {system, deposit}
  end

  defp get_withdraw_account(system, currency) do
    system = create_currency_control_accounts(system, currency)
    {_, _, withdraw} = Map.get(system, currency)
    {system, withdraw}
  end

  def is_registered_account(system, account) do
    Enum.member?(system.accounts, account)
  end

  def balance(system, account) do
    currency = Account.get_native_currency(account)
    zero = Money.create(0, currency)

    credits =
      system
      |> transactions_envolving(account)
      |> Enum.map(fn t ->
        case t do
          {_, {^account, debit}, _} -> debit
          {_, _, {^account, credit}} -> credit
        end
      end)

    # TODO put reduce/sum in money module
    {:ok, balance} = Enum.reduce(credits, zero, fn x, {:ok, acc} -> Money.sum(x, acc) end)
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
