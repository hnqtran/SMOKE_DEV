
        SUBROUTINE WRREPHDR( FDEV, RCNT, FILENUM, LH, OUTFMT )

C***********************************************************************
C  subroutine body starts at line 
C
C  DESCRIPTION:
C     This subroutine writes the header lines for a report based on the 
C     settings of the report-specific flags.  The header lines include lines 
C     for identifying the type of report as well as the column headers, 
C     which are set based on the labels for the generic output data columns.
C     It also determines the column widths
C
C  PRECONDITIONS REQUIRED:
C
C  SUBROUTINES AND FUNCTIONS CALLED:
C
C  REVISION  HISTORY:
C     Created 7/2000 by M Houyoux
C     Revised 7/2003 by A. Holland
C
C***********************************************************************
C  
C Project Title: Sparse Matrix Operator Kernel Emissions (SMOKE) Modeling
C                System
C File: @(#)$Id$
C  
C COPYRIGHT (C) 2004, Environmental Modeling for Policy Development
C All Rights Reserved
C 
C Carolina Environmental Program
C University of North Carolina at Chapel Hill
C 137 E. Franklin St., CB# 6116
C Chapel Hill, NC 27599-6116
C 
C smoke@unc.edu
C  
C Pathname: $Source$
C Last updated: $Date$ 
C  
C***********************************************************************

C.........  MODULES for public variables
C...........   This module is the inventory arrays
        USE MODSOURC, ONLY: STKHT, STKDM, STKTK, STKVE, CPDESC

C.........  This module contains the lists of unique source characteristics
        USE MODLISTS, ONLY: NINVSCC, SCCDESC, SCCDLEV, NINVSIC, SICDESC,
     &                      NINVMACT, MACTDESC, NINVNAICS, NAICSDESC

C.........  This module contains Smkreport-specific settings
        USE MODREPRT, ONLY: QAFMTL3, AFLAG, OUTDNAM, RPT_, LREGION,
     &                      PDSCWIDTH, VARWIDTH, DATEFMT, DATEWIDTH,
     &                      HOURFMT, HOURWIDTH, LAYRFMT, LAYRWIDTH,
     &                      CELLFMT, CELLWIDTH, SRCFMT, SRCWIDTH,
     &                      REGNFMT, REGNWIDTH, COWIDTH, STWIDTH,
     &                      CYWIDTH, SCCWIDTH, SRG1FMT, SRG1WIDTH,
     &                      SRG2FMT, SRG2WIDTH, MONFMT, MONWIDTH,
     &                      WEKFMT, WEKWIDTH, DIUFMT, DIUWIDTH,
     &                      CHARFMT, CHARWIDTH, STKPFMT, STKPWIDTH,
     &                      SPCWIDTH, ELEVWIDTH, SDSCWIDTH, UNITWIDTH,
     &                      MINC, LENELV3, SDATE, STIME, EDATE, ETIME,
     &                      PYEAR, PRBYR, PRPYR, OUTUNIT, TITLES,
     &                      ALLRPT, LOC_BEGP, LOC_ENDP, SICFMT,
     &                      SICWIDTH, SIDSWIDTH, MACTWIDTH, MACDSWIDTH,
     &                      NAIWIDTH, NAIDSWIDTH, STYPWIDTH,
     &                      LTLNFMT, LTLNWIDTH, LABELWIDTH, DLFLAG,
     &                      NFDFLAG, MATFLAG, ORSWIDTH, ORSDSWIDTH,
     &                      STKGWIDTH, STKGFMT

C.........  This module contains report arrays for each output bin
        USE MODREPBN, ONLY: NOUTBINS, BINX, BINY, BINSMKID, BINREGN,
     &                      BINSRGID1, BINSRGID2, BINMONID, BINWEKID,
     &                      BINDIUID, BINRCL, BINDATA, BINSNMIDX,
     &                      BINCYIDX, BINSTIDX, BINCOIDX, BINSPCID,
     &                      BINPLANT, BINSIC, BINSICIDX, BINMACT, 
     &                      BINMACIDX, BINNAICS, BINNAIIDX, BINSRCTYP,
     &                      BINORIS, BINORSIDX, BINSTKGRP

C.........  This module contains the arrays for state and county summaries
        USE MODSTCY, ONLY: NCOUNTRY, NSTATE, NCOUNTY, STCYPOPYR,
     &                     CTRYNAM, STATNAM, CNTYNAM, ORISDSC, NORIS

C.........  This module contains the global variables for the 3-d grid
        USE MODGRID, ONLY: GRDNM

CC...........  This module contains the information about the source category
        USE MODINFO, ONLY: NCHARS, CATEGORY, CATDESC, BYEAR, INVPIDX,
     &                     EANAM, ATTRUNIT

        IMPLICIT NONE

C...........   INCLUDES
        INCLUDE 'EMCNST3.EXT'   !  emissions constant parameters

C...........  EXTERNAL FUNCTIONS and their descriptions:
        CHARACTER(2)    CRLF
        INTEGER         STR2INT
        CHARACTER(14)   MMDDYY
        INTEGER         WKDAY

        EXTERNAL   CRLF, STR2INT, MMDDYY, WKDAY

C...........   SUBROUTINE ARGUMENTS
        INTEGER     , INTENT (IN) :: FDEV       ! output file unit number
        INTEGER     , INTENT (IN) :: RCNT       ! report count
        INTEGER     , INTENT (IN) :: FILENUM    ! file number
        INTEGER     , INTENT(OUT) :: LH         ! header width
        CHARACTER(QAFMTL3),
     &                INTENT(OUT) :: OUTFMT     ! output record format

C...........   Local parameters
        INTEGER, PARAMETER :: OLINELEN = 3500
        INTEGER, PARAMETER :: IHDRDATE = 1
        INTEGER, PARAMETER :: IHDRHOUR = 2
        INTEGER, PARAMETER :: IHDRLAYR = 3
        INTEGER, PARAMETER :: IHDRCOL  = 4
        INTEGER, PARAMETER :: IHDRROW  = 5
        INTEGER, PARAMETER :: IHDRSRC  = 6
        INTEGER, PARAMETER :: IHDRREGN = 7
        INTEGER, PARAMETER :: IHDRCNRY = 8
        INTEGER, PARAMETER :: IHDRSTAT = 9
        INTEGER, PARAMETER :: IHDRCNTY = 10
        INTEGER, PARAMETER :: IHDRSCC  = 11
        INTEGER, PARAMETER :: IHDRSIC  = 12
        INTEGER, PARAMETER :: IHDRMACT = 13
        INTEGER, PARAMETER :: IHDRNAI  = 14
        INTEGER, PARAMETER :: IHDRSTYP = 15
        INTEGER, PARAMETER :: IHDRSRG1 = 16
        INTEGER, PARAMETER :: IHDRSRG2 = 17
        INTEGER, PARAMETER :: IHDRMON  = 18
        INTEGER, PARAMETER :: IHDRWEK  = 19
        INTEGER, PARAMETER :: IHDRDIU  = 20
        INTEGER, PARAMETER :: IHDRSPC  = 21
        INTEGER, PARAMETER :: IHDRHT   = 22
        INTEGER, PARAMETER :: IHDRDM   = 23
        INTEGER, PARAMETER :: IHDRTK   = 24
        INTEGER, PARAMETER :: IHDRVE   = 25
        INTEGER, PARAMETER :: IHDRLAT  = 26
        INTEGER, PARAMETER :: IHDRLON  = 27
        INTEGER, PARAMETER :: IHDRELEV = 28
        INTEGER, PARAMETER :: IHDRSTKG = 29
        INTEGER, PARAMETER :: IHDRPNAM = 30
        INTEGER, PARAMETER :: IHDRSNAM = 31
        INTEGER, PARAMETER :: IHDRINAM = 32    ! SIC name
        INTEGER, PARAMETER :: IHDRMNAM = 33
        INTEGER, PARAMETER :: IHDRNNAM = 34
        INTEGER, PARAMETER :: IHDRVAR  = 35
        INTEGER, PARAMETER :: IHDRDATA = 36
        INTEGER, PARAMETER :: IHDRUNIT = 37
        INTEGER, PARAMETER :: IHDRLABL = 38
        INTEGER, PARAMETER :: IHDRNFDRS= 39
        INTEGER, PARAMETER :: IHDRMATBN= 40
        INTEGER, PARAMETER :: IHDRORIS = 41
        INTEGER, PARAMETER :: IHDRORNM = 42
        INTEGER, PARAMETER :: NHEADER  = 42

        CHARACTER(12), PARAMETER :: MISSNAME = 'Missing Name'

        CHARACTER(17), PARAMETER :: HEADERS( NHEADER ) = 
     &                          ( / 'Date             ',
     &                              'Hour             ',
     &                              'Layer            ',
     &                              'X cell           ',
     &                              'Y cell           ',
     &                              'Source ID        ',
     &                              'Region           ',
     &                              'Country          ',
     &                              'State            ',
     &                              'County           ',
     &                              'SCC              ',
     &                              'SIC              ',
     &                              'MACT             ',
     &                              'NAICS            ',
     &                              'Source type      ',
     &                              'Primary Srg      ',
     &                              'Fallbk Srg       ',
     &                              'Monthly Prf      ',
     &                              'Weekly Prf       ',
     &                              'Diurnal Prf      ',
     &                              'Spec Prf         ',
     &                              'Stk Ht           ',
     &                              'Stk Dm           ',
     &                              'Stk Tmp          ',
     &                              'Stk Vel          ',
     &                              'Latitude         ',
     &                              'Longitude        ',
     &                              'Elevstat         ',
     &                              'Stack Groups     ',
     &                              'Plt Name         ',
     &                              'SCC Description  ',
     &                              'SIC Description  ',
     &                              'MACT Description ',
     &                              'NAICS Description',
     &                              'Variable         ',
     &                              'Data value       ',
     &                              'Units            ',
     &                              'Label            ',
     &                              'NFDRS            ',
     &                              'MATBURNED        ',
     &                              'ORIS             ',
     &                              'ORIS Description ' / )

C...........   Local variables that depend on module variables
        LOGICAL    LCTRYUSE ( NCOUNTRY )
        LOGICAL    LSTATUSE ( NSTATE )
        LOGICAL    LCNTYUSE ( NCOUNTY )
        LOGICAL    LSCCUSE  ( NINVSCC )
        LOGICAL    LSICUSE  ( NINVSIC )
        LOGICAL    LMACTUSE ( NINVMACT )
        LOGICAL    LNAICSUSE( NINVNAICS )
        LOGICAL    LORISUSE ( NORIS )

        CHARACTER(10) CHRHDRS( NCHARS )  ! Source characteristics headers

C...........   Other local arrays
        INTEGER       PWIDTH( 4 )

C...........   Other local variables
        INTEGER     I, J, K, K1, K2, L, L1, L2, S, V, IOS

        INTEGER     LN              ! length of single units entry
        INTEGER     LU              ! cumulative width of units header
        INTEGER     LV              ! width of delimiter
        INTEGER     NC              ! tmp no. src chars
        INTEGER     NDECI           ! no decimal place of data format
        INTEGER     NLEFT           ! value of left part of data format
        INTEGER     NWIDTH          ! tmp with
        INTEGER     W1, W2          ! tmp widths
        INTEGER     STIDX           ! starting index of loop
        INTEGER     EDIDX           ! ending index of loop
        INTEGER, SAVE:: PDEV  = 0   ! previous output file unit number

        REAL        VAL             ! tmp data value
        REAL        PREVAL          ! tmp previous data value

        LOGICAL  :: CNRYMISS              ! true: >=1 missing country name
        LOGICAL  :: CNTYMISS              ! true: >=1 missing county name
        LOGICAL  :: DATFLOAT              ! true: use float output format
        LOGICAL  :: ORISMISS              ! true: >=1 missing ORIS name
        LOGICAL  :: STATMISS              ! true: >=1 missing state name
        LOGICAL  :: SCCMISS               ! true: >=1 missing SCC name
        LOGICAL  :: SICMISS               ! true: >=1 missing SIC name
        LOGICAL  :: MACTMISS              ! true: >=1 missing MACT name
        LOGICAL  :: NAICSMISS             ! true: >=1 missing NAICS name
        LOGICAL  :: DYSTAT                ! true: write average day header

        LOGICAL  :: FIRSTIME = .TRUE.     ! true: first time routine called

        CHARACTER(50)  :: BUFFER      ! write buffer
        CHARACTER(50)  :: LINFMT      ! header line of '-'
        CHARACTER(300) :: MESG        ! message buffer
        CHARACTER(IODLEN3)  :: TMPUNIT    ! tmp units buffer
        CHARACTER(OLINELEN) :: HDRBUF     ! labels line buffer
        CHARACTER(OLINELEN) :: UNTBUF     ! units line buffer
        CHARACTER(QAFMTL3)  :: TMPFMT ! temporary format for Linux PG compiler

        CHARACTER(16) :: PROGNAME = 'WRREPHDR' ! program name

C***********************************************************************
C   begin body of subroutine WRREPHDR
        
C.........  Initialize output subroutine arguments
        LH     = 0
        OUTFMT = ' '

C.........  Initialize local variables for current report
        CNRYMISS = .FALSE.
        STATMISS = .FALSE.
        CNTYMISS = .FALSE.
        SCCMISS  = .FALSE.
        SICMISS  = .FALSE.
        MACTMISS = .FALSE.
        NAICSMISS= .FALSE.
        ORISMISS = .FALSE.

        LCTRYUSE = .FALSE.    ! array
        LSTATUSE = .FALSE.    ! array
        LCNTYUSE = .FALSE.    ! array
        LSCCUSE  = .FALSE.    ! array
        LSICUSE  = .FALSE.    ! array
        LMACTUSE = .FALSE.    ! array
        LNAICSUSE= .FALSE.    ! array
        LORISUSE = .FALSE.    ! array
        
        PWIDTH   = 0          ! array
        LU       = 0

        IF( AFLAG ) THEN
            DEALLOCATE( OUTDNAM )
            ALLOCATE( OUTDNAM( RPT_%NUMDATA, RCNT ), STAT=IOS )
            CALL CHECKMEM( IOS, 'OUTDNAM', PROGNAME )
            OUTDNAM  = ''       ! array

            DO I = 1, RPT_%NUMDATA
                IF( AFLAG ) OUTDNAM( I, RCNT ) = EANAM( I )
            END DO
        END IF

C.........  Initialize report-specific settings
        RPT_ = ALLRPT( RCNT )  ! many-values

        LREGION = ( RPT_%BYCNRY .OR. RPT_%BYSTAT .OR. RPT_%BYCNTY )

C.........  Define source-category specific header
C.........  NOTE that (1) will not be used and none will be for area sources
        CHRHDRS( 1 ) = HEADERS( IHDRREGN )
        SELECT CASE( CATEGORY )
        CASE( 'AREA' )
            CHRHDRS( 2 ) = HEADERS( IHDRSCC )

        CASE( 'MOBILE' )
            CHRHDRS( 2 ) = 'Road '
            CHRHDRS( 3 ) = 'Link'
            CHRHDRS( 4 ) = 'Veh Type'
            CHRHDRS( 5 ) = 'SCC'

        CASE( 'POINT' )
            CHRHDRS( 2 ) = 'Plant ID'
            IF ( NCHARS .GE. 3 ) THEN
                IF( .NOT. AFLAG ) THEN
                    CHRHDRS( 3 ) = 'Char 1'
                ELSE
                    CHRHDRS( 3 ) = 'Stack ID'
                END IF
            END IF
            IF ( NCHARS .GE. 4 ) CHRHDRS( 4 ) = 'Char 2'
            IF ( NCHARS .GE. 5 ) CHRHDRS( 5 ) = 'Char 3'
            IF ( NCHARS .GE. 6 ) CHRHDRS( 6 ) = 'Char 4'
            IF ( NCHARS .GE. 7 ) CHRHDRS( 7 ) = 'Char 5'

        END SELECT

C............................................................................
C.........  Pre-process output bins to determine the width of the stack 
C           parameter and variable-length string columns.
C.........  For country, state, county, SCC names, and SIC names only flag 
C           which ones are being used by the selected sources.
C............................................................................
        PDSCWIDTH = 1
        DO I = 1, NOUTBINS

C.............  Include country name in string
            IF( RPT_%BYCONAM ) THEN
                J = BINCOIDX( I )
                IF( J .GT. 0 ) LCTRYUSE( J ) = .TRUE.
                IF( J .LE. 0 ) CNRYMISS = .TRUE.
            END IF

C.............  Include state name in string
            IF( RPT_%BYSTNAM ) THEN
                J = BINSTIDX( I )
                IF( J .GT. 0 ) LSTATUSE( J ) = .TRUE.
                IF( J .LE. 0 ) STATMISS = .TRUE.
            END IF

C.............  Include county name in string
            IF( RPT_%BYCYNAM ) THEN
                J = BINCYIDX( I )
                IF( J .GT. 0 ) LCNTYUSE( J ) = .TRUE.
                IF( J .LE. 0 ) CNTYMISS = .TRUE.
            END IF

C.............  Include stack parameters
            IF( RPT_%STKPARM ) THEN
                S = BINSMKID( I )
 
                BUFFER = ' '
                WRITE( BUFFER, '(F30.0)' ) STKHT( S )
                BUFFER = ADJUSTL( BUFFER )
                PWIDTH( 1 ) = MAX( PWIDTH( 1 ), LEN_TRIM( BUFFER ) )

                BUFFER = ' '
                WRITE( BUFFER, '(F30.0)' ) STKDM( S )
                BUFFER = ADJUSTL( BUFFER )
                PWIDTH( 2 ) = MAX( PWIDTH( 2 ), LEN_TRIM( BUFFER ) )

                BUFFER = ' '
                WRITE( BUFFER, '(F30.0)' ) STKTK( S )
                BUFFER = ADJUSTL( BUFFER )
                PWIDTH( 3 ) = MAX( PWIDTH( 3 ), LEN_TRIM( BUFFER ) )

                BUFFER = ' '
                WRITE( BUFFER, '(F30.0)' ) STKVE( S )
                BUFFER = ADJUSTL( BUFFER )
                PWIDTH( 4 ) = MAX( PWIDTH( 4 ), LEN_TRIM( BUFFER ) )

            END IF

C.............  Include plant description (for point sources)
            IF( RPT_%SRCNAM ) THEN
                S = BINSMKID( I )
                PDSCWIDTH = MAX( PDSCWIDTH, LEN_TRIM( CPDESC( S ) ) )
            END IF

C.............  Include SCC description
            IF( RPT_%SCCNAM ) THEN
                J = BINSNMIDX( I ) 
                IF( J .GT. 0 ) LSCCUSE( J ) = .TRUE.
            END IF

C.............  Include SIC description
            IF( RPT_%SICNAM ) THEN
                J = BINSICIDX( I ) 
                IF( J .GT. 0 ) LSICUSE( J ) = .TRUE.
            END IF
 
C.............  Include MACT description
            IF( RPT_%MACTNAM ) THEN
                J = BINMACIDX( I ) 
                IF( J .GT. 0 ) LMACTUSE( J ) = .TRUE.
            END IF

C.............  Include NAICS description
            IF( RPT_%NAICSNAM ) THEN
                J = BINNAIIDX( I ) 
                IF( J .GT. 0 ) LNAICSUSE( J ) = .TRUE.
            END IF

C.............  Include ORIS description
            IF( RPT_%ORISNAM ) THEN
                J = BINORSIDX( I ) 
                IF( J .GT. 0 ) LORISUSE( J ) = .TRUE.
            END IF

       END DO  ! End loop through bins

C............................................................................
C.........  Set the widths of each output column, while including the
C           width of the column header.
C.........  Build the formats for the data in each column
C.........  Build the header as we go along
C............................................................................

C.........  The extra length for each variable is 1 space and 1 delimiter width
        LV = LEN_TRIM( RPT_%DELIM ) + 1

C.........  Variable column
        IF( RPT_%RPTMODE .EQ. 3 ) THEN
            NWIDTH = 0
            DO I = 1, RPT_%NUMDATA
                NWIDTH = MAX( NWIDTH, LEN_TRIM( OUTDNAM( I, RCNT ) ) )
            END DO

            J = LEN_TRIM( HEADERS( IHDRVAR ) )
            J = MAX( NWIDTH, J )

            CALL ADD_TO_HEADER( J, HEADERS(IHDRVAR), LH, HDRBUF )

            VARWIDTH = J + LV

        END IF

C.........  User-defined label
        IF( RPT_%USELABEL ) THEN
            J = MAX( LEN_TRIM( RPT_%LABEL ), 
     &               LEN_TRIM( HEADERS(IHDRLABL) ) )
            LABELWIDTH = J + LV

            CALL ADD_TO_HEADER( J, HEADERS(IHDRLABL), LH, HDRBUF )
            CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

        END IF

C.........  Date column
        IF( RPT_%BYDATE ) THEN
            J = 10  ! header width is MM/DD/YYYY
            WRITE( DATEFMT, 94620 ) RPT_%DELIM  ! leading zeros
            DATEWIDTH = J + LV

            CALL ADD_TO_HEADER( J, HEADERS(IHDRDATE), LH, HDRBUF )
            CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

        END IF

C.........  Hour column
        IF( RPT_%BYHOUR ) THEN
            IF( .NOT. DLFLAG ) THEN
                J = LEN_TRIM( HEADERS( IHDRHOUR ) )  ! header width
                WRITE( HOURFMT, 94630 ) J, 2, RPT_%DELIM  ! leading zeros
                J = MAX( 2, J )
                HOURWIDTH = J + LV

                CALL ADD_TO_HEADER( J, HEADERS(IHDRHOUR), LH, HDRBUF )
                CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

            END IF
        END IF

C.........  Layer column
        IF( RPT_%BYLAYER ) THEN
            J = LEN_TRIM( HEADERS( IHDRLAYR ) )  ! header width
            WRITE( LAYRFMT, 94630 ) J, 2, RPT_%DELIM  ! leading zeros
            J = MAX( 2, J )
            LAYRWIDTH = J + LV

            CALL ADD_TO_HEADER( J, HEADERS(IHDRLAYR), LH, HDRBUF )
            CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

        END IF

C.........  Cell columns
        IF( RPT_%BYCELL ) THEN

C.............  X-cell
            J = LEN_TRIM( HEADERS( IHDRCOL ) )
            W1 = INTEGER_COL_WIDTH( NOUTBINS, BINX )
            W1 = MAX( W1, J )
            CALL ADD_TO_HEADER( W1, HEADERS(IHDRCOL), LH, HDRBUF )
            CALL ADD_TO_HEADER( W1, ' ', LU, UNTBUF )

C.............  Y-cell
            J = LEN_TRIM( HEADERS( IHDRROW ) )
            W2 = INTEGER_COL_WIDTH( NOUTBINS, BINY )
            W2 = MAX( W2, J )

            CALL ADD_TO_HEADER( W2, HEADERS(IHDRROW), LH, HDRBUF )
            CALL ADD_TO_HEADER( W2, ' ', LU, UNTBUF )

C.............  Write format to include both x-cell and y-cell
            WRITE( CELLFMT, 94635 ) W1, RPT_%DELIM, W2, RPT_%DELIM
            CELLWIDTH = W1 + W2 + 2*LV
        END IF

C.........  Source ID column
        IF( RPT_%BYSRC ) THEN

            J = LEN_TRIM( HEADERS( IHDRSRC ) )
            W1 = INTEGER_COL_WIDTH( NOUTBINS, BINSMKID )
            W1 = MAX( W1, J )

            CALL ADD_TO_HEADER( W1, HEADERS(IHDRSRC), LH, HDRBUF )
            CALL ADD_TO_HEADER( W1, ' ', LU, UNTBUF )

            WRITE( SRCFMT, 94625 ) W1, RPT_%DELIM
            SRCWIDTH = W1 + LV

        END IF

C.........  Region code column
        IF( LREGION ) THEN
            J  = LEN_TRIM( HEADERS( IHDRREGN ) )
            W1 = INTEGER_COL_WIDTH( NOUTBINS, BINREGN )
            W1  = MAX( W1, J )

            CALL ADD_TO_HEADER( W1, HEADERS(IHDRREGN), LH, HDRBUF)
            CALL ADD_TO_HEADER( W1, ' ', LU, UNTBUF )

            WRITE( REGNFMT, 94630 ) W1, FIPLEN3, RPT_%DELIM     ! leading zeros
            REGNWIDTH = W1 + LV
        END IF

C.........  Set widths and build formats for country, state, and county names.
C           These are done on loops of unique lists of these names
C           so that the LEN_TRIMs can be done on the shortest possible list
C           of entries instead of on all entries in the bins list.

C.........  Country names
        IF( RPT_%BYCONAM ) THEN

C.............  For countries in the inventory, get max name width
            NWIDTH = 0
            DO I = 1, NCOUNTRY
                IF( LCTRYUSE( I ) ) THEN
                    NWIDTH = MAX( NWIDTH, LEN_TRIM( CTRYNAM( I ) ) )
                END IF
            END DO

C.............  If any missing country names, check widths
            IF( CNRYMISS ) NWIDTH = MAX( NWIDTH, LEN_TRIM( MISSNAME ) )

C.............  Set country name column width 
            J = LEN_TRIM( HEADERS( IHDRCNRY ) )
            J = MAX( NWIDTH, J )

            CALL ADD_TO_HEADER( J, HEADERS(IHDRCNRY), LH, HDRBUF )
            CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

            COWIDTH = J + LV

        END IF

C.........  State names
        IF( RPT_%BYSTNAM ) THEN

C.............  For states in the inventory, get max name width
            NWIDTH = 0
            DO I = 1, NSTATE
                IF( LSTATUSE( I ) ) THEN
                    NWIDTH = MAX( NWIDTH, LEN_TRIM( STATNAM( I ) ) )
                END IF
            END DO

C.............  If any missing state names, check widths
            IF( STATMISS ) NWIDTH = MAX( NWIDTH, LEN_TRIM( MISSNAME ) )

C.............  Set country name column width 
            J = LEN_TRIM( HEADERS( IHDRSTAT ) )
            J = MAX( NWIDTH, J )

            CALL ADD_TO_HEADER( J, HEADERS(IHDRSTAT), LH, HDRBUF )
            CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

            STWIDTH = J + LV

        END IF

C.........  County names
        IF( RPT_%BYCYNAM ) THEN

C.............  For countries in the inventory, get max name width
            NWIDTH = 0
            DO I = 1, NCOUNTY
                IF( LCNTYUSE( I ) ) THEN
                    NWIDTH = MAX( NWIDTH, LEN_TRIM( CNTYNAM( I ) ) )
                END IF
            END DO

C.............  If any missing country names, check widths
            IF( CNTYMISS ) NWIDTH = MAX( NWIDTH, LEN_TRIM( MISSNAME ) )

C.............  Set country name column width 
            J = LEN_TRIM( HEADERS( IHDRCNTY ) )
            J = MAX( NWIDTH, J )

            CALL ADD_TO_HEADER( J, HEADERS(IHDRCNTY), LH, HDRBUF )
            CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

            CYWIDTH = J + LV

        END IF

C.........  SCC column
        IF( RPT_%BYSCC ) THEN
            J = LEN_TRIM( HEADERS( IHDRSCC ) )
            IF( RPT_%SCCRES < NSCCLV3 ) J = J + 7  ! Plus " Tier #"
            J = MAX( SCCLEN3, J )
   
            IF( RPT_%SCCRES < NSCCLV3 ) THEN
                WRITE( BUFFER, '(A,I1)' ) TRIM( HEADERS(IHDRSCC) ) // 
     &                                    ' Tier ', RPT_%SCCRES
            ELSE
                BUFFER = TRIM( HEADERS(IHDRSCC) )
            END IF

            CALL ADD_TO_HEADER( J, BUFFER, LH, HDRBUF )
            CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

            SCCWIDTH = J + LV
        END IF

C.........  SIC column
        IF( RPT_%BYSIC ) THEN
            IF( MATFLAG ) THEN
                J = LEN_TRIM( HEADERS( IHDRMATBN ) )
                W1 = INTEGER_COL_WIDTH( NOUTBINS, BINSIC )
                W1 = MAX( W1, J )  
                CALL ADD_TO_HEADER( W1, HEADERS(IHDRMATBN), LH, HDRBUF )
                CALL ADD_TO_HEADER( W1, ' ', LU, UNTBUF )

                WRITE( SICFMT, 94650 ) W1, RPT_%DELIM
                SICWIDTH = W1 + LV
            ELSE
                J = LEN_TRIM( HEADERS( IHDRSIC ) )
                W1 = INTEGER_COL_WIDTH( NOUTBINS, BINSIC )
                W1 = MAX( W1, J )  
                CALL ADD_TO_HEADER( W1, HEADERS(IHDRSIC), LH, HDRBUF )
                CALL ADD_TO_HEADER( W1, ' ', LU, UNTBUF )

                WRITE( SICFMT, 94650 ) W1, RPT_%DELIM
                SICWIDTH = W1 + LV
            END IF
        END IF

C.........  MACT column
        IF( RPT_%BYMACT ) THEN
            IF( NFDFLAG ) THEN
                J = LEN_TRIM( HEADERS( IHDRNFDRS ) )
                J = MAX( MACLEN3, J )
                CALL ADD_TO_HEADER( J, HEADERS(IHDRNFDRS), LH, HDRBUF )
                CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )
                MACTWIDTH = J + LV
            ELSE
                J = LEN_TRIM( HEADERS( IHDRMACT ) )
                J = MAX( MACLEN3, J )
                CALL ADD_TO_HEADER( J, HEADERS(IHDRMACT), LH, HDRBUF )
                CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )
                MACTWIDTH = J + LV
            END IF
        END IF

C.........  NAICS column
        IF( RPT_%BYNAICS ) THEN
            J = LEN_TRIM( HEADERS( IHDRNAI ) )
            J = MAX( NAILEN3, J )
    
            CALL ADD_TO_HEADER( J, HEADERS(IHDRNAI), LH, HDRBUF )
            CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

            NAIWIDTH = J + LV
        END IF

C.........  SRCTYP column
        IF( RPT_%BYSRCTYP ) THEN
            J = LEN_TRIM( HEADERS( IHDRSTYP ) )
            J = MAX( STPLEN3, J )
    
            CALL ADD_TO_HEADER( J, HEADERS(IHDRSTYP), LH, HDRBUF )
            CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

            STYPWIDTH = J + LV
        END IF

C.........  Primary surrogates column
        IF( RPT_%SRGRES .EQ. 1 ) THEN
            J = LEN_TRIM( HEADERS( IHDRSRG1 ) )
            W1 = INTEGER_COL_WIDTH( NOUTBINS, BINSRGID1 )
            W1  = MAX( W1, J )
            CALL ADD_TO_HEADER( W1, HEADERS(IHDRSRG1), LH, HDRBUF )
            CALL ADD_TO_HEADER( W1, ' ', LU, UNTBUF )

            WRITE( SRG1FMT, 94650 ) W1, RPT_%DELIM 
            SRG1WIDTH = W1 + LV
        END IF

C.........  Fallback surrogates column
        IF( RPT_%SRGRES .GE. 1 ) THEN
            J = LEN_TRIM( HEADERS( IHDRSRG2 ) )
            W1 = INTEGER_COL_WIDTH( NOUTBINS, BINSRGID2 )
            W1  = MAX( W1, J )
            CALL ADD_TO_HEADER( W1, HEADERS(IHDRSRG2), LH, HDRBUF )
            CALL ADD_TO_HEADER( W1, ' ', LU, UNTBUF )

            WRITE( SRG2FMT, 94650 ) W1, RPT_%DELIM 
            SRG2WIDTH = W1 + LV
        END IF

C.........  Temporal profiles columns
        IF( RPT_%BYMON ) THEN          ! Monthly
            J = LEN_TRIM( HEADERS( IHDRMON ) )
            W1 = INTEGER_COL_WIDTH( NOUTBINS, BINMONID )
            W1  = MAX( W1, J )
            CALL ADD_TO_HEADER( W1, HEADERS(IHDRMON), LH, HDRBUF )
            CALL ADD_TO_HEADER( W1, ' ', LU, UNTBUF )

            WRITE( MONFMT, 94625 ) W1, RPT_%DELIM 
            MONWIDTH = W1 + LV
        END IF

        IF( RPT_%BYWEK ) THEN          ! Weekly
            J = LEN_TRIM( HEADERS( IHDRWEK ) )
            W1 = INTEGER_COL_WIDTH( NOUTBINS, BINWEKID )
            W1  = MAX( W1, J )
            CALL ADD_TO_HEADER( W1, HEADERS(IHDRWEK), LH, HDRBUF )
            CALL ADD_TO_HEADER( W1, ' ', LU, UNTBUF )

            WRITE( WEKFMT, 94625 ) W1, RPT_%DELIM 
            WEKWIDTH = W1 + LV
        END IF

        IF( RPT_%BYDIU ) THEN          ! Diurnal
            J = LEN_TRIM( HEADERS( IHDRDIU ) )
            W1 = INTEGER_COL_WIDTH( NOUTBINS, BINDIUID )
            W1  = MAX( W1, J )
            CALL ADD_TO_HEADER( W1, HEADERS(IHDRDIU), LH, HDRBUF )
            CALL ADD_TO_HEADER( W1, ' ', LU, UNTBUF )

            WRITE( DIUFMT, 94625 ) W1, RPT_%DELIM 
            DIUWIDTH = W1 + LV
        END IF

C.........  Speciation profile column
        IF( RPT_%BYSPC ) THEN

            NWIDTH = 0
            DO I = 1, NOUTBINS
                NWIDTH = MAX( NWIDTH, LEN_TRIM( BINSPCID( I ) ) )
            END DO

C.............  Set speciation profiles column width 
            J = LEN_TRIM( HEADERS( IHDRSPC ) )
            J = MAX( NWIDTH, J )

            CALL ADD_TO_HEADER( J, HEADERS(IHDRSPC), LH, HDRBUF )
            CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

            SPCWIDTH = J + LV

        END IF

C.........  Road class.  By roadclass can only be true if by source is not
C           being used.
        IF( RPT_%BYRCL ) THEN
            J  = LEN_TRIM( CHRHDRS( 2 ) )
            W1 = INTEGER_COL_WIDTH( NOUTBINS, BINRCL )
            W1  = MAX( W1, J )

            CALL ADD_TO_HEADER( W1, CHRHDRS( 2 ), LH, HDRBUF )
            CALL ADD_TO_HEADER( W1, ' ', LU, UNTBUF )

            WRITE( CHARFMT, 94645 ) W1, RPT_%DELIM 
            CHARWIDTH = W1 + LV

        END IF

C.........  Source characteristics. NOTE - the source characteristics have
C           already been rearranged and their widths reset based on the
C           inventory.  The SCC has been removed if its one of the source
C           characteristics, and NCHARS reset accordingly.
        IF( RPT_%BYSRC ) THEN        

            CHARWIDTH = 0
            CHARFMT = '('

            DO K = MINC, NCHARS

C.................  Build source characteristics output format for WRREPOUT
                TMPFMT = CHARFMT
                L  = LEN_TRIM( TMPFMT )
                J  = LEN_TRIM( CHRHDRS( K ) )
                W1 = MAX( LOC_ENDP( K ) - LOC_BEGP( K ) + 1, J )
                WRITE( CHARFMT, '(A,I2.2,A)' ) TMPFMT( 1:L )// 
     &                 '1X,A', W1, ',"'//RPT_%DELIM//'",'

                CALL ADD_TO_HEADER( W1, CHRHDRS( K ), LH, HDRBUF )
                CALL ADD_TO_HEADER( W1, ' ', LU, UNTBUF )

                CHARWIDTH = CHARWIDTH + W1 + LV

            END DO

            TMPFMT = CHARFMT
            L = LEN_TRIM( TMPFMT ) - 1   ! (minus 1 to remove trailing comma)
            CHARFMT = TMPFMT( 1:L ) // ')'

        END IF

C.........  Plant ID
        IF( RPT_%BYPLANT ) THEN
            NWIDTH = 0
            DO I = 1, NOUTBINS
                NWIDTH = MAX( NWIDTH, LEN_TRIM( BINPLANT( I ) ) )
            END DO

            J  = LEN_TRIM( CHRHDRS( 2 ) )
            W1 = MAX( NWIDTH, J )

            CALL ADD_TO_HEADER( W1, CHRHDRS( 2 ), LH, HDRBUF )
            CALL ADD_TO_HEADER( W1, ' ', LU, UNTBUF )

            WRITE( CHARFMT, 94645 ) W1, RPT_%DELIM
            CHARWIDTH = W1 + LV

        END IF

C.........  ORIS ID
        IF( RPT_%BYORIS ) THEN
            NWIDTH = 0
            DO I = 1, NOUTBINS
                NWIDTH = MAX( NWIDTH, LEN_TRIM( BINORIS( I ) ) )
            END DO

            J = LEN_TRIM( HEADERS( IHDRORIS ) )
            J = MAX( NWIDTH, J )

            CALL ADD_TO_HEADER( J, HEADERS( IHDRORIS ), LH, HDRBUF )
            CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

            ORSWIDTH = J + LV

        END IF

C.........  Stack parameters.  +3 for decimal and 2 significant figures
        IF( RPT_%STKPARM ) THEN

            J = LEN_TRIM( HEADERS( IHDRHT ) )
            PWIDTH( 1 ) = MAX( PWIDTH( 1 ) + 3, J )
            CALL ADD_TO_HEADER( PWIDTH( 1 ), HEADERS( IHDRHT ), 
     &                          LH, HDRBUF )
            CALL ADD_TO_HEADER( PWIDTH( 1 ), ATTRUNIT( 8 ), LU, UNTBUF )

            J = LEN_TRIM( HEADERS( IHDRDM ) )
            PWIDTH( 2 ) = MAX( PWIDTH( 2 ) + 3, J )
            CALL ADD_TO_HEADER( PWIDTH( 2 ), HEADERS( IHDRDM ), 
     &                          LH, HDRBUF )
            CALL ADD_TO_HEADER( PWIDTH( 2 ), ATTRUNIT( 9 ), LU, UNTBUF )

            J = LEN_TRIM( HEADERS( IHDRTK ) )
            PWIDTH( 3 ) = MAX( PWIDTH( 3 ) + 3, J )
            CALL ADD_TO_HEADER( PWIDTH( 3 ), HEADERS( IHDRTK ), 
     &                          LH, HDRBUF )
            CALL ADD_TO_HEADER( PWIDTH( 3 ), ATTRUNIT(10), LU, UNTBUF )

            J = LEN_TRIM( HEADERS( IHDRVE ) )
            PWIDTH( 4 ) = MAX( PWIDTH( 4 ) + 3, J )
            CALL ADD_TO_HEADER( PWIDTH( 4 ), HEADERS( IHDRVE ), 
     &                          LH, HDRBUF )
            CALL ADD_TO_HEADER( PWIDTH( 4 ), ATTRUNIT(11), LU, UNTBUF )

            WRITE( STKPFMT, 94640 ) PWIDTH( 1 ), RPT_%DELIM,
     &                              PWIDTH( 2 ), RPT_%DELIM,
     &                              PWIDTH( 3 ), RPT_%DELIM,
     &                              PWIDTH( 4 ), RPT_%DELIM

            STKPWIDTH = SUM( PWIDTH ) + 4*LV

        END IF

C.........  Point-source latitude and longitude
        IF( RPT_%LATLON ) THEN
        
            J = LEN_TRIM( HEADERS( IHDRLAT ) )
            PWIDTH( 1 ) = 13
            CALL ADD_TO_HEADER( PWIDTH( 1 ), HEADERS( IHDRLAT ),
     &                          LH, HDRBUF )
            CALL ADD_TO_HEADER( PWIDTH( 1 ), '    ', LU, UNTBUF )
            
            J = LEN_TRIM( HEADERS( IHDRLON ) )
            PWIDTH( 2 ) = 13
            CALL ADD_TO_HEADER( PWIDTH( 2 ), HEADERS( IHDRLON ),
     &                          LH, HDRBUF )
            CALL ADD_TO_HEADER( PWIDTH( 2 ), '     ', LU, UNTBUF )
            
            WRITE( LTLNFMT, 94642 ) PWIDTH( 1 ), RPT_%DELIM,
     &                              PWIDTH( 2 ), RPT_%DELIM
     
            LTLNWIDTH = SUM( PWIDTH( 1:2 ) ) + 2*LV
            
        END IF

C.........  Elevated flag column
        IF( RPT_%BYELEV ) THEN
            J = LEN_TRIM( HEADERS( IHDRELEV ) )
            J = MAX( LENELV3, J )

            CALL ADD_TO_HEADER( J, HEADERS(IHDRELEV), LH, HDRBUF )
            CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

            ELEVWIDTH = J + LV

        END IF

C.........  Stack group IDs when BY ELEVSTAT (RPT_%BYELEV)
        IF( RPT_%ELVSTKGRP ) THEN
            J = LEN_TRIM( HEADERS( IHDRSTKG ) )
            W1 = INTEGER_COL_WIDTH( NOUTBINS, BINSTKGRP )
            W1 = MAX( W1, J )  
            CALL ADD_TO_HEADER( W1, HEADERS(IHDRSTKG), LH, HDRBUF )
            CALL ADD_TO_HEADER( W1, ' ', LU, UNTBUF )

            WRITE( STKGFMT, 94625 ) W1, RPT_%DELIM
            STKGWIDTH = W1 + LV
        END IF

C.........  Plant descriptions
        IF( RPT_%SRCNAM ) THEN
            J = LEN_TRIM( HEADERS( IHDRPNAM ) )
            J = MAX( PDSCWIDTH, J )

            CALL ADD_TO_HEADER( J, HEADERS(IHDRPNAM), LH, HDRBUF )
            CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

            PDSCWIDTH = J + LV
        END IF

C.........  ORIS descriptions
        IF( RPT_%ORISNAM ) THEN
            NWIDTH = 0
            DO I = 1, NORIS
                IF( LORISUSE( I ) ) THEN
                    L = LEN( ORISDSC( I ) )
                    NWIDTH = MAX( NWIDTH, L )
                    IF ( L .EQ. 0 ) ORISMISS = .TRUE.
                END IF
            END DO

C.............  If any missing ORIS names, check widths
            IF( ORISMISS ) NWIDTH = MAX( NWIDTH, LEN_TRIM( MISSNAME ) )

C.............  Set ORIS name column width 
            J = LEN_TRIM( HEADERS( IHDRORNM ) )
            J = MAX( NWIDTH, J ) + 2 ! two for quotes

            CALL ADD_TO_HEADER( J, HEADERS( IHDRORNM ), LH, HDRBUF )
            CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

            ORSDSWIDTH = J + LV - 2       ! quotes in count for header print
        END IF

C.........  SCC names
        IF( RPT_%SCCNAM ) THEN

C.............  For SCC descriptions in the inventory, get max name 
C               width
            NWIDTH = 0
            DO I = 1, NINVSCC
                IF( LSCCUSE( I ) ) THEN
                    J = RPT_%SCCRES
                    L = SCCDLEV( I,J )
                    NWIDTH = MAX( NWIDTH, LEN( SCCDESC( I )( 1:L ) ) )
                    IF ( NWIDTH .EQ. 0 ) SCCMISS = .TRUE.
                END IF
            END DO

C.............  If any missing SCC names, check widths
            IF( SCCMISS ) NWIDTH = MAX( NWIDTH, LEN_TRIM( MISSNAME ) )

C.............  Set SCC name column width 
            J = LEN_TRIM( HEADERS( IHDRSNAM ) )
            J = MAX( NWIDTH, J ) + 2     ! two for quotes

            CALL ADD_TO_HEADER( J, HEADERS(IHDRSNAM), LH, HDRBUF )
            CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

            SDSCWIDTH = J + LV - 2       ! quotes in count for header print

        END IF

C.........  SIC names
        IF( RPT_%SICNAM ) THEN

C.............  For SIC descriptions in the inventory, get max name 
C               width
            NWIDTH = 0
            DO I = 1, NINVSIC
                IF( LSICUSE( I ) ) THEN
                    NWIDTH = MAX( NWIDTH, LEN_TRIM( SICDESC( I ) ) )
                    IF ( NWIDTH .EQ. 0 ) SICMISS = .TRUE.
                END IF
            END DO

C.............  If any missing SIC names, check widths
            IF( SICMISS ) NWIDTH = MAX( NWIDTH, LEN_TRIM( MISSNAME ) )

C.............  Set SIC name column width 
            J = LEN_TRIM( HEADERS( IHDRINAM ) )
            J = MAX( NWIDTH, J ) + 2     ! two for quotes

            CALL ADD_TO_HEADER( J, HEADERS(IHDRINAM), LH, HDRBUF )
            CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

            SIDSWIDTH = J + LV - 2       ! quotes in count for header print

        END IF

C.........  MACT names
        IF( RPT_%MACTNAM ) THEN

C.............  For MACT descriptions in the inventory, get max name 
C               width
            NWIDTH = 0
            DO I = 1, NINVMACT
                IF( LMACTUSE( I ) ) THEN
                    NWIDTH = MAX( NWIDTH, LEN_TRIM( MACTDESC( I ) ) )
                    IF ( NWIDTH .EQ. 0 ) MACTMISS = .TRUE.
                END IF
            END DO

C.............  If any missing MACT names, check widths
            IF( MACTMISS ) NWIDTH = MAX( NWIDTH, LEN_TRIM( MISSNAME ) )

C.............  Set MACT name column width 
            J = LEN_TRIM( HEADERS( IHDRMNAM ) )
            J = MAX( NWIDTH, J ) + 2     ! two for quotes

            CALL ADD_TO_HEADER( J, HEADERS(IHDRMNAM), LH, HDRBUF )
            CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

            MACDSWIDTH = J + LV - 2       ! quotes in count for header print

        END IF

C.........  NAICS names
        IF( RPT_%NAICSNAM ) THEN

C.............  For NAICS descriptions in the inventory, get max name 
C               width
            NWIDTH = 0
            DO I = 1, NINVNAICS
                IF( LNAICSUSE( I ) ) THEN
                    L = LEN_TRIM( NAICSDESC( I ) )
                    NWIDTH = MAX( NWIDTH, L )
                    IF ( L .EQ. 0 ) NAICSMISS = .TRUE.
                END IF
            END DO

C.............  If any missing NAICS names, check widths
            IF( NAICSMISS ) NWIDTH = MAX( NWIDTH, LEN_TRIM( MISSNAME ) )

C.............  Set NAICS name column width 
            J = LEN_TRIM( HEADERS( IHDRNNAM ) )
            J = MAX( NWIDTH, J ) + 2     ! two for quotes

            CALL ADD_TO_HEADER( J, HEADERS(IHDRNNAM), LH, HDRBUF )
            CALL ADD_TO_HEADER( J, ' ', LU, UNTBUF )

            NAIDSWIDTH = J + LV - 2       ! quotes in count for header print

        END IF

C.........  Determine the format type requested (if any) - either float or
C           scientific. Also determine the number of decimal places 
C           requested.
C.........  The data format will already have been QAed so not need to worry
C           about that here.
        J = INDEX( RPT_%DATAFMT, '.' )
        L = LEN_TRIM( RPT_%DATAFMT )
        NLEFT = STR2INT( RPT_%DATAFMT(   2:J-1 ) )
        NDECI = STR2INT( RPT_%DATAFMT( J+1:L   ) )

        J = INDEX( RPT_%DATAFMT, 'F' )
        DATFLOAT = ( J .GT. 0 )

C.........  Data values. Get width for columns that use the "F" format instead
C           of the "E" format.  The code will not permit the user to specify
C           a width that is too small for the value requested.
        IF( RPT_%NUMDATA .GT. 0 ) THEN

            OUTFMT = '(A,1X,'            

            IF( RPT_%NUMFILES .EQ. 1 ) THEN

                IF( RPT_%RPTMODE .EQ. 2 ) THEN

                    IF( FIRSTIME ) THEN
                        STIDX = 1
                        EDIDX = RPT_%RPTNVAR
                        FIRSTIME = .FALSE.

                    ELSE
                        IF( EDIDX + RPT_%RPTNVAR .GT.
     &                                 RPT_%NUMDATA ) THEN

                            STIDX = EDIDX + 1
                            EDIDX = RPT_%NUMDATA

                        ELSE

                            STIDX = EDIDX + 1
                            EDIDX = EDIDX + RPT_%RPTNVAR

                        END IF

                    END IF

                ELSE IF( RPT_%RPTMODE .EQ. 1 ) THEN

                    STIDX = 1
                    EDIDX = RPT_%NUMDATA

                ELSE IF( RPT_%RPTMODE .EQ. 3 ) THEN

                    STIDX = 1
                    EDIDX = 1

                ELSE

                    STIDX = 1
                    EDIDX = RPT_%NUMDATA
        
                END IF

            ELSE

                IF( FIRSTIME ) THEN
                    STIDX = 1
                    EDIDX = RPT_%RPTNVAR
                    FIRSTIME = .FALSE.

                ELSE
                    IF( EDIDX + RPT_%RPTNVAR .GT. 
     &                                 RPT_%NUMDATA ) THEN
                
                        STIDX = EDIDX + 1
                        EDIDX = RPT_%NUMDATA

                    ELSE

                        STIDX = EDIDX + 1
                        EDIDX = EDIDX + RPT_%RPTNVAR
 
                    END IF

                END IF

            END IF

            DO J = STIDX, EDIDX

C.................  Build temporary units fields and get final width
                L = LEN_TRIM( OUTUNIT( J ) )
                TMPUNIT = '[' // OUTUNIT( J )( 1:L ) // ']'
                LN = LEN_TRIM( TMPUNIT )

C.................  If float format
                IF ( DATFLOAT ) THEN

C.....................  For database output get max data value for all columns
                    IF( RPT_%RPTMODE .EQ. 3 ) THEN

                        PREVAL = 0.0
                        DO I = 1, RPT_%NUMDATA

                            VAL = MAXVAL( BINDATA( :,J ) )
                            IF( VAL .LE. PREVAL ) CYCLE
                            PREVAL = VAL

                        END DO

                        VAL = PREVAL

                    ELSE

C.....................  Get maximum data value for this column
                        VAL = MAXVAL( BINDATA( :,J ) )

                    END IF

                    BUFFER = ' '
                    WRITE( BUFFER, '(F30.0)' ) VAL
                    BUFFER = ADJUSTL( BUFFER )

C.....................  Store the minimum width of the left part of the format. 
                    W1 = LEN_TRIM( BUFFER )

C.....................  Increase the width to include the decimal places
                    W1 = W1 + NDECI + 1           ! +1 for decimal point

C.....................  Set the left part of the format.  Compare needed width 
C                       with requested width and width of the column header
C                       and units header
                    IF( RPT_%RPTMODE .EQ. 3 ) THEN
                        L2 = LEN_TRIM( HEADERS( IHDRDATA ) )
                        W1 = MAX( NLEFT, W1, L2 )
                    ELSE
                        L2 = LEN_TRIM( OUTDNAM( J,RCNT ) )
                        W1  = MAX( NLEFT, W1, L2, LN )
                    END IF

C.....................  Build the array of output formats for the data in 
C                       current report
                    TMPFMT = OUTFMT 
                    L2 = LEN_TRIM( TMPFMT )
                    WRITE( OUTFMT, '(A,I2.2,A,I2.2)' ) 
     &                     TMPFMT( 1:L2 ) // 'F', W1, '.', NDECI

C.................  If exponential output format
                ELSE

                    W1 = 0 ! added by GAP 1/17/07

C.....................  Set the left part of the format.  Compare needed width 
C                       with requested width and width of the column header
C                       and units header
                    IF( RPT_%RPTMODE .EQ. 3 ) THEN
                        L2 = LEN_TRIM( HEADERS( IHDRDATA ) )
                        W1 = MAX( NLEFT, W1, L2 )
                    ELSE
                        L2 = LEN_TRIM( OUTDNAM( J,RCNT ) )
                        W1  = MAX( NLEFT, W1, L2, LN )
                    END IF

                    L1 = LEN_TRIM( RPT_%DATAFMT )
                    TMPFMT = OUTFMT
                    L2 = LEN_TRIM( TMPFMT )
                    WRITE( OUTFMT, '(A,I2.2,A,I2.2)' ) 
     &                     TMPFMT( 1:L2 ) // 'E', W1, '.', NDECI

                END IF

C.................  Add delimeter to output formats except for last value
                TMPFMT = OUTFMT
                L1 = LEN_TRIM( TMPFMT )
                IF( J .NE. EDIDX ) THEN
                    IF( L1 .LT. QAFMTL3-8 ) THEN
                        OUTFMT = TMPFMT( 1:L1 ) // ',"' // 
     &                           RPT_%DELIM // '",1X,'
                    ELSE
                        GO TO 988
                    END IF

C.................  Otherwise make sure there is no comma on the end and
C                   add the ending parenthese
                ELSE
                    IF( L1 .LT. QAFMTL3-1 ) THEN      
                        IF( TMPFMT( L1:L1 ) .EQ. ',' ) L1 = L1 - 1
                        IF( RPT_%RPTMODE .EQ. 3 ) THEN
                            OUTFMT = TMPFMT( 1:L1 ) // ',A,1X,A)'
                        ELSE
                            OUTFMT = TMPFMT( 1:L1 ) // ')'
                        END IF

                    ELSE
                        GO TO 988
                    END IF

                END IF
             
C.................  Add next entry to header buffers
                IF( RPT_%RPTMODE .EQ. 3 ) THEN
                    CALL ADD_TO_HEADER( W1, HEADERS( IHDRDATA ),
     &                                  LH, HDRBUF )

                ELSE
                    CALL ADD_TO_HEADER( W1, OUTDNAM( J,RCNT ), 
     &                                  LH, HDRBUF )

                END IF

C.................  Add next entry to units line buffer
                CALL ADD_TO_HEADER( W1, TMPUNIT, LU, UNTBUF )

            END DO

C.............  Units
            IF( RPT_%RPTMODE .EQ. 3 ) THEN

                NWIDTH = 0
                DO I = 1, RPT_%NUMDATA
                    NWIDTH = MAX( NWIDTH, LEN_TRIM( OUTUNIT( I ) ) )
                END DO

                J = LEN_TRIM( HEADERS( IHDRUNIT ) )
                J = MAX( NWIDTH, J )

                CALL ADD_TO_HEADER( J, HEADERS(IHDRUNIT), LH, HDRBUF )

                UNITWIDTH = J + LV

            END IF

        END IF     ! End if any data to output or not

C............................................................................
C.........  Write out the header to the report
C............................................................................

C.........  Write line to separate reports from each other and from metadata
        IF( PDEV == FDEV ) WRITE( FDEV, '(/,A,/)' ) REPEAT( '#', LH )

C.........  If multifile report, write out number of current file
        IF( RPT_%NUMFILES .GT. 1 ) THEN
            WRITE( MESG,94020 ) '# File', FILENUM, 'of', RPT_%NUMFILES
            WRITE( FDEV,93000 ) TRIM( MESG )

        END IF

C.........  User Titles  ....................................................

C.........  Loop through user-defined titles for current report, and write
C           to the report verbatim.
        DO I = 1, RPT_%NUMTITLE

            L2 = LEN_TRIM( TITLES( I,RCNT ) )
            WRITE( FDEV,93000 ) '# ' // TITLES( I,RCNT )( 1:L2 )

        END DO

C.........  Automatic Titles  ...............................................

C.........  Source category processed
        WRITE( FDEV,93000 ) '# Processed as ' // TRIM( CATDESC ) // 
     &                      ' sources'

C.........  The year of the inventory
        WRITE( MESG,94010 ) '# Base inventory year', BYEAR
        WRITE( FDEV,93000 ) TRIM( MESG )

        IF( PYEAR .NE. 0 ) THEN 
            WRITE( MESG,94010 ) '# Projected inventory year', PYEAR
            WRITE( FDEV,93000 ) TRIM( MESG )
        END IF

C.........  Whether projection factors were applied and for what year
        IF( RPT_%USEPRMAT ) THEN
            WRITE( MESG,94010 ) '# Projection factors applied to ' //
     &             'inventory for converting from', PRBYR, 'to', PRPYR
            WRITE( FDEV,93000 ) TRIM( MESG )
        END IF

C.........  Whether multiplicative control factors were applied
        IF( RPT_%USECUMAT ) THEN
            WRITE( FDEV,93000 ) '# Multiplicative control factors ' //
     &             'applied'
        END IF

C.........  Whether a gridding matrix was applied and the grid name
        IF( RPT_%USEGMAT .OR. AFLAG ) THEN
            WRITE( FDEV,93000 ) '# Gridding matrix applied for grid' // 
     &                          TRIM( GRDNM )
        ELSE
            WRITE( FDEV,93000 ) '# No gridding matrix applied'
        END IF

C.........  Whether a speciation matrix was applied and mole- or mass-based
        IF( RPT_%USESLMAT .OR. AFLAG ) THEN
            WRITE( FDEV,93000 ) '# Molar speciation matrix applied'

        ELSE IF( RPT_%USESSMAT ) THEN
            WRITE( FDEV,93000 ) '# Mass speciation matrix applied'

        ELSE
            WRITE( FDEV,93000 ) '# No speciation matrix applied'

        END IF

C.........  What pollutant was used for speciation profiles
        IF( RPT_%BYSPC ) THEN
            L = LEN_TRIM( RPT_%SPCPOL )
            WRITE( FDEV,93000 )'# Speciation profiles for pollutant "'//
     &                          RPT_%SPCPOL( 1:L ) // '"'
        END IF

C.........  Whether hourly data or inventory data were input 
C.........  For hourly data, the time period processed
        IF( RPT_%USEHOUR .OR. AFLAG ) THEN

            K1 = WKDAY( SDATE )
            K2 = WKDAY( EDATE )
            L1 = LEN_TRIM( DAYS( K1 ) )
            L2 = LEN_TRIM( DAYS( K2 ) )

            WRITE( FDEV,93010 ) 
     &            '# Temporal factors applied for episode from'
            WRITE( FDEV,93010 ) '# ' // BLANK5 // 
     &             DAYS( K1 )( 1:L1 ) // ' ' // MMDDYY( SDATE ) //
     &             ' at', STIME, 'to'

            WRITE( FDEV,93010 ) '# ' // BLANK5 // 
     &             DAYS( K2 )( 1:L2 ) // ' '// MMDDYY( EDATE ) //
     &             ' at', ETIME

C.............  Compare average day setting in configuration file with what
C               is actually available in the hourly emissions file.  Give
C               messages and titles accordingly.
            DYSTAT = .FALSE.
            IF( INVPIDX .EQ. 1 ) DYSTAT = .TRUE.

        ELSE
            WRITE( FDEV,93000 ) '# No temporal factors applied'

            DYSTAT = .FALSE.
            IF( RPT_%AVEDAY ) DYSTAT = .TRUE.

        END IF

C.........  Write average day status
        IF( DYSTAT ) THEN
            WRITE( FDEV,93000 ) '# Average day data basis in report'
        ELSE
            WRITE( FDEV,93000 ) '# Annual total data basis in report'
        END IF

C.........  Write normalization status
        IF( RPT_%NORMCELL ) THEN
            L = LEN_TRIM( GRDNM )
            WRITE( FDEV, 93000 ) '# Data divided by grid cell areas '//
     &                           'based on grid ' // GRDNM( 1:L )
        END IF

        IF( RPT_%NORMPOP ) THEN
            WRITE( FDEV, 93020 ) '# Data divided by year ', STCYPOPYR,
     &                           ' population'
        END IF

C.........  The name of the group used to select the data
        IF( RPT_%REGNNAM .NE. ' ' ) THEN

            L = LEN_TRIM( RPT_%REGNNAM )
            WRITE( FDEV,93000 ) '# Region group "'//RPT_%REGNNAM( 1:L )
     &                          // '" applied'

        END IF

C.........  The name of the subgrid used to select the data
        IF( RPT_%SUBGNAM .NE. ' ' ) THEN

            L = LEN_TRIM( RPT_%SUBGNAM )
            WRITE( FDEV,93000 ) '# Subgrid "' // RPT_%SUBGNAM( 1:L )
     &                          // '" applied'

        END IF

C.........  Column headers  .................................................

        IF( RPT_%RPTMODE .NE. 3 ) THEN
C.........  Remove leading spaces from column units
            L = LEN_TRIM( UNTBUF )
            UNTBUF = UNTBUF( 2:L )
            L = L - 1

C.........   Write data output units
            WRITE( FDEV, 93000 ) UNTBUF( 1:L )

        END IF

C.........  Remove leading spaces from column headers
        L = LEN_TRIM( HDRBUF )
        HDRBUF = HDRBUF( 2:L )
        L = L - 1

C.........  Write column headers
        WRITE( FDEV, 93000 ) HDRBUF( 1:L )

C.........  Store previous output file unit number
        PDEV = FDEV

C.........  Successful completion of routine
        RETURN

C.........  Unsuccessful completion of routine
988     WRITE( MESG,94010 ) 'INTERNAL ERROR: Allowable length ' //
     &         'of format statement (', QAFMTL3, ') exceeded' //
     &         CRLF() // BLANK10 // 'at output data field "'//
     &         OUTDNAM( J,RCNT )( 1:LEN_TRIM( OUTDNAM( J,RCNT ) ) ) //
     &         '". Must rerun with fewer outputs or change' // CRLF() //
     &         BLANK10 // 'value of QAFMTL3 in modreprt.f and ' //
     &         'recompile SMOKE library and Smkreport.'
       CALL M3MSG2( MESG )

       CALL M3EXIT( PROGNAME, 0, 0, ' ', 2 )

C******************  FORMAT  STATEMENTS   ******************************

C...........   Formatted file I/O formats............ 93xxx

93000   FORMAT( A )

93010   FORMAT( 10( A, :, 1X, I6.6, :, 1X ) )

93020   FORMAT( A, I4.4, A )

C...........   Internal buffering formats............ 94xxx

94010   FORMAT( 10( A, :, I10, :, 1X ) )

94020   FORMAT( 10( A, :, I3, :, 1X ) )

94620   FORMAT( '(1X,I2.2,"/",I2.2,"/",I4.4,"', A, '")' )

94625   FORMAT( '(1X,I', I2.2, ',"', A, '")' )

94630   FORMAT( '(1X,I', I2.2, '.', I1, ',"', A, '")' )

94635   FORMAT( '(1X,', 'I',I2.2, ',"',A,'", I',I1, ',"',A,'")' )

94640   FORMAT( '(', 3('1X,F', I2.2, '.2,"', A, '",'), 
     &          '1X,F', I2.2, '.2,"', A, '")' )

94642   FORMAT( '(1X,F',I2.2,'.8,"', A,'",1X,F',I2.2,'.8,"',A,'")' )  ! lat/lons

94645   FORMAT( '(I', I1, ',"', A, '")' )

94650   FORMAT( '(I', I3.3, ',"', A, '")' )

C******************  INTERNAL SUBPROGRAMS  *****************************
 
        CONTAINS
 
C.............  This internal subprogram builds the report header
            SUBROUTINE ADD_TO_HEADER( LCOL, LABEL, LHDR, HDRBUF )

C.............  Subprogram arguments
            INTEGER     , INTENT (IN)     :: LCOL   ! width of current column
            CHARACTER(*), INTENT (IN)     :: LABEL  ! column label
            INTEGER     , INTENT (IN OUT) :: LHDR   ! header length
            CHARACTER(*), INTENT (IN OUT) :: HDRBUF ! header

C----------------------------------------------------------------------

C.............  If this is the firstime for this report
            IF( LHDR .EQ. 0 ) THEN

C.................  Initialize header and its length
                HDRBUF = ' ' // '#' // LABEL
                LHDR   = LCOL + LV

C.............  If not a new report...
            ELSE

                HDRBUF = HDRBUF( 1:LHDR ) // RPT_%DELIM // ' ' // LABEL
                LHDR = LHDR + LCOL + LV     ! space included in LV

            END IF
 
            END SUBROUTINE ADD_TO_HEADER

C----------------------------------------------------------------------
C----------------------------------------------------------------------

C.............  This internal subprogram finds the width of the largest
C               integer in an array
            INTEGER FUNCTION INTEGER_COL_WIDTH( NVAL, IARRAY )

C.............  Subprogram arguments
            INTEGER, INTENT (IN) :: NVAL             ! size of array
            INTEGER, INTENT (IN) :: IARRAY( NVAL )   ! integer array

C.............  Local subprogram variables
            INTEGER          M            ! tmp integer value

            CHARACTER(16)    NUMBUF       ! tmp number string

C----------------------------------------------------------------------

C.............  Find maximum integer value in list
            M = MAXVAL( IARRAY )

C.............  Write integer to character string
            WRITE( NUMBUF, '(I16)' ) M

C.............  Find its width
            NUMBUF = ADJUSTL( NUMBUF )
            INTEGER_COL_WIDTH = LEN_TRIM( NUMBUF )
 
            END FUNCTION INTEGER_COL_WIDTH

        END SUBROUTINE WRREPHDR
