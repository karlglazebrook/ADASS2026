-- csubffi.lua -- LuaJIT FFI port (2026 review variant of csubraw.lua).
-- The arrays are C double[] buffers from the FFI library (unboxed,
-- contiguous, flat index iy*nx+ix), which is how LuaJIT users write numeric
-- kernels.  LuaJIT only: plain Lua has no ffi module.
local ffi = ffi or require("ffi")

local function subr(ina, nx, ny, out)
   for iy = 0, ny - 1 do
      local base = iy * nx
      for ix = 0, nx - 1 do
         out[base + ix] = ina[base + ix] + ix + iy
      end
   end
end

local nrpt = tonumber(arg[1]) or 1000
local nx   = tonumber(arg[2]) or 2000
local ny   = tonumber(arg[3]) or 10

local ina = ffi.new("double[?]", nx * ny)
local out = ffi.new("double[?]", nx * ny)
for iy = 0, ny - 1 do
   for ix = 0, nx - 1 do
      ina[iy * nx + ix] = nx - ix + ny - iy
      out[iy * nx + ix] = 0
   end
end

io.write(string.format("Arrays %d by %d count %d\n", nx, ny, nrpt))

for _ = 1, nrpt do subr(ina, nx, ny, out) end

for iy = 0, ny - 1 do
   for ix = 0, nx - 1 do
      local k = iy * nx + ix
      if out[k] ~= ina[k] + ix + iy then
         io.write(string.format("Error: %s %d %d %s\n",
                                tostring(out[k]), ix, iy, tostring(ina[k])))
         return
      end
   end
end
