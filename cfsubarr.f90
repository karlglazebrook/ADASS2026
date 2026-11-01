! cfsubarr.f90 -- Fortran 90 array syntax (2026).
!
! A drop-in replacement for Keith's cfsub.f, linked with his unchanged
! cfmain.f: the subroutine is one whole-array assignment. The index rows are
! array constructors spread across the other dimension, built on every call
! (like numpy "arrays"); gfortran is free to fuse it all into one loop.

subroutine sub (In, Nx, Ny, Out)
   implicit none
   integer, intent(in) :: Nx, Ny
   real, intent(in) :: In(Nx,Ny)
   real, intent(out) :: Out(Nx,Ny)
   integer :: Ix, Iy
   Out = In + spread([(real(Ix), Ix = 1, Nx)], 2, Ny) &
            + spread([(real(Iy), Iy = 1, Ny)], 1, Nx)
end subroutine sub
