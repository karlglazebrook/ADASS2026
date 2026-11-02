-- csubflt.lua -- csubraw.lua with float (double) elements (2026 review
-- variant).  Lua 5.3+ and LuaJIT on arm64 both have an integer subtype, so
-- csubraw.lua's  nx - ix + ny - iy  values are integers and the kernel adds
-- integers.  Multiplying by 1.0 makes the stored values floats, as in the
-- other ports.
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
      rin[ix + 1] = (nx - ix + ny - iy) * 1.0
      rout[ix + 1] = 0.0
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
