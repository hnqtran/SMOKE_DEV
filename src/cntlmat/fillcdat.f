        SUBROUTINE FILLCDAT( PKTTYP, JT, PKTINFO )

C***********************************************************************
C  subroutine body starts at line
C
C  DESCRIPTION:
C      This subroutine populates the control data table depending on the 
C      packet type being processed when the routine is called (PKTTYP)
C
C  PRECONDITIONS REQUIRED:
C
C  SUBROUTINES AND FUNCTIONS CALLED:
C
C  REVISION  HISTORY:
C      Started 3/99 by M. Houyoux
C
C****************************************************************************/
C
C Project Title: Sparse Matrix Operator Kernel Emissions (SMOKE) Modeling
C                System
C File: @(#)$Id$
C
C COPYRIGHT (C) 1998, MCNC--North Carolina Supercomputing Center
C All Rights Reserved
C
C See file COPYRIGHT for conditions of use.
C
C Environmental Programs Group
C MCNC--North Carolina Supercomputing Center
C P.O. Box 12889
C Research Triangle Park, NC  27709-2889
C
C env_progs@mcnc.org
C
C Pathname: $Source$
C Last updated: $Date$ 
C
C***************************************************************************

C.........  MODULES for public variables
C.........  This module contains the control packet data and control matrices
        USE MODCNTRL

        IMPLICIT NONE
        
C...........   INCLUDES
        INCLUDE 'EMCNST3.EXT'   !  emissions constant parameters
        INCLUDE 'CPKTDAT.EXT'   !  control packet contents        

C...........   EXTERNAL FUNCTIONS:
        INTEGER       STR2INT
        EXTERNAL      STR2INT

C...........   SUBROUTINE ARGUMENTS:

        CHARACTER(*), INTENT (IN) :: PKTTYP    ! packet type 
        INTEGER     , INTENT (IN) :: JT        ! index to control data tables
        TYPE(CPACKET),INTENT (IN) :: PKTINFO   ! packet information

        CHARACTER*16 :: PROGNAME = 'FILLCDAT' ! program name

C***********************************************************************
C   Begin body of subroutine FILLCNTl

        SELECT CASE( PKTTYP )

        CASE( 'CTG' )
            CUTCTG ( JT ) = PKTINFO%FAC1
            FACCTG ( JT ) = PKTINFO%FAC2
            FACMACT( JT ) = PKTINFO%FAC3
            FACRACT( JT ) = PKTINFO%FAC4

        CASE( 'CONTROL' )
            ICTLEQUP( JT ) = INT    ( PKTINFO%FAC1 )
            ICTLSIC ( JT ) = STR2INT( PKTINFO%CSIC )
            FACCEFF ( JT ) = PKTINFO%FAC2
            FACREFF ( JT ) = PKTINFO%FAC3
            FACRLPN ( JT ) = PKTINFO%FAC4

        CASE( 'ALLOWABLE' )
            IALWSIC ( JT ) = STR2INT( PKTINFO%CSIC )
            FACALW  ( JT ) = PKTINFO%FAC1
            EMCAPALW( JT ) = PKTINFO%FAC2
            EMREPALW( JT ) = PKTINFO%FAC3

        CASE( 'ADD' )
            EMADD( JT ) = PKTINFO%FAC1

        CASE( 'REACTIVITY' )
            EMREPREA( JT ) = PKTINFO%FAC1
            PRJFCREA( JT ) = PKTINFO%FAC2
            MKTPNREA( JT ) = PKTINFO%FAC3
            CSCCREA ( JT ) = PKTINFO%NSCC
            CSPFREA ( JT ) = PKTINFO%TMPPRF

        CASE( 'PROJECTION' )
            IPRJSIC( JT ) = STR2INT( PKTINFO%CSIC )
            PRJFC  ( JT ) = PKTINFO%FAC1

        CASE( 'EMS_CONTROL' )
            IEMSSIC ( JT ) = STR2INT( PKTINFO%CSIC )
            BASCEFF ( JT ) = PKTINFO%FAC1
            BASREFF ( JT ) = PKTINFO%FAC2
            BASRLPN ( JT ) = PKTINFO%FAC3
            EMSCEFF ( JT ) = PKTINFO%FAC4
            EMSREFF ( JT ) = PKTINFO%FAC5
            EMSRLPN ( JT ) = PKTINFO%FAC6
            IF( PKTINFO%FAC7 .GT. 0. ) 
     &          EMSPTCF ( JT ) = PKTINFO%FAC7
            IF( PKTINFO%FAC8 .GT. 0. ) 
     &          EMSTOTL ( JT ) = PKTINFO%FAC8

        END SELECT

        RETURN

        END SUBROUTINE FILLCDAT
