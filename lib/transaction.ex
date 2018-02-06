defmodule Transaction do
  
  def create(from, to, money) do
    cond do
      Money.is_negative(money) or Money.is_zero(money) -> {:error, "Money from a transaction must be positive"}
      true -> {:ok, {{from, Money.negative(money)}, {to, money}}}  
    end
  end
end