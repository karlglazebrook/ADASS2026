! cfsubdc.f90 -- Fortran 2008 do concurrent (2026).
!
! A drop-in replacement for Keith's cfsub.f, linked with his unchanged
! cfmain.f: the same element loop written as one do concurrent construct,
! which promises the compiler the iterations are independent. gfortran runs
! it serially unless asked to parallelise, so this stays single-threaded.

subroutine sub (In, Nx, Ny, Out)
   implicit none
   integer, intent(in) :: Nx, Ny
   real, intent(in) :: In(Nx,Ny)
   real, intent(out) :: Out(Nx,Ny)
   integer :: Ix, Iy
   do concurrent (Iy = 1:Ny, Ix = 1:Nx)
      Out(Ix,Iy) = In(Ix,Iy) + Ix + Iy
   end do
end subroutine sub
