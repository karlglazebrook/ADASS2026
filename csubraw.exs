# csubraw.exs -- Elixir port with Erlang :array (2026).
#
# The BEAM has no mutable arrays. The closest thing to Keith's element
# access is Erlang's :array module: a functional tree with get/set by index.
# Each row is an :array; every csub call builds new rows by setting one
# element at a time, so this measures element-wise "update" in an immutable
# runtime. The BEAM's JIT (BeamAsm) compiles the code. csubmap.exs is the
# idiomatic Elixir form, a map over lists.
#
#    elixir csubraw.exs 100 2000 10

defmodule Csub do
  def csub(ina, nx, ny, out) do
    for iy <- 0..(ny - 1)//1 do
      inrow = elem(ina, iy)
      Enum.reduce(0..(nx - 1)//1, elem(out, iy), fn ix, row ->
        :array.set(ix, :array.get(ix, inrow) + ix + iy, row)
      end)
    end
    |> List.to_tuple()
  end

  def main(args) do
    [nrpt, nx, ny] = Enum.map(args ++ Enum.drop(["100", "2000", "10"], length(args)), &String.to_integer/1)
    ina = for(iy <- 0..(ny - 1)//1, do: :array.from_list(for(ix <- 0..(nx - 1)//1, do: (nx - ix + ny - iy) * 1.0))) |> List.to_tuple()
    out0 = for(_ <- 0..(ny - 1)//1, do: :array.new(nx, default: 0.0)) |> List.to_tuple()
    IO.puts("Arrays #{nx} by #{ny} count #{nrpt}")
    out = Enum.reduce(1..nrpt//1, out0, fn _, out -> csub(ina, nx, ny, out) end)
    bad = for iy <- 0..(ny - 1)//1, ix <- 0..(nx - 1)//1,
              :array.get(ix, elem(out, iy)) != :array.get(ix, elem(ina, iy)) + ix + iy, do: {ix, iy}
    case bad do
      [{ix, iy} | _] -> IO.puts("Error: #{ix} #{iy}")
      [] -> :ok
    end
  end
end

Csub.main(System.argv())
