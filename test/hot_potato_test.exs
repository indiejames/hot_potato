defmodule HotPotatoTest do
  use ExUnit.Case
  use ExUnitProperties

  doctest HotPotato

  property "`in` works with lists" do
    check all list <- list_of(term()),
              list != [],
              elem <- member_of(list) do
      assert elem in list
    end
  end

  property "sum of positive integers is greater than both integers" do
    check all x <- StreamData.integer() |> filter(fn x -> x > 0 end),
              y <- StreamData.integer() |> filter(fn y -> y > 0 end),
              sum <- StreamData.constant(x+y) do
      assert sum > x && sum > y
    end
  end

  test "the truth" do
    assert 1 + 1 == 2
  end
end
