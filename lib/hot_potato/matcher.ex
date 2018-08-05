defmodule HotPotato.Matcher do

  defmacro __using__(_opts) do
    quote do
      import HotPotato.Matcher

      # Initialize @tests to an empty list
      @matchers []

      # Invoke TestCase.__before_compile__/1 before the module is compiled
      @before_compile HotPotato.Matcher
    end
  end

  defmacro match(regex, fun) do
    quote do
      @matchers @matchers ++ [[unquote(regex), unquote(fun)]]
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def do_match(slack, message) do
        %{channel: channel, user: user, text: text} = message
        match = Enum.find(@matchers, fn [regex, _] -> Regex.match?(regex, text) end)
        if match do
          [regex, fun] = match
          [_ | args] = Regex.run(regex, text)
          Kernel.apply(__MODULE__, fun, [slack | [channel | [user | args]]])
        end
      end
    end
  end
end
