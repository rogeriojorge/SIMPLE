module field_can_mod

implicit none
save

type :: field_can
    double precision :: Ath, Aph
    double precision :: hth, hph
    double precision :: Bmod
end type field_can

type :: d_field_can
    double precision, dimension(3) :: dAth, dAph
    double precision, dimension(3) :: dhth, dhph
    double precision, dimension(3) :: dBmod
end type d_field_can

! second derivatives: drdr, drdt, drdp, dtdt, dtdp, dpdp
type :: d2_field_can 
    double precision, dimension(6) :: d2Ath, d2Aph  
    double precision, dimension(6) :: d2hth, d2hph  
    double precision, dimension(6) :: d2Bmod
end type d2_field_can

type(field_can) :: f
type(d_field_can) :: df
type(d2_field_can) :: d2f

double precision :: H, pth, vpar
double precision, dimension(4) :: dvpar, dH, dpth
double precision, dimension(10) :: d2vpar, d2H, d2pth
! order of second derivatives: 
! d2dr2, d2drdth, d2drph, d2dth2, d2dthdph, d2dph2,
! d2dpphdr, d2dpphdth, d2dpphdph, d2dpph2

double precision :: mu, ro0

integer :: neval = 0

integer, parameter :: nbuf = 32
integer :: kbuf = 1
double precision :: xbuf(3, nbuf) = 1e30
type(field_can) :: fbuf(nbuf)
type(d_field_can) :: dfbuf(nbuf)
type(d2_field_can) :: d2fbuf(nbuf)


interface eval_field
  module procedure eval_field_can
end interface

contains

!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!
subroutine get_val(pphi)
!
! computes values of H, pth and vpar at z=(r, th, ph, pphi)
!
!
  double precision, intent(in) :: pphi

  vpar = (pphi - f%Aph/ro0)/f%hph
  H = vpar**2/2d0 + mu*f%Bmod
  pth = f%hth*vpar + f%Ath/ro0
  
end subroutine get_val

    
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!
subroutine get_derivatives(pphi)
!
! computes H, pth and vpar at z=(r, th, ph, pphi) and their derivatives  
!
!
  double precision, intent(in) :: pphi

  call get_val(pphi)

  dvpar(1:3) = -(df%dAph/ro0 + df%dhph*vpar)
  dvpar(4)   = 1d0/f%hph

  dH(1:3) = vpar*dvpar(1:3) + mu*df%dBmod
  dH(4)   = vpar/f%hph
  
  dpth(1:3) = ((pphi-f%Aph/ro0)*df%dhth - df%dAph/ro0*f%hth            &
               -(pth-f%Ath/ro0)*df%dhph + df%dAth/ro0*f%hph)/f%hph
  dpth(4) = f%hth/f%hph

end subroutine get_derivatives

!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!
subroutine get_derivatives2(pphi)
!
! computes H, pth and vpar at z=(r, th, ph, pphi) up to 2nd derivatives 
! order of second derivatives: 
! d2dr2, d2drdth, d2drph, d2dth2, d2dthdph, d2dph2,
! d2dpphdr, d2dpphdth, d2dpphdph, d2dpph2
!
  double precision, intent(in) :: pphi

  call get_derivatives(pphi)

  d2vpar = 0d0
  d2H    = 0d0
  d2pth  = 0d0

end subroutine get_derivatives2

    
!ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
!
subroutine eval_field_can(r, th_c, ph_c, mode_secders)
!
  implicit none

  double precision, intent(in) :: r, th_c, ph_c     
  integer, intent(in) :: mode_secders

  double precision :: Bctr_vartheta, Bctr_varphi, bmod2, sqg, dsqg(3), d2sqg(6), d3Aphdr3, dummy, &
    Bth, Bph, dBth(3), dBph(3), d2Bth(6), d2Bph(6)

  integer :: kb, bufind

  do kb = 0, nbuf
    bufind = kbuf-kb
    if (bufind<1) bufind = bufind + nbuf
    if (r == xbuf(1,bufind) .and. th_c == xbuf(2,bufind) .and. ph_c == xbuf(3,bufind)) then
        ! exact match
        f = fbuf(bufind)
        df = dfbuf(bufind)
        d2f = d2fbuf(bufind)
        return
        !print *, 'buffer hit ', xbuf(:,bufind)
    end if
  end do

  ! Count evaluations for profiling
  neval = neval + 1

  ! initialize to zero - no angular derivatives will be set due to straight field line Ath(r) Aph(r)
  df%dAth = 0d0
  df%dAph = 0d0
  d2f%d2Ath = 0d0
  d2f%d2Aph = 0d0

  call splint_can_coord(.false., mode_secders, r, th_c, ph_c, &
    f%Ath, f%Aph, df%dAth(1), df%dAph(1), d2f%d2Aph(1), d3Aphdr3, &
    sqg, dsqg(1), dsqg(2), dsqg(3), &
    Bth, dBth(1), dBth(2), dBth(3), &
    Bph, dBph(1), dBph(2), dBph(3), &
    d2sqg(1), d2sqg(2), d2sqg(3), d2sqg(4), d2sqg(5), d2sqg(6), &
    d2Bth(1), d2Bth(2), d2Bth(3), d2Bth(4), d2Bth(5), d2Bth(6), &
    d2Bph(1), d2Bph(2), d2Bph(3), d2Bph(4), d2Bph(5), d2Bph(6), dummy)
 
  Bctr_vartheta = -df%dAph(1)/sqg
  Bctr_varphi = df%dAth(1)/sqg
  
  bmod2 = Bctr_vartheta*Bth + Bctr_varphi*Bph
  f%Bmod = sqrt(bmod2)
  
  df%dBmod(1) = 0.5d0*((df%dAth(1)*dBph(1)-df%dAph(1)*dBth(1)-d2f%d2Aph(1)*Bth)/f%Bmod-dsqg(1)*f%Bmod)/sqg
  df%dBmod(2) = 0.5d0*((df%dAth(1)*dBph(2)-df%dAph(1)*dBth(2))/f%Bmod-dsqg(2)*f%Bmod)/sqg
  df%dBmod(3) = 0.5d0*((df%dAth(1)*dBph(3)-df%dAph(1)*dBth(3))/f%Bmod-dsqg(3)*f%Bmod)/sqg

  f%hth = Bth/f%Bmod
  f%hph = Bph/f%Bmod
  df%dhth = dBth/f%Bmod - Bth*df%dBmod/bmod2
  df%dhph = dBph/f%Bmod - Bph*df%dBmod/bmod2

  if (nbuf>0) then
    xbuf(:,kbuf) = (/r,th_c,ph_c/)
    fbuf(kbuf) = f
    dfbuf(kbuf) = df 
    d2fbuf(kbuf) = d2f
    kbuf = mod(kbuf, nbuf) + 1
  end if

end subroutine eval_field_can

! for testing -> circular tokamak
! subroutine eval_field_test(r, th, ph, mode_secders)
! !
!  implicit none

!  double precision, intent(in) :: r, th, ph   
!  integer, intent(in) :: mode_secders        

!  double precision :: B0th, B0ph, cth, sth 

!    ! Count evaluations for profiling
!   neval = neval + 1

!   B0th = .99d0
!   B0ph = sqrt(1d0-B0th**2)

!   cth = cos(th)
!   sth = sin(th)
  
!   f%Ath      = B0ph*(r**2/2d0 - r**3/3d0*cth)
!   df%dAth(1) = B0ph*(r - r**2*cth)
!   df%dAth(2) = B0ph*r**3/3d0*sth
!   df%dAth(3) = 0d0

!   f%Aph     = -B0th*r
!   df%dAph(1) = -B0th
!   df%dAph(2) = 0d0
!   df%dAph(3) = 0d0

!   f%Bth      = B0th*r*(1d0 - r*cth)
!   df%dBth(1) = B0th*(1d0 - 2d0*r*cth)
!   df%dBth(2) = B0th*r**2*sth
!   df%dBth(3) = 0d0
  
!   f%Bph      = B0ph*(1d0 - (r*cth)**2)
!   Bph(1) = -2d0*B0ph*r*cth**2
!   Bph(2) = 2d0*B0ph*r**2*cth*sth
!   Bph(3) = 0d0

!   f%Bmod   = 1d0 - r*cth
!   df%dBmod(1) = -cth
!   df%dBmod(2) = r*sth
!   df%dBmod(3) = 0d0

! !  TODO: second derivatives
!   d2f%d2Ath = 0d0
!   d2f%d2Aph = 0d0
!   d2f%d2Bth = 0d0
!   d2f%d2Bph = 0d0
!   d2f%d2Bmod = 0d0

! end subroutine eval_field_test


end module field_can_mod