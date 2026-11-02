! cfsubcol.f90 -- Fortran 90 array sections, one column at a time (2026).
!
! A drop-in replacement for Keith's cfsub.f, linked with his unchanged
! cfmain.f. The row-index vector is an array constructor built on every
! call (Nx reals); each column is then one array-section assignment with a
! scalar Iy. Unlike cfsubarr.f90 (spread), no full-size temporaries.

subroutine sub (In, Nx, Ny, Out)
   implicit none
   integer, intent(in) :: Nx, Ny
   real, intent(in) :: In(Nx,Ny)
   real, intent(out) :: Out(Nx,Ny)
   integer :: Ix, Iy
   real :: ixv(Nx)
   ixv = [(real(Ix), Ix = 1, Nx)]
   do Iy = 1, Ny
      Out(:,Iy) = In(:,Iy) + ixv + real(Iy)
   end do
end subroutine sub
