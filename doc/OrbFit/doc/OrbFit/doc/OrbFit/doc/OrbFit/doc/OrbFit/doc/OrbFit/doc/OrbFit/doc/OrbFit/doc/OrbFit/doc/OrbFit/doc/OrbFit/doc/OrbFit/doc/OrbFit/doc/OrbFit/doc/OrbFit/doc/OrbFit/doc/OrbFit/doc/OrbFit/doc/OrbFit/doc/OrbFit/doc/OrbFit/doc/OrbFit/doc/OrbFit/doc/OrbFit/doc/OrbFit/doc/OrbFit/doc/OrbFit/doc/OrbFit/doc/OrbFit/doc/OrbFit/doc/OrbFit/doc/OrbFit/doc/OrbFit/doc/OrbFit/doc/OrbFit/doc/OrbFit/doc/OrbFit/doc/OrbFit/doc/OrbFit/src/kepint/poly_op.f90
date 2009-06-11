
! Given the multi-index coefficients of two bivariate polinomials 
! calpha,dbeta of degree amod, bmod respectively, computes the
! degree and coefficients of the polynomial sum.
SUBROUTINE poly_sum(amod,bmod,calpha,dbeta,gmod,egamma)
  USE fund_const, ONLY: dkind
  IMPLICIT NONE
  INTEGER,INTENT(IN) :: amod,bmod ! modulus of the multi-index
  REAL(KIND=dkind),INTENT(IN) :: calpha(0:amod,0:amod)
  REAL(KIND=dkind),INTENT(IN) :: dbeta(0:bmod,0:bmod)
  INTEGER,INTENT(OUT) :: gmod ! modulus of the multi-index
!  REAL(KIND=dkind),INTENT(OUT) :: egamma(0:amod+bmod,0:amod+bmod)
  REAL(KIND=dkind) :: egamma(0:max(amod,bmod),0:max(amod,bmod))
! ==== end interface ======
  ! auxiliary
  REAL(KIND=dkind) :: calpha_aux(0:max(amod,bmod),0:max(amod,bmod))
  REAL(KIND=dkind) :: dbeta_aux(0:max(amod,bmod),0:max(amod,bmod))
  INTEGER :: m,n,h,k   ! loop index
  egamma = 0.q0
  calpha_aux=0.q0
  dbeta_aux=0.q0
  calpha_aux(0:amod,0:amod) =  calpha(0:amod,0:amod)
  dbeta_aux(0:bmod,0:bmod) =  dbeta(0:bmod,0:bmod)
  gmod = max(amod,bmod)
  DO h=0,gmod
     DO k = 0,gmod-h
        egamma(h,k)= calpha_aux(h,k)+dbeta_aux(h,k)
     ENDDO
  ENDDO
END SUBROUTINE poly_sum

SUBROUTINE poly_sum_QP(amod,bmod,calpha,dbeta,gmod,egamma)
  USE fund_const, ONLY: qkind
  IMPLICIT NONE
  INTEGER,INTENT(IN) :: amod,bmod ! modulus of the multi-index
  REAL(KIND=qkind),INTENT(IN) :: calpha(0:amod,0:amod)
  REAL(KIND=qkind),INTENT(IN) :: dbeta(0:bmod,0:bmod)
  INTEGER,INTENT(OUT) :: gmod ! modulus of the multi-index
!  REAL(KIND=qkind),INTENT(OUT) :: egamma(0:amod+bmod,0:amod+bmod)
  REAL(KIND=qkind) :: egamma(0:max(amod,bmod),0:max(amod,bmod))
! ==== end interface ======
  ! auxiliary
  REAL(KIND=qkind) :: calpha_aux(0:max(amod,bmod),0:max(amod,bmod))
  REAL(KIND=qkind) :: dbeta_aux(0:max(amod,bmod),0:max(amod,bmod))
  INTEGER :: m,n,h,k   ! loop index
  egamma = 0.q0
  calpha_aux=0.q0
  dbeta_aux=0.q0
  calpha_aux(0:amod,0:amod) =  calpha(0:amod,0:amod)
  dbeta_aux(0:bmod,0:bmod) =  dbeta(0:bmod,0:bmod)
  gmod = max(amod,bmod)
  DO h=0,gmod
     DO k = 0,gmod-h
        egamma(h,k)= calpha_aux(h,k)+dbeta_aux(h,k)
     ENDDO
  ENDDO
END SUBROUTINE poly_sum_QP


! Given the multi-index coefficients of two bivariate polinomials 
! calpha,dbeta of degree amod, bmod respectively, computes the
! degree and coefficients of the product polynomial according to the
! Cauchy rule
SUBROUTINE poly_product(amod,bmod,calpha,dbeta,gmod,egamma)
  USE fund_const, ONLY: dkind
  IMPLICIT NONE
  INTEGER,INTENT(IN) :: amod,bmod ! modulus of the multi-index
  REAL(KIND=dkind),INTENT(IN) :: calpha(0:amod,0:amod)
  REAL(KIND=dkind),INTENT(IN) :: dbeta(0:bmod,0:bmod)
  INTEGER,INTENT(OUT) :: gmod ! modulus of the multi-index
  REAL(KIND=dkind),INTENT(OUT) :: egamma(0:amod+bmod,0:amod+bmod)
! ==== end interface ======
  INTEGER :: m,n,h,k   ! loop index
  egamma = 0.q0
  gmod = amod+bmod
  DO h=0,amod
     DO k = 0,amod-h
        DO m = 0,bmod
           DO n = 0,bmod-m
              egamma(h+m,k+n)=egamma(h+m,k+n)+calpha(h,k)*dbeta(m,n)
           ENDDO
        ENDDO
     ENDDO
  ENDDO
END SUBROUTINE poly_product

SUBROUTINE poly_product_QP(amod,bmod,calpha,dbeta,gmod,egamma)
  USE fund_const, ONLY: qkind
  IMPLICIT NONE
  INTEGER,INTENT(IN) :: amod,bmod ! modulus of the multi-index
  REAL(KIND=qkind),INTENT(IN) :: calpha(0:amod,0:amod)
  REAL(KIND=qkind),INTENT(IN) :: dbeta(0:bmod,0:bmod)
  INTEGER,INTENT(OUT) :: gmod ! modulus of the multi-index
  REAL(KIND=qkind),INTENT(OUT) :: egamma(0:amod+bmod,0:amod+bmod)
! ==== end interface ======
  INTEGER :: m,n,h,k   ! loop index
  egamma = 0.q0
  gmod = amod+bmod
  DO h=0,amod
     DO k = 0,amod-h
        DO m = 0,bmod
           DO n = 0,bmod-m
              egamma(h+m,k+n)=egamma(h+m,k+n)+calpha(h,k)*dbeta(m,n)
           ENDDO
        ENDDO
     ENDDO
  ENDDO
END SUBROUTINE poly_product_QP
