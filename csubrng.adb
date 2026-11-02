--  csubrng.adb -- Ada port, as csubraw.adb but the kernel loops over the
--  array's own index ranges (Output'Range (1), Output'Range (2)), which is the
--  Ada idiom and lets GNAT prove the index checks away without -gnatp.
--  The index sum is Long_Float (Ix) + Long_Float (Iy), so there is no
--  overflow-checked integer add in the loop either. Element loop, Long_Float.
--     gnatmake -O3 csubrng.adb -o csubrng && ./csubrng 1000 2000 10
with Ada.Command_Line; use Ada.Command_Line;
with Ada.Text_IO;      use Ada.Text_IO;

procedure Csubrng is
   type Matrix is array (Natural range <>, Natural range <>) of Long_Float;

   procedure Csub (Input : Matrix; Output : in out Matrix) is
   begin
      for Iy in Output'Range (1) loop
         for Ix in Output'Range (2) loop
            Output (Iy, Ix) := Input (Iy, Ix) + (Long_Float (Ix) + Long_Float (Iy));
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
      for Iy in Input'Range (1) loop
         for Ix in Input'Range (2) loop
            Input (Iy, Ix) := Long_Float (Nx - Ix + Ny - Iy);
         end loop;
      end loop;
      Put_Line ("Arrays" & Natural'Image (Nx) & " by" & Natural'Image (Ny)
                & " count" & Natural'Image (Nrpt));
      for R in 1 .. Nrpt loop
         Csub (Input, Output);
      end loop;
      Check :
      for Iy in Output'Range (1) loop
         for Ix in Output'Range (2) loop
            if Output (Iy, Ix) /= Input (Iy, Ix) + Long_Float (Ix + Iy) then
               Put_Line ("Error:" & Natural'Image (Ix) & Natural'Image (Iy));
               exit Check;
            end if;
         end loop;
      end loop Check;
   end;
end Csubrng;
