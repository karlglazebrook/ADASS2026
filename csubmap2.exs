# csubmap2.exs -- Elixir, lists of rows, one explicit recursive pass per row.
#
# Same data as csubmap.exs (a list of row lists of floats) but the row is
# rebuilt by a body-recursive function that carries ix itself, instead of
# Enum.with_index |> Enum.map, which allocates a {v, ix} tuple list and walks
# each row twice.  This is how the hot path of an Elixir/Erlang library is
# written.  Element loop, float64.
#
#    elixir csubmap2.exs 100 2000 10

defmodule CsubMap2 do
  def csub(ina), do: rows(ina, 0)

  defp rows([r | t], iy), do: [row(r, 0, iy) | rows(t, iy + 1)]
  defp rows([], _iy), do: []

  defp row([v | t], ix, iy), do: [v + ix + iy | row(t, ix + 1, iy)]
  defp row([], _ix, _iy), do: []

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

CsubMap2.main(System.argv())
