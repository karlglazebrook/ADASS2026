-- csubraw.lua — Lua port of csubraw.py / csubraw.rb.
-- Run with luajit (or plain lua, but LuaJIT's tracing JIT is the
-- whole point of this benchmark).
--
-- Lua tables-of-tables.  iy outer / ix inner so each row is walked
-- sequentially.  Lua arrays are 1-indexed, so we use 0..n-1 *values*
-- but 1..n *indices* to keep arithmetic identical to the other ports.

local function subr(ina, nx, ny, out)
   for iy = 0, ny - 1 do
      local row_in  = ina[iy + 1]
      local row_out = out[iy + 1]
      for ix = 0, nx - 1 do
         row_out[ix + 1] = row_in[ix + 1] + ix + iy
      end
   end
end

local nrpt = tonumber(arg[1]) or 1000
local nx   = tonumber(arg[2]) or 2000
local ny   = tonumber(arg[3]) or 10

local ina, out = {}, {}
for iy = 0, ny - 1 do
   local rin, rout = {}, {}
   for ix = 0, nx - 1 do
      rin[ix + 1] = nx - ix + ny - iy
      rout[ix + 1] = 0
   end
   ina[iy + 1] = rin
   out[iy + 1] = rout
end

io.write(string.format("Arrays %d by %d count %d\n", nx, ny, nrpt))

for _ = 1, nrpt do subr(ina, nx, ny, out) end

for iy = 0, ny - 1 do
   for ix = 0, nx - 1 do
      if out[iy + 1][ix + 1] ~= ina[iy + 1][ix + 1] + ix + iy then
         io.write(string.format("Error: %s %d %d %s\n",
                                tostring(out[iy + 1][ix + 1]), ix, iy,
                                tostring(ina[iy + 1][ix + 1])))
         return
      end
   end
end
