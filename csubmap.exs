# csubmap.exs -- Elixir port, idiomatic (2026).
#
# How Elixir would actually do it: the arrays are lists of row lists, and
# csub maps over them with their indices, building a new out each call.
# No element is "accessed" by index at all. Compare csubraw.exs (:array).
#
#    elixir csubmap.exs 100 2000 10

defmodule CsubMap do
  def csub(ina) do
    ina
    |> Enum.with_index()
    |> Enum.map(fn {row, iy} ->
      row |> Enum.with_index() |> Enum.map(fn {v, ix} -> v + ix + iy end)
    end)
  end

  def main(args) do
    [nrpt, nx, ny] = Enum.map(args ++ Enum.drop(["100", "2000", "10"], length(args)), &String.to_integer/1)
    ina = for iy <- 0..(ny - 1)//1, do: for(ix <- 0..(nx - 1)//1, do: (nx - ix + ny - iy) * 1.0)
    IO.puts("Arrays #{nx} by #{ny} count #{nrpt}")
    out = Enum.reduce(1..nrpt//1, nil, fn _, _ -> csub(ina) end)
    bad = for {{inrow, outrow}, iy} <- Enum.with_index(Enum.zip(ina, out)),
              {{a, b}, ix} <- Enum.with_index(Enum.zip(inrow, outrow)), b != a + ix + iy, do: {ix, iy}
    case bad do
      [{ix, iy} | _] -> IO.puts("Error: #{ix} #{iy}")
      [] -> :ok
    end
  end
end

CsubMap.main(System.argv())
