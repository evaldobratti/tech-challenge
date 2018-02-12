defmodule Money do
  @moduledoc """
  Representação do dinheiro no sistema.
  O dinheiro é representado pela tupla
  {parte_inteira, parte_exponencial, moeda}

  - Parte inteira representa a quantia pré virgula
  - Parte exponencial representa a quantia pós virgula
  - Moeda do dinheiro

  Para qualquer operação monetária, o dinheiro e convertido para inteiro para então retornar a representação de dinheiro novamente.
  
  @significant_floating_point
  Determina quantia de casas decimais que poderá ser utilizada para recuperar valores decimais pós cambio.
  Exemplo:
  $ 1.00 para R$ utlizando taxa de 3.33333

  A quantia significativa dessa conversão é de R$ 3.33, ficando R$ 0.00333 centavos de sobras.
  A quantia de casas decimais determinada por esse campo será utilizado para salvar essas sobras. 
  No caso acima, teríamos 33300
  Após 4 conversões de R$ 1.00 para $ utilizando a taxa de 3.33333 temos que a soma dessas sobras
  é suficiente para criar uma quantia significativa de R$
  33300 * 4 = 133200

  Podemos recuperar R$ 0.01 após as 4 conversões acimas.
  Esta funcionalidade não está incorporada no sistema financiero.
  """
  alias Currency

  @significant_floating_point 5

  @doc """
  Cria dinheiro utilizando a quantia e moeda informada.

  #Parameters
    - amount: quantia da moeda
    - currency: moeda
  """
  def create(amount, currency) when is_integer(amount) do
    create(amount / 1, currency)
  end

  @doc """
  Cria dinheiro utilizando a quantia e moeda informada.

  #Parameters
    - amount: quantia da moeda
    - currency: moeda
  """
  def create(amount, currency) when is_float(amount) do
    if currency == nil do
        {:error, "Currency is not present"}
    else
      no_comma_amout = Float.round(amount * Currency.factor(currency))

      {:ok, raw_integer(trunc(no_comma_amout), currency)}
    end
  end

  @doc """
  Soma de dinheiro. Ambos parametros devem ter a mesma moeda.
  """
  def sum({_, _, currency1} = money1, {_, _, currency2} = money2) do
    if currency1 != currency2 do
      {:error, "You can only sum money from the same currency"}
    else
      amount1 = to_raw_integer(money1)
      amount2 = to_raw_integer(money2)

      sum = amount1 + amount2

      {:ok, raw_integer(sum, currency1)}
    end
  end

  @doc """
  Inverte o sinal do dinheiro informado.
  A grandeza do dinheiro continuará a mesma.
  """
  def negative({integer, exponent, currency}) do
    {-integer, -exponent, currency}
  end

  @doc """
  Representação em string do dinheiro. A quantia de casas exponenciais da moeda é utilizada.
  Se a moeda conter sua representação, ela será utilizada.
  """
  def to_string({integer, exponent, currency}) do
    %{exponent: currency_exponent} = currency
    base = "#{currency.repr} #{integer}"
    if currency_exponent > 0 do
      exponent_part = exponent
      |> abs()
      |> Integer.to_string()
      |> String.pad_leading(currency_exponent, "0")
      base <> ".#{exponent_part}"
    else
      base
    end
  end

  @doc """
  Realiza cambio para a moeda utilizando a taxa informada.
  Cambios de-para mesma moeda devem ter taxa 1.

  A multiplicação será fluente utilizandoa representação inteira da moeda.
  A parte flutuante da multiplicação poderá ser utilizada para recuperação de centavos de conversão, conforme detalhado em 
  @significant_floating_point.

  # Parameters
    - money_from: dinheiro a sofrer cambio
    - currency_to: moeda de saída
    - rate: taxa de câmbio
  """
  def exchange({_, _, currency_from} = money_from, currency_to, rate) do
    if currency_from == currency_to do
       if rate != 1 do
            {:error, "Exchanging from to the same currency should have 1 as rate"}
       else
            {:ok, money_from, {0, currency_from}}
        end
    else
        amount = to_raw_integer(money_from)

        exchanged_amount = amount * rate
        significant = trunc(exchanged_amount)
        insignificant = exchanged_amount - significant

        leftover =
          (insignificant * :math.pow(10, @significant_floating_point))
          |> Float.round()
          |> trunc()

        {:ok, raw_integer(significant, currency_to), {leftover, currency_to}}
    end
  end

  @doc """
  Realiza a divisão de dinheiro.
  Retorna uma lista com as partes da divisão.
  É garantido que a soma dessas partes será igual ao valor informado no parâmetro.

  Exemplo: 
  R$ 2.33 / 5 não é exata (diferente de R$ 1.00 / 2 que resulta em 2 partes iguais de R$ 0.50).
  2.33 / 5 = 0.466 que após arredondamento fica R$ 0.47.
  Porém, R$ 0.47 * 5 = 2.35, que é diferente o parametro informado R$ 2.33.

  Esta função utilizará o valor truncado da divisão e distribuirá o valor restante da divisão nas primeiras partes.
  Logo, o resultado para a divisão de R$ 2.33 / 5 será 3 partes de R$ 0.47 e 2 partes de R$ 0.46.

  # Parameters
    - money: dinheiro a ser divido
    - divisor: divisor do dinheiro

  # Returns
    - Lista de dinheiro que representam a divisão
  """
  def divide({_, _, currency} = money, divisor) when is_integer(divisor) and divisor > 1 do
    amount = to_raw_integer(money)

    divided = div(amount, divisor)

    difference = amount - (divided * divisor)

    parts = Enum.map(1..divisor, fn(_) -> raw_integer(divided, currency) end)

    distributed_parts = distribute(difference, parts)

    distributed_parts
  end

  defp raw_integer(raw_integer, currency) when is_integer(raw_integer) do
    factor = Currency.factor(currency)

    integer = div(raw_integer, factor)
    exponent = rem(raw_integer, factor)

    {integer, exponent, currency}
  end

  defp to_raw_integer({integer, exponent, currency}) do
    factor = Currency.factor(currency)
    integer * factor + exponent
  end

  defp distribute(0, list) do
    list
  end

  defp distribute(difference, [ {_, _, currency} = part | others ]) do
    new_amount = to_raw_integer(part) + 1
    [raw_integer(new_amount, currency)] ++ distribute(difference - 1, others)
  end

  def is_negative(money) do
    to_raw_integer(money) < 0
  end

  def is_zero(money) do
    to_raw_integer(money) == 0
  end

  def is_positive(money) do
    to_raw_integer(money) > 0
  end

  def get_currency(money) do
    {_, _, currency} = money
    currency
  end

  def sum_parts(currency, moneys) do
    zero = Money.create(0, currency)
    Enum.reduce(moneys, zero, fn x, {:ok, acc} -> Money.sum(x, acc) end)
  end

  def can_recover(amount, currency) do
    factor = trunc(:math.pow(10, @significant_floating_point))
    if amount >= factor do
      {:ok, raw_integer(1, currency), amount - factor}
    else
      {:no}
    end
  end
end
