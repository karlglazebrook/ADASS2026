--  csubraw.adb -- Ada port (2026).
--
--  A true 2D array type over Long_Float (64-bit), indexed (Iy, Ix) in nested
--  loops. Ada checks every array index against its bounds by default (and
--  integer overflow); Run.py builds it with gnatmake -O3, checks on, and
--  with -O3 -gnatp, which suppresses all of them.
--
--     gnatmake -O3 csubraw.adb -o csub_ada && ./csub_ada 100 2000 10

with Ada.Command_Line; use Ada.Command_Line;
with Ada.Text_IO;      use Ada.Text_IO;

procedure Csubraw is
   type Matrix is array (Natural range <>, Natural range <>) of Long_Float;

   procedure Csub (Input : Matrix; Nx, Ny : Natural; Output : in out Matrix) is
   begin
      for Iy in 0 .. Ny - 1 loop
         for Ix in 0 .. Nx - 1 loop
            Output (Iy, Ix) := Input (Iy, Ix) + Long_Float (Ix + Iy);
         end loop;
      end loop;
   end Csub;

   Nrpt : Natural := 100;
   Nx   : Natural := 2000;
   Ny   : Natural := 10;
begin
   if Argument_Count >= 1 then Nrpt := Natural'Value (Argument (1)); end if;
   if Argument_Count >= 2 then Nx := Natural'Value (Argument (2)); end if;
   if Argument_Count >= 3 then Ny := Natural'Value (Argument (3)); end if;
   declare
      Input  : Matrix (0 .. Ny - 1, 0 .. Nx - 1);
      Output : Matrix (0 .. Ny - 1, 0 .. Nx - 1) := (others => (others => 0.0));
   begin
      for Iy in 0 .. Ny - 1 loop
         for Ix in 0 .. Nx - 1 loop
            Input (Iy, Ix) := Long_Float (Nx - Ix + Ny - Iy);
         end loop;
      end loop;
      Put_Line ("Arrays" & Natural'Image (Nx) & " by" & Natural'Image (Ny)
                & " count" & Natural'Image (Nrpt));
      for R in 1 .. Nrpt loop
         Csub (Input, Nx, Ny, Output);
      end loop;
      Check :
      for Iy in 0 .. Ny - 1 loop
         for Ix in 0 .. Nx - 1 loop
            if Output (Iy, Ix) /= Input (Iy, Ix) + Long_Float (Ix + Iy) then
               Put_Line ("Error:" & Natural'Image (Ix) & Natural'Image (Iy));
               exit Check;
            end if;
         end loop;
      end loop Check;
   end;
end Csubraw;
