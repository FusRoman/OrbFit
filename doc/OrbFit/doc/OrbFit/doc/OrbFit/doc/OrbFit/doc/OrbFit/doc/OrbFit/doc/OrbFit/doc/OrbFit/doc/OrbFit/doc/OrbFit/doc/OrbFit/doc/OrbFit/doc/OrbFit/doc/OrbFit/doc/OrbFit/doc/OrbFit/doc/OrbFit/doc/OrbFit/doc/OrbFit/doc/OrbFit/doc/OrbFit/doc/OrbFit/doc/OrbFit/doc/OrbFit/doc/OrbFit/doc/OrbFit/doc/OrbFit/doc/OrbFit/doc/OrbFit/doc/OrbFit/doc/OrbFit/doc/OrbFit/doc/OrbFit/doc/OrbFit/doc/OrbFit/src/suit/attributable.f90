MODULE attributable
USE fund_const
USE name_rules
IMPLICIT NONE
PRIVATE

! new data type: attributable, including covariance and curvature information
TYPE attrib

DOUBLE PRECISION :: tdtobs, tutobs ! average time of observations, MJD, TDT/UT 

DOUBLE PRECISION :: arc, sph ! arc length in time, in angle

CHARACTER*7 :: obscod ! alphanumeric obscode, 500 (geocentric) if nsta >1

INTEGER :: nsta ! number of different observatories, nsta=2 if more than 1

INTEGER :: nobs, ntime, nrad ! number of observations, 
 ! of different times, of radar obs.

DOUBLE PRECISION, DIMENSION(4) :: angles ! alpha, delta, alphadot, deltadot
                         ! unit radians and radians/day

DOUBLE PRECISION :: apm ! apparent magnitude, average; =0 if not available

DOUBLE PRECISION, DIMENSION(4,4) :: g        ! covariance of attributable

LOGICAL lin_fit  ! are we using the linear fit? if false, the quadratic
                 !  fit is being used

DOUBLE PRECISION :: eta, geocurv, etadot ! proper motion, geodetic curvature,
                            ! along track acceleration (all on the celestial
                            ! sphere, units radians and days)

DOUBLE PRECISION :: rms_eta, rms_geocurv, rms_etadot, c_curvacc 
                            ! standard deviations as propagated from g3a, g3d, 
                            ! and correlation of geocurv, etadot


DOUBLE PRECISION rms_a, rms_d, rms_obs ! RMS of residuals, for alpha*cos(delta)
                                       ! for delta, combined

!DOUBLE PRECISION acc_corr, curv_corr ! topocentric corrections to etadot, geocurv

END TYPE attrib
DOUBLE PRECISION, DIMENSION(4), PARAMETER :: zero_4d_vect = &
&    (/ 0.d0, 0.d0, 0.d0, 0.d0 /)
DOUBLE PRECISION, DIMENSION(4,4), PARAMETER :: zero_4x4_matrix = &
& RESHAPE((/ 0.d0, 0.d0, 0.d0, 0.d0, 0.d0, 0.d0, &
& 0.d0, 0.d0, 0.d0, 0.d0, 0.d0, 0.d0, 0.d0, 0.d0, 0.d0, 0.d0/),(/ 4, 4 /))
TYPE(attrib), PARAMETER :: undefined_attrib = ATTRIB( &
&  1.d99,1.d99,     & ! no time defined
&   0.d0,0.d0,      & ! no arc defined
&  '       ',       & ! no obscode 
& 1, 0, 0, 0,       & ! integers
& zero_4d_vect,     & ! null angles
&   -9.99d0,        & ! null magnitude
& zero_4x4_matrix,  & ! null covariance
&  .false.,         & ! lin_fit
&  0.d0,0.d0,0.d0,  & ! pr.m curvatures
&  0.d0,0.d0,0.d0,0.d0,  & ! rms
&  0.d0,0.d0,0.d0  & ! rms fit
&     )  !

DOUBLE PRECISION, PARAMETER :: sphdistx=2.d0 ! spherical distance betw first and last, deg

! public entities
PUBLIC attrib, undefined_attrib

PUBLIC attri_comp, wri_attri, spher_dist , rea_attri

PUBLIC sphdistx

CONTAINS
  SUBROUTINE rea_attri(iunatt,iunrat,name0,att,trou,eof)
    TYPE(attrib), INTENT(OUT) :: att
    CHARACTER*(name_len), INTENT(OUT) :: name0 
    DOUBLE PRECISION, INTENT(OUT) :: trou ! rounded time
    LOGICAL, INTENT(OUT) :: eof
    INTEGER, INTENT(IN) :: iunatt,iunrat ! units for attributable,
                                       ! for curvature info
    DOUBLE PRECISION sec1,sec2
    INTEGER mjd1,mjd2
    DOUBLE PRECISION atrou,dtrou,sa,sd,sadot,sddot,caad,cddd,eta
    CHARACTER*(name_len) name1
    CHARACTER*256 record
    INTEGER yearm
    DOUBLE PRECISION arc2,ds2,curv,accel,curv_unc,acc_unc,eta_unc
! read att file
    READ(iunatt,100,END=2)att%tdtobs,att%angles,trou,atrou,dtrou, &
&        att%nobs,att%arc,name0,att%obscod,    &
&        sa,sd,sadot,sddot,caad,cddd,att%eta,att%apm
100 FORMAT(f13.6,1x,f10.7,1x,f10.7,1p,1x,d12.5,1x,d12.5,1x,0p,      &
     &      f9.2,1x,f8.5,1x,f8.5,1x,i3,1x,f8.2,1x,a9,1x,a3,             &
     &      1p,6(1x,d10.3),0p,1x,f9.4,1x,f5.2)
! compose covariance matrix
       att%g=0.d0
       att%g(1,1)=sa**2
       att%g(2,2)=sd**2
       att%g(3,3)=sadot**2
       att%g(4,4)=sddot**2
       att%g(1,3)=caad*(sa*sadot)
       att%g(3,1)=att%g(1,3)
       att%g(2,4)=cddd*(sd*sddot)
       att%g(4,2)=att%g(2,4)
! find UT of observation
       mjd1=FLOOR(att%tdtobs)
       sec1=att%tdtobs-mjd1
       CALL cnvtim(mjd1,sec1,'TDT',mjd2,sec2,'UTC')
       att%tutobs=mjd2+sec2/86400.d0
! read .rat file
       READ(iunrat,'(A)', END=3)record
       READ(record,101)name1,att%nobs,att%arc,yearm,att%nrad,att%nsta, &
      & att%sph,eta,eta_unc
101    FORMAT(a9,1x,i4,1x,f10.4,1x,i4,1x,i2,1x,i1,3(1x,f12.7))
! 9+1+4+1+10+1+4+1+2+1+1+3*13 = 35+39 = 74 
! name1 = a9
! nobs = i4
! arc = f10.4 
! yearm = i4
! nrad = i2
! nsta = i1
! sph,eta,eta_unc = f12.7
       READ(record(76:173),*)curv,accel,curv_unc,acc_unc, &
      & att%rms_obs,att%rms_a,att%rms_d,att%c_curvacc
! 74 + 4*13+3*13+1+7 = 173
! curv,accel,curv_unc,acc_unc = d12.5
! rms_obs,rms_a,rms_d = d12.5
! c_curvacc = f7.4

! *************** WRONG ***************************************************
!       READ(record,101)name1,att%nobs,att%arc,yearm,att%nrad,att%nsta, &
!      & att%sph,eta,eta_unc, &
!      & att%rms_obs,att%rms_a,att%rms_d,att%c_curvacc
!101    FORMAT(a9,1x,i4,1x,f10.4,1x,i4,1x,i2,1x,i1,3(1x,f12.7),       &
! &      40x,3(1x,f12.7),1x,f7.4)
!       READ(record(74:172),*)curv,accel,curv_unc,acc_unc
! **************************************************************************

    att%sph=att%sph/degrad
    IF(abs(eta-att%eta).gt.1.d-4.or.name0.ne.name1)THEN
       WRITE(*,*)' rea_attri: inconsistency ',name0,' ',name1,att%eta, eta
    ENDIF
    att%ntime=att%nobs  ! guess 
    att%eta=att%eta/degrad
    arc2=(att%arc/2.d0)**2
    ds2=(att%arc*att%eta/2.d0)**2 
    att%geocurv=curv/(ds2*degrad)
    att%etadot= accel/(arc2*degrad)
    att%rms_geocurv=curv_unc/(ds2*degrad)
    att%rms_etadot=acc_unc/(arc2*degrad)
    att%rms_eta=eta_unc/degrad
    eof=.false.          
    RETURN
2   WRITE(*,*)' rea_attri: end of file .att'
    eof=.true.
    RETURN
3   WRITE(*,*)' rea_attri: end of file .rat'
    eof=.true.
  END SUBROUTINE rea_attri

  SUBROUTINE wri_attri(iunatt,iunrat,name0,att,trou,nvir)
    TYPE(attrib), INTENT(IN) :: att
    CHARACTER*(name_len), INTENT(IN) :: name0 
    DOUBLE PRECISION, INTENT(IN) :: trou ! rounded time
    INTEGER, INTENT(IN) :: iunatt,iunrat ! units for attributable,
                                       ! for curvature info
    INTEGER, INTENT(IN), OPTIONAL :: nvir
    DOUBLE PRECISION atrou,dtrou, princ,sa,sd,sadot,sddot,caad,cddd
    INTEGER iday,month,yearm 
    DOUBLE PRECISION hour,arc2,ds2,curv,accel,curv_unc,acc_unc,eta_unc
! write .att file
    IF(iunatt.ge.0)THEN
       IF(iunatt.eq.0)  WRITE(iunatt,201)
201 FORMAT(' t(MJD)  R.A.  DEC. radot  decdot tround rarou decrou nobs arc(d) '&
 &  ,' name  obscod  s(ra) s(dec) s(rad) s(decd) c(aad) c(ddd) pr.m(deg) appmag')
       atrou=att%angles(1)+(trou-att%tdtobs)*att%angles(3)
       atrou=princ(atrou)
       dtrou=att%angles(2)+(trou-att%tdtobs)*att%angles(4)
       sa=sqrt(att%g(1,1))
       sd=sqrt(att%g(2,2))
       sadot=sqrt(att%g(3,3))
       sddot=sqrt(att%g(4,4))
       caad=att%g(1,3)/(sa*sadot)
       cddd=att%g(2,4)/(sd*sddot)
       IF(PRESENT(nvir))THEN
          WRITE(iunatt,300)att%tdtobs,att%angles,trou,atrou,dtrou,   &
     &        att%nobs,att%arc,name0,att%obscod,nvir,                &
     &        sa,sd,sadot,sddot,caad,cddd,att%eta*degrad,att%apm
300       FORMAT(f13.6,1x,f10.7,1x,f10.7,1p,1x,d12.5,1x,d12.5,1x,0p, &
     &      f9.2,1x,f8.5,1x,f8.5,1x,i3,1x,f8.2,1x,a9,1x,a3,1x,i5,    &
     &      1p,6(1x,d10.3),0p,1x,f9.4,1x,f5.2)
       ELSE
          WRITE(iunatt,100)att%tdtobs,att%angles,trou,atrou,dtrou,   &
     &        att%nobs,att%arc,name0,att%obscod,                     &
     &        sa,sd,sadot,sddot,caad,cddd,att%eta*degrad,att%apm
100       FORMAT(f13.6,1x,f10.7,1x,f10.7,1p,1x,d12.5,1x,d12.5,1x,0p,      &
     &      f9.2,1x,f8.5,1x,f8.5,1x,i3,1x,f8.2,1x,a9,1x,a3,          &
     &      1p,6(1x,d10.3),0p,1x,f9.4,1x,f5.2)
       ENDIF
    ENDIF
! write .rat file header
    IF(iunrat.lt.0)RETURN
    IF(iunrat.eq.0)WRITE(iunrat,200)
200 FORMAT('  name    nobs  arctime year nr st   arcang     pr.m     pmunc   ', &
  & '  geocurv    accel     gcunc    accunc     RMS      RMS(a)    RMS(d)', &
  & ' cor-g-a') 
    CALL mjddat(att%tdtobs,iday,month,yearm,hour) 
! output               
    arc2=(att%arc/2.d0)**2
    ds2=(att%arc*att%eta/2.d0)**2                     
    curv=att%geocurv*ds2*degrad
    accel=att%etadot*arc2*degrad
    curv_unc=att%rms_geocurv*ds2*degrad
    acc_unc=att%rms_etadot*arc2*degrad
    eta_unc=att%rms_eta*degrad
    IF(abs(curv).gt.999.d0.or.abs(accel).gt.999.d0.or.abs(att%rms_obs) &
&    .gt.999.d0.or.abs(att%rms_a).gt.999.d0.or.abs(att%rms_d).gt.999.d0)THEN
       WRITE(iunrat,101)name0,att%nobs,att%arc,yearm,att%nrad,att%nsta,   &
      & att%sph*degrad,att%eta*degrad,eta_unc,                            &
      & curv,accel,curv_unc,acc_unc,att%rms_obs,att%rms_a,att%rms_d,      &
      & att%c_curvacc,att%tdtobs
101    FORMAT(a9,1x,i4,1x,f10.4,1x,i4,1x,i2,1x,i1,3(1x,f12.7),       &
 &    1p,4(1x,d12.5),0p,3(1x,d12.5),1x,f7.4,1x,f13.6)
    ELSE
       WRITE(iunrat,102)name0,att%nobs,att%arc,yearm,att%nrad,att%nsta,   &
      & att%sph*degrad,att%eta*degrad,eta_unc,                            &
      & curv,accel,curv_unc,acc_unc,att%rms_obs,att%rms_a,att%rms_d,      &
      & att%c_curvacc,att%tdtobs
102    FORMAT(a9,1x,i4,1x,f10.4,1x,i4,1x,i2,1x,i1,3(1x,f12.7),       &
 &    4(1x,f12.7),3(1x,f12.7),1x,f7.4,1x,f13.6)
    ENDIF
  END SUBROUTINE wri_attri

  SUBROUTINE attri_comp(m,obs,obsw,att,error)
  USE astrometric_observations
!INPUT:  observations
  INTEGER,INTENT(IN) :: m ! number of observations 
  TYPE(ast_obs),INTENT(IN),DIMENSION(m) :: obs ! observations 
  TYPE(ast_wbsr),INTENT(IN),DIMENSION(m) :: obsw ! observation weights 
! OUTPUT: attributable
  TYPE(attrib), INTENT(OUT) :: att 
  LOGICAL, INTENT(OUT), OPTIONAL :: error ! error flag, to avoid stop
! END INTERFACE
  DOUBLE PRECISION :: tc ! central time
  INCLUDE 'parobx.h90'
  DOUBLE PRECISION, DIMENSION(nobx) :: t, alpha, delta, rmsa,rmsd, &
    &    alcosd,rmsad,alr
  DOUBLE PRECISION, DIMENSION(2,2) :: g2a, g2d ! covariance of linear fit 
  DOUBLE PRECISION, DIMENSION(3,3) :: g3a, g3d ! covariance of quadratic fit
! RMS of residuals: linear fit, quadr. fit
  DOUBLE PRECISION :: rms_2a, rms_3a, rms_2d, rms_3d 
  DOUBLE PRECISION :: s2d(2),s2a(2), s3d(3), s3a(3), cosdtc, sindtc, princ
  DOUBLE PRECISION detadv(2), tmp2(2), arc, gked(2,2)
  DOUBLE PRECISION :: sw,swx,ww
  INTEGER ng, ntime ! no rev for unwrapping of alpha, no of distinct times
  INTEGER j, ising,nmag
  CHARACTER*7 idst1
! ================================
  error=.false.
  alpha(1:m)=obs%coord(1)
! unwrap of alpha                                                  
  alr(1)=alpha(1) 
  ng=0 
  DO j=2,m 
     IF(alpha(j).lt.alpha(j-1)-pig)THEN 
        ng=ng+1 
     ELSEIF(alpha(j).gt.alpha(j-1)+pig)THEN 
        ng=ng-1 
     ENDIF
     alr(j)=alpha(j)+ng*dpig 
  ENDDO
  delta(1:m)=obs%coord(2)
  rmsa(1:m)=abs(obsw%rms_coord(1))
  rmsd(1:m)=abs(obsw%rms_coord(2))
! observation times
  t(1:m)=obs%time_tdt
  arc=MAXVAL(t(1:m))-MINVAL(t(1:m))
! total weight (for both coordinates, using area of ellipse) and central time
  sw=0.d0
  swx=0.d0
  DO j=1,m
     ww=1/(rmsa(j)*rmsd(j)*cos(delta(j)))
     swx=swx+t(j)*ww
     sw=sw+ww
  ENDDO
! central time is weighed mean
  tc=swx/sw
! shift origin of time to tc
  t(1:m)=t(1:m)-tc 
! count distinct times 
  ntime=1
  DO j=2,m
     IF(t(j)-t(j-1).gt.100*epsilon(1.d0))ntime=ntime+1
  ENDDO
  IF(ntime.eq.1)THEN
    WRITE(*,*)' attri_comp: what do you want with one observation?' 
    WRITE(*,*) obs%time_tdt
    error=.true.
    RETURN
  ENDIF 
  att%nrad=0
  DO j=1,m 
     IF(obs(j)%type.eq.'R'.or.obs(j)%type.eq.'V')att%nrad=att%nrad+1 
  ENDDO
! test for mixed station attributables                                  
  idst1=obs(1)%obscod_s 
  att%nobs=m
  att%nsta=1 
  DO j=2,att%nobs
     IF(obs(j)%obscod_s.ne.idst1)att%nsta=2 
  ENDDO
! use no topocentric correction if there are two (or more) stations
  IF(att%nsta.eq.1)THEN
     att%obscod=idst1
  ELSE
     att%obscod='500'
  ENDIF
! fit to delta  
  CALL quadratic_fit(t,delta,rmsd,m,ntime,g2d,g3d,s2d,s3d,   &
&           rms_2d,rms_3d,ising)
! decision on which fit to use  
  IF(ntime.eq.2)THEN
     cosdtc=cos(s2d(2))
     sindtc=sin(s2d(2))
  ELSE
     cosdtc=cos(s3d(3))
     sindtc=sin(s3d(3))
  ENDIF
!  alcosd(1:m)=alr(1:m)*cosdtc
!  rmsad(1:m)=rmsa(1:m)*cosdtc
! fit to alpha*cos(delta*)
  CALL quadratic_fit(t,alr,rmsa,m,ntime,g2a,g3a,s2a,s3a,   &
&           rms_2a,rms_3a,ising)
! output attributable
  att%tdtobs=tc ! central time in TDT
  att%arc=arc
  att%nobs=m
  att%ntime=ntime
  att%tutobs=SUM(obs%time_utc)/m ! central time in TUT (WRONG!!!)
  att%sph=spher_dist(obs(1)%coord,obs(m)%coord)
  IF(att%sph.le.sphdistx*radeg)      &
&         att%sph= max_sphdist(obs(1:m)%coord(1),obs(1:m)%coord(2),m)
  IF(att%sph.le.1000*epsilon(1.d0))THEN
    WRITE(*,*)' attri_comp: what do you want with a fixed star?' 
    WRITE(*,*) att%sph
    error=.true.
    RETURN
  ENDIF 
! compute average apparent magnitude
  nmag=0
  att%apm=0.d0
  DO j=1,m
     IF(obs(j)%mag_def)THEN
        att%apm=att%apm+obs(j)%mag
        nmag=nmag+1
     ENDIF
  ENDDO
  IF(nmag.ne.0)att%apm=att%apm/nmag
! angles and covariance
  IF(ntime.eq.2)THEN
     att%lin_fit=.true.
     att%angles(1)=princ(s2a(2))
     att%angles(2)=s2d(2)
     att%angles(3)=s2a(1)
     att%angles(4)=s2d(1)
     att%g=0.d0
     att%g(1,1)=g2a(2,2)
     att%g(3,3)=g2a(1,1)
     att%g(1,3)=g2a(2,1)
     att%g(3,1)=g2a(1,2)
     att%g(2,2)=g2d(2,2)
     att%g(4,4)=g2d(1,1)
     att%g(2,4)=g2d(2,1)
     att%g(4,2)=g2d(1,2)
     att%rms_a=rms_2a ! this includes cos(delta)
     att%rms_d=rms_2d
     att%rms_obs=sqrt(rms_2a**2+rms_2d**2)
  ELSE
     att%lin_fit=.false.
     att%angles(1)=princ(s3a(3))
     att%angles(2)=s3d(3)
     att%angles(3)=s3a(2)
     att%angles(4)=s3d(2)
     att%g=0.d0
     att%g(1,1)=g3a(3,3)
     att%g(3,3)=g3a(2,2)
     att%g(1,3)=g3a(3,2)
     att%g(3,1)=g3a(2,3)
     att%g(2,2)=g3d(3,3)
     att%g(4,4)=g3d(2,2)
     att%g(2,4)=g3d(3,2)
     att%g(4,2)=g3d(2,3)
     att%rms_a=rms_3a ! this includes cos(delta)
     att%rms_d=rms_3d
     att%rms_obs=sqrt(rms_3a**2+rms_3d**2)
  ENDIF
! proper motion and its variance
  att%eta=sqrt(att%angles(4)**2+att%angles(3)**2*cosdtc**2)
  detadv(1)=att%angles(3)*cosdtc**2/att%eta
  detadv(2)=att%angles(4)/att%eta
! neglecting the contribution from uncert. of delta
  tmp2=MATMUL(att%g(3:4,3:4),detadv)
  att%rms_eta=sqrt(DOT_PRODUCT(detadv,tmp2))
  IF(ntime.eq.2)THEN
     att%geocurv=0.d0
     att%etadot=0.d0
     att%rms_geocurv=0.d0 !wrong, but please use lin_fit
     att%rms_etadot=0.d0  ! idem
     att%c_curvacc=0.d0
  ELSE
     att%geocurv=(s3d(1)*att%angles(3)-s3a(1)*att%angles(4))*cosdtc/att%eta**3
     att%geocurv=att%geocurv + att%angles(3)*sindtc*(att%eta**2+   &
  &     att%angles(4)**2)/att%eta**3
     att%etadot=(att%angles(3)*s3a(1)*cosdtc**2+ att%angles(4)*s3d(1))/att%eta
     att%etadot=att%etadot -(att%angles(3)**2*sindtc*cosdtc*att%angles(4)) &
  &     /att%eta
! covariance of geodetic curvature, acceleration
     CALL covar_curvacc(att%eta,att%angles(1),att%angles(2),att%angles(3), &
 &       att%angles(4),s3a(1),s3d(1),g3a,g3d,gked)
     att%rms_geocurv=sqrt(gked(1,1)) 
     att%rms_etadot=sqrt(gked(2,2))  
     att%c_curvacc=gked(1,2)/(att%rms_geocurv*att%rms_etadot)
! compute Vhat, Nhat

! compute for each obs a(t)=Pobs*Nhat, b(t)=Pobs*Vhat
! quadratic fit of a(t), b(t)
! curv_corr=\ddot a
! acc_corr=\ddot b
  ENDIF
  END SUBROUTINE attri_comp

  SUBROUTINE quadratic_fit(x,y,sy,m,ntime,g2,g3,s2,s3,rms_2,rms_3,ising)
!INPUT:
    INTEGER,INTENT(IN) :: m, ntime ! number of data, 
            ! separate observation times
    DOUBLE PRECISION, INTENT(IN) :: x(m),y(m),sy(m) ! fit done
        ! on y, with RMS sy, as polynomial in x
!OUTPUT
    DOUBLE PRECISION, INTENT(OUT), DIMENSION(2) :: s2  ! linear sol.
    DOUBLE PRECISION, INTENT(OUT), DIMENSION(3) :: s3  ! quadratic sol.
! covariance matrices
    DOUBLE PRECISION, INTENT(OUT) :: g2(2,2), g3(3,3) !of linear, quadratic fit
    DOUBLE PRECISION, INTENT(OUT) :: rms_2, rms_3 ! RMS of linear/quadr fit
    INTEGER, INTENT(OUT) :: ising ! row of degeneracy
!END INTERFACE
    DOUBLE PRECISION :: sw,swx,swx2,swxy,swy,sr,ww,detc, d2(2) 
            !sums, weight, determinant, right hand side
    DOUBLE PRECISION :: c2(2,2), c3(3,3) ! normal matr. of lin/quadr fit
    DOUBLE PRECISION :: aa(3,4),det,swx4,swx3,swx2y,tmp 
            ! linear system for degree 2
    INTEGER j
! total weight and central time
    sw=0.d0
    swx=0.d0
! normal matrix and right hand side
    swx2=0.d0
    swxy=0.d0
    swy=0.d0 
! for curvature
    swx3=0.d0
    swx4=0.d0
    swx2y=0.d0
    DO j=1,m
       ww=1/sy(j)**2
       sw=sw+ww
       swx=swx+x(j)*ww
       swx2=swx2+x(j)**2*ww
       swy=swy+y(j)*ww
       swxy=swxy+x(j)*y(j)*ww
! for curvature
       swx3=swx3+x(j)**3*ww
       swx4=swx4+x(j)**4*ww
       swx2y=swx2y+x(j)**2*y(j)*ww      
    ENDDO
!    IF(abs(swx).gt.100*epsilon(1.d0))WRITE(*,*)' central time trouble ',swx
! normal matrix for linear fit
    c2(1,1)=swx2
    c2(1,2)=swx
    c2(2,1)=swx
    c2(2,2)=sw
    d2(1)=swxy !right hand side for linear fit
    d2(2)=swy
    detc=c2(1,1)*c2(2,2)-c2(1,2)*c2(2,1)
    IF(abs(detc).lt.epsilon(detc)*c2(1,1)*100)THEN
       WRITE(*,*)' lin_reg: var(x) too small', detc,c2
    ENDIF
    g2(1,1)=c2(2,2)/detc ! covariance matrix for linear fit 
    g2(2,2)=c2(1,1)/detc
    g2(2,1)=-c2(2,1)/detc
    g2(1,2)=-c2(1,2)/detc
! solution
    s2=MATMUL(g2,d2)
! rms of residuals
    sr=0.d0
    DO j=1,m
       ww=1/sy(j)**2
       sr=sr+ww*(y(j)-s2(1)*x(j)-s2(2))**2
    ENDDO
    rms_2=sqrt(sr/m)
! check if quadratic fit is possible
    IF(m.gt.2.and.ntime.gt.2)THEN
       aa(1,1)=swx4
       aa(1,2)=swx3
       aa(2,1)=swx3
       aa(2,2)=swx2
       aa(3,1)=swx2
       aa(1,3)=swx2
       aa(3,2)=swx
       aa(2,3)=swx
       aa(3,3)=sw
       aa(1,4)=swx2y
       aa(2,4)=swxy
       aa(3,4)=swy
       c3=aa(1:3,1:3)
       CALL matin(aa,det,3,1,3,ising,1)
       g3=aa(1:3,1:3)
       s3=aa(1:3,4)
! post fit residuals
        sr=0.
        DO j=1,m
           ww=1/sy(j)**2
           tmp=ww*(y(j)-s3(1)*x(j)**2-s3(2)*x(j)-s3(3))**2
!              write(*,*)j,tmp
           sr=sr+tmp
        ENDDO
        rms_3=sqrt(sr/m)
    ENDIF
  END SUBROUTINE quadratic_fit

! covariance of geodetic curvature and acceleration
  SUBROUTINE covar_curvacc(eta,a,d,da,dd,dda,ddd,g3a,g3d,gked)
    DOUBLE PRECISION, INTENT(IN) :: eta,a,d,da,dd,dda,ddd
    DOUBLE PRECISION, DIMENSION(3,3), INTENT(IN) :: g3a,g3d
    DOUBLE PRECISION, INTENT(OUT) :: gked(2,2)
    DOUBLE PRECISION tmp23(2,3),dked(2,3)
    DOUBLE PRECISION t1,t2,t3,t4,t5,t6,t7,t8,t9,t10,t11,t12,t13,t14,t15
! partials of k w.r. delta and derivatives
!    dked(1,1:3)=\partial k /\partial (\"\delta, \ddot, \delta)
    dked(1,3) = 3.D0*(ddd*da-dda*dd)/sqrt(da**2*cos(d)**2.D0+dd**2)**5.D0* &
& cos(d)**2.D0*da**2*sin(d)-(ddd*da-dda*dd)/sqrt(da**2*cos(d)**2.D0+ &
& dd**2)**3.D0*sin(d)+da*cos(d)/sqrt(da**2*cos(d)**2.D0+dd**2)**3.D0 &
& *(da**2*cos(d)**2.D0+2.D0*dd**2)+3.D0*da**3*sin(d)**2.D0/ &
& sqrt(da**2*cos(d)**2.D0+dd**2)**5.D0*(da**2*cos(d)**2.D0+ &
& 2.D0*dd**2)*cos(d)-2.D0*da**3*sin(d)**2.D0/sqrt(da**2*cos(d)**2.D0+ &
& dd**2)**3.D0*cos(d)
    dked(1,2) = -dda/sqrt(da**2*cos(d)**2.D0+dd**2)**3.D0*cos(d)- &
& 3.D0*(ddd*da-dda*dd)/sqrt(da**2*cos(d)**2.D0+dd**2)**5.D0* &
& cos(d)*dd-3.D0*da*sin(d)/sqrt(da**2*cos(d)**2.D0+ &
& dd**2)**5.D0*(da**2*cos(d)**2.D0+2.D0*dd**2)*dd+ &
& 4.D0*da*sin(d)/sqrt(da**2*cos(d)**2.D0+dd**2)**3.D0*dd
    dked(1,1) =  da/sqrt(da**2*cos(d)**2.D0+dd**2)**3.D0*cos(d)
! partials of etadot w.r. to delta and derivatives
    dked(2,3) =  1.D0/sqrt(da**2*cos(d)**2.D0+dd**2)**3.D0* &
& (da*dda*cos(d)**2.D0+dd*ddd-da**2*cos(d)*sin(d)*dd)* &
& da**2*cos(d)*sin(d)+1.D0/sqrt(da**2*cos(d)**2.D0+ &
& dd**2)*(-2.D0*da*dda*cos(d)*sin(d)+da**2*sin(d)**2.D0*dd- &
& da**2*cos(d)**2.D0*dd)
    dked(2,2) = -1.D0/sqrt(da**2*cos(d)**2.D0+dd**2)**3.D0* &
& (da*dda*cos(d)**2.D0+dd*ddd-da**2*cos(d)*sin(d)*dd)*dd+ &
& 1.D0/sqrt(da**2*cos(d)**2.D0+dd**2)*(ddd-da**2*cos(d)*sin(d))
    dked(2,1) = 1.D0/sqrt(da**2*cos(d)**2.D0+dd**2)*dd
    tmp23=MATMUL(dked,g3d)
    gked=MATMUL(tmp23,TRANSPOSE(dked))
! partials of k w.r. to alpha and derivatives
    dked(1,3) = 0.d0
    dked(1,2) = ddd/sqrt(da**2*cos(d)**2.D0+dd**2)**3.D0*cos(d)- &
& 3.D0*(ddd*da-dda*dd)/sqrt(da**2*cos(d)**2.D0+dd**2)**5.D0 &
& *cos(d)**3.D0*da+sin(d)/sqrt(da**2*cos(d)**2.D0+ &
& dd**2)**3.D0*(da**2*cos(d)**2.D0+2.D0*dd**2)- &
& 3.D0*da**2*sin(d)/sqrt(da**2*cos(d)**2.D0+dd**2)**5.D0* &
& (da**2*cos(d)**2.D0+2.D0*dd**2)*cos(d)**2.D0+ &
& 2.D0*da**2*sin(d)/sqrt(da**2*cos(d)**2.D0+dd**2)**3.D0*cos(d)**2.D0
    dked(1,1) = -dd/sqrt(da**2*cos(d)**2.D0+dd**2)**3.D0*cos(d)
! partials of etadot w.r. to alpha and derivatives
    dked(2,3) =  0.d0
    dked(2,2) = -1.D0/sqrt(da**2*cos(d)**2.D0+dd**2)**3.D0* &
& (da*dda*cos(d)**2.D0+dd*ddd-da**2*cos(d)*sin(d)*dd)* &
& da*cos(d)**2.D0+1.D0/sqrt(da**2*cos(d)**2.D0+ &
& dd**2)*(dda*cos(d)**2.D0-2.D0*da*cos(d)*sin(d)*dd)
    dked(2,1) = 1.D0/sqrt(da**2*cos(d)**2.D0+dd**2)*da*cos(d)**2.D0
    tmp23=MATMUL(dked,g3a)
    gked=gked+MATMUL(tmp23,TRANSPOSE(dked))
  END SUBROUTINE covar_curvacc

! max spherical distance for a set of observations
  DOUBLE PRECISION FUNCTION max_sphdist(alpha,delta,m)
    INTEGER, INTENT(IN) :: m ! nummber of obs
! array of alpha, delta
    DOUBLE PRECISION, DIMENSION(m), INTENT(IN) :: alpha,delta 
    INTEGER i,j
    DOUBLE PRECISION mx, oi(2), oj(2)
    mx=0.d0
    DO i=1,m-1
       oi(1)=alpha(i)
       oi(2)=delta(i)
       DO j=i+1,m
          oj(1)=alpha(j)
          oj(2)=delta(j)
          mx=MAX(mx,spher_dist(oi,oj))
       ENDDO
    ENDDO
    max_sphdist=mx
  END FUNCTION max_sphdist
! spherical distance between two observations
  DOUBLE PRECISION FUNCTION spher_dist(obs1,obs2)
    DOUBLE PRECISION, INTENT(IN), DIMENSION(2) :: obs1,obs2
    DOUBLE PRECISION :: alpha1,delta1,alpha2,delta2
    DOUBLE PRECISION x1(3), x2(3),prscal,pp
! unit vectors
    alpha1=obs1(1)
    delta1=obs1(2)
    x1(1)=cos(delta1)*cos(alpha1)
    x1(2)=cos(delta1)*sin(alpha1) 
    x1(3)=sin(delta1)
    alpha2=obs2(1)
    delta2=obs2(2)
    x2(1)=cos(delta2)*cos(alpha2)
    x2(2)=cos(delta2)*sin(alpha2) 
    x2(3)=sin(delta2)
! cosine as scalar product
    pp=prscal(x1,x2)
    IF(abs(pp).gt.1.d0-100*epsilon(1.d0))THEN
       spher_dist=0.d0
    ELSE
       spher_dist=acos(pp)
    ENDIF
END FUNCTION spher_dist

END MODULE attributable
