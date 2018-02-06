defmodule Account do
  @doc """
  {owner_name, limit, native_currency}
  """
  def create(owner_name, {_, _, currency} = limit) do
    cond do
      owner_name == nil -> {:error, "Name should not be nil"}
      !is_binary(owner_name) -> {:error, "Name should be a string"}
      String.length(owner_name) == 0 -> {:error, "Name should not be empty"}
      Money.is_negative(limit) -> {:error, "Limit should not be negative"}
      true -> {:ok, {owner_name, limit, currency}}
    end
  end

  def id({name, _, _}) do
    name
  end
end
