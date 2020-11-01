defmodule Primy.Prime do
  def is_prime?(0) do
    false
  end

  def is_prime?(1) do
    true
  end

  def is_prime?(n) when is_integer(n) and n >= 0 do
    r = :random.uniform(n - 1)
    mpow(r, n - 1, n) == 1
  end

  def is_prime?(n) when is_integer(n) and n < 0 do
    raise ArgumentError, message: "Expected a non-negative integer, got: #{n}"
  end

  def is_prime?(n) when not is_integer(n) do
    raise ArgumentError, message: "Expected an integer; got: #{inspect(n)}"
  end

  defp mpow(n, 1, _) do
    n
  end

  defp mpow(n, k, m) do
    mpow(rem(k, 2), n, k, m)
  end

  defp mpow(0, n, k, m) do
    x = mpow(n, div(k, 2), m)
    rem(x * x, m)
  end

  defp mpow(_, n, k, m) do
    x = mpow(n, k - 1, m)
    rem(x * n, m)
  end
end
