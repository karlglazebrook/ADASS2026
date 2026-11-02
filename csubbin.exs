# csubbin.exs -- Elixir port on packed float64 binaries (2026).
#
# The BEAM's only contiguous unboxed numeric storage is a binary.  Each row is
# a binary of nx IEEE doubles (the layout Nx uses for a tensor).  csub walks
# each input row with a binary pattern match, <<v::float, rest::binary>>, and
# builds the output row by appending <<x::float>> to an accumulator; the
# runtime's binary-append optimisation makes that an in-place write into a
# growing buffer.  Because v is matched as ::float, the JIT knows its type and
# emits float arithmetic without a type test.  Element loop, float64.
#
#    elixir csubbin.exs 100 2000 10

defmodule CsubBin do
  def csub(ina, _nx, ny) do
    for iy <- 0..(ny - 1)//1, do: row(elem(ina, iy), 0, iy, <<>>)
  end

  defp row(<<v::float, rest::binary>>, ix, iy, acc),
    do: row(rest, ix + 1, iy, <<acc::binary, (v + ix + iy)::float>>)
  defp row(<<>>, _ix, _iy, acc), do: acc

  def main(args) do
    [nrpt, nx, ny] = Enum.map(args ++ Enum.drop(["100", "2000", "10"], length(args)), &String.to_integer/1)
    ina =
      for iy <- 0..(ny - 1)//1 do
        for ix <- 0..(nx - 1)//1, into: <<>>, do: <<(nx - ix + ny - iy) * 1.0::float>>
      end
      |> List.to_tuple()
    IO.puts("Arrays #{nx} by #{ny} count #{nrpt}")
    out = Enum.reduce(1..nrpt//1, nil, fn _, _ -> csub(ina, nx, ny) end)
    bad =
      for {outrow, iy} <- Enum.with_index(out),
          {{a, b}, ix} <- Enum.with_index(Enum.zip(for(<<a::float <- elem(ina, iy)>>, do: a),
                                                    for(<<b::float <- outrow>>, do: b))),
          b != a + ix + iy, do: {ix, iy}
    case bad do
      [{ix, iy} | _] -> IO.puts("Error: #{ix} #{iy}")
      [] -> :ok
    end
  end
end

CsubBin.main(System.argv())
