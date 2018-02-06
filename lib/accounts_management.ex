defmodule AccountsManagement do
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
