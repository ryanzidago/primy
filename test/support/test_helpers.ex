defmodule Support.TestHelpers do
  def wait_until(func) when is_function(func) do
    case func.() do
      result when result == [] or is_nil(result) -> :timer.sleep(100) && func.()
      result -> result
    end
  end
end
