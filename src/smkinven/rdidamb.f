
       SUBROUTINE RDIDAMB ( FDEV, NRAWIN, NRAWBV, WKSET, 
     &                      NRAWOUT, EFLAG, NDROP, VDROP )

C***********************************************************************
C  subroutine body starts at line
C
C  DESCRIPTION:
C       This subroutine reads the IDA-formatted mobile files.  It can
C       be called multiple times for multiple files.
C
C  PRECONDITIONS REQUIRED:
C
C  SUBROUTINES AND FUNCTIONS CALLED:
C
C  REVISION  HISTORY:
C
C***************************************************************************
C
C Project Title: Sparse Matrix Operator Kernel Emissions (SMOKE) Modeling
C                System
C File: @(#)$Id$
C
C COPYRIGHT (C) 2000, MCNC--North Carolina Supercomputing Center
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

C...........   Modules for public variables
C.........  This module contains the inventory arrays
        USE MODSOURC

C.........  This module is for mobile-specific data
        USE MODMOBIL

C.........  This module contains the lists of unique inventory information
        USE MODLISTS

C.........  This module contains the arrays for state and county summaries
        USE MODSTCY

C.........  This module contains the information about the source category
        USE MODINFO

        IMPLICIT NONE

C...........   Include files

        INCLUDE 'EMCNST3.EXT'   !  emissions constant parameters
        INCLUDE 'PARMS3.EXT'    !  I/O API parameters
	
C...........   EXTERNAL FUNCTIONS and their descriptions:

        LOGICAL         CHKINT
        LOGICAL         CHKREAL
        CHARACTER*2     CRLF
        INTEGER         ENVINT
        INTEGER         FIND1
        INTEGER         FINDC
        INTEGER         INDEX1
        INTEGER         STR2INT
        REAL            STR2REAL

        EXTERNAL        CHKINT, CHKREAL, CRLF, ENVINT, FIND1, FINDC,
     &                  INDEX1, STR2INT, STR2REAL

C...........   Subroutine arguments. Note that number and amount of dropped
C              VMT is initialied in calling program.

        INTEGER     , INTENT (IN) :: FDEV        ! file unit number
        INTEGER     , INTENT (IN) :: NRAWIN      ! total raw record count
        INTEGER     , INTENT (IN) :: NRAWBV      ! total rec x data var count
        INTEGER     , INTENT (IN) :: WKSET       ! weekly profile interpretation
        INTEGER     , INTENT(OUT) :: NRAWOUT     ! valid raw record count
        INTEGER     , INTENT(OUT) :: NDROP       ! number of records dropped
        REAL        , INTENT(OUT) :: VDROP( MXIDAT ) ! sum of data dropped
        LOGICAL     , INTENT(OUT) :: EFLAG       ! error flag

C...........   Local parameters, indpendent
         INTEGER, PARAMETER :: MXVARFIL = 113 ! maximum data variables in file
         INTEGER, PARAMETER :: MBOTWIDE = 20  ! total width of all data fields
         INTEGER, PARAMETER :: MBNONDWD = 15  ! width of non-data fields

C...........   Local parameters, dependent
         INTEGER, PARAMETER :: LINSIZ  = MBNONDWD + MXVARFIL * MBOTWIDE

C...........   Local parameter arrays
C...........   Start and end positions in the file format of the first set
C              of pollutant fields.
        INTEGER  :: ISINIT( NMBPPOL3 ) = ( / 16,26 / )

        INTEGER  :: IEINIT( NMBPPOL3 ) = ( / 25,35 / )

C...........   Local arrays
        INTEGER          IS( NMBPPOL3 )  ! start position for each pol char
        INTEGER          IE( NMBPPOL3 )  ! end position for each pol char

C...........   Local allocatable arrays
        CHARACTER*50, ALLOCATABLE :: SEGMENT( : ) ! list-formatted strings

C...........   Counters of total number of input records
        INTEGER, SAVE :: NSRCSAV = 0 ! cumulative source count
        INTEGER, SAVE :: NSRCVAR = 0 ! cumulative source x pollutants count

C...........   Local variables

        INTEGER         I, J, K, L, N, V     ! indices

        INTEGER         CYID           ! tmp county code
        INTEGER         ES             ! valid raw record counter
        INTEGER         FIP            ! tmp country/state/county
        INTEGER         ICC            ! tmp country code
        INTEGER         IDROP          ! local dropped raw record counter
        INTEGER         INY            ! inventory year
        INTEGER         IOS            ! I/O status
        INTEGER         IREC           ! record counter
        INTEGER         IVT            ! tmp vehicle type code
        INTEGER, SAVE:: MXWARN         ! maximum number of warnings
        INTEGER         NPVAR          ! number of variables per data
        INTEGER         NSEG           ! number of input segments
        INTEGER         NVAR           ! number of data variables
        INTEGER, SAVE:: NWARN =0       ! number of warnings in this routine
        INTEGER         SS             ! counter for sources
        INTEGER         RWT            ! roadway type
        INTEGER         SCCLEN         ! length of SCC string 
        INTEGER         STID           ! tmp state code
        INTEGER         TPF            ! tmp temporal adjustments setting

        REAL            VAL            ! tmp data value

        LOGICAL    :: FIRSTIME = .TRUE.! true: first time routine called
        LOGICAL       FIXED            ! true: input file is fixed-format
        LOGICAL       INVALID          ! tmp error flag for current record
        LOGICAL       MISSFLAG         ! true: all emissions missing on line

        CHARACTER*20  VIDFMT         ! vehicle type ID format
        CHARACTER*20  RWTFMT         ! roadway type number format
        CHARACTER*300 MESG           ! message buffer
        CHARACTER*500 LINE           ! read buffer for a line

        CHARACTER(LEN=POLLEN3) CCOD  ! character pollutant index to INVDNAM
        CHARACTER(LEN=FIPLEN3) CFIP  ! character FIPS code
        CHARACTER(LEN=VIDLEN3) CIVT  ! tmp vehicle type ID
        CHARACTER(LEN=LNKLEN3) CLNK  ! tmp link ID 
        CHARACTER(LEN=RWTLEN3) CRWT  ! tmp roadway type
        CHARACTER(LEN=SCCLEN3) TSCC  ! tmp source classification code
        CHARACTER(LEN=VTPLEN3) VTYPE ! tmp vehicle type

        CHARACTER*16 :: PROGNAME = 'RDIDAMB'   ! program name

C***********************************************************************
C   Begin body of subroutine RDIDAMB

C.........  Firstime routine is called, get the number of warnings
        IF( FIRSTIME ) THEN
            MXWARN = ENVINT( WARNSET, ' ', 100, IOS )
            FIRSTIME = .FALSE.
        END IF

C.........  Reinitialize for multiple subroutine calls
        ICC   = -9
        IDROP = 0
        INY   = 0
        NVAR  = 0
        FIXED = .TRUE.

C.........  Create formats
        WRITE( VIDFMT, '("(I",I2.2,")")' ) VIDLEN3
        WRITE( RWTFMT, '("(I",I2.2,")")' ) RWTLEN3

C.........  Make sure the file is at the beginning
        REWIND( FDEV )

C........................................................................
C.............  Head of the main read loop  .............................
C........................................................................

        SS   = NSRCSAV
        ES   = NSRCVAR
        IREC = 0
        TPF  = MTPRFAC * WKSET
        CLNK = ' '
        DO

            INVALID = .FALSE.

            READ( FDEV, 93000, END=12, IOSTAT=IOS ) LINE
            IREC = IREC + 1
 
            IF ( IOS .GT. 0 ) THEN

                EFLAG = .TRUE.
                WRITE( MESG, 94010)
     &              'I/O error', IOS, 'reading inventory '//
     &              'file at line', IREC
                CALL M3MESG( MESG )

            END IF
	
            L = LEN_TRIM( LINE )  ! store width of line and check

C.............  Skip blank lines
            IF( L .EQ. 0 ) CYCLE

C.............  Scan for header lines and check to ensure all are set 
C               properly
            CALL GETHDR( MXVARFIL, .TRUE., .TRUE., .TRUE., 
     &                   LINE, ICC, INY, NVAR, IOS )

C.............  Interpret error status
            IF( IOS .EQ. 4 ) THEN
                WRITE( MESG,94010 ) 
     &                 'Maximum allowed data variables ' //
     &                 '(MXVARFIL=', MXVARFIL, CRLF() // BLANK10 //
     &                 ') exceeded in input file'
                CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )

            ELSE IF( IOS .GT. 0 ) THEN
                EFLAG = .TRUE.

            END IF


C.............  If a header line was encountered...
            IF ( IOS .GE. 0 ) THEN

C.................  Check if types is set to determine free or fixed format
                IF ( LINE(2:5) .EQ. 'TYPE' ) THEN

C.....................  Try to find activity in name of data, otherwise, assume
C                       emissions
                    MESG = LINE
                    CALL UPCASE( MESG )
                    I = INDEX( MESG, 'ACTIVITY' ) 
                    IF( I .GT. 0 ) THEN
                        FIXED = .FALSE.
                    END IF
                END IF

C.................  Go to next line
                CYCLE

            END IF

C.............  Allocate memory for line segments if not already done
            IF( .NOT. ALLOCATED( SEGMENT ) ) THEN

C.................  Compute the number of segments - different depending on
C                   whether pollutant or activity
	        NSEG = NMBVAR3
                DO V = 1, NVAR
                    J = DATPOS( V )
                    IF( INVSTAT( J ) .EQ.  1 ) NSEG = NSEG + NPPOL
                    IF( INVSTAT( J ) .EQ. -1 ) NSEG = NSEG + NPACT
                END DO

                ALLOCATE( SEGMENT( NSEG ), STAT=IOS )
                CALL CHECKMEM( IOS, 'SEGMENT', PROGNAME )
                SEGMENT = ' '  ! Array

            END IF

C.............  Separate lines into parts for fixed format
            IF ( FIXED ) THEN

C.................  Initialize fixed-format field positions
                IS = ISINIT - MBOTWIDE  ! array
                IE = IEINIT - MBOTWIDE  ! array

                SEGMENT( 1 ) = ADJUSTL( LINE( 1:2  ) )
                SEGMENT( 2 ) = ADJUSTL( LINE( 3:5  ) )
                SEGMENT( 3 ) = ADJUSTL( LINE( 6:15 ) )

                K = 3
                DO V = 1, NVAR

                    DO I = 1, NPPOL
                        K = K + 1
                        IS( I ) = IS( I ) + MBOTWIDE
                        IE( I ) = IE( I ) + MBOTWIDE

                        SEGMENT( K ) = LINE( IS( I ):IE( I ) )

                    END DO

                END DO

C.............  Separate line in to parts for list format
            ELSE

                CALL PARSLINE( LINE, NSEG, SEGMENT )

            END IF

C.............  Check state/county codes, error for missing
            IF( .NOT. CHKINT( SEGMENT( 1 ) ) .OR. 
     &          .NOT. CHKINT( SEGMENT( 2 ) ) .OR.
     &          SEGMENT( 1 ) .EQ. ' '        .OR.
     &          SEGMENT( 2 ) .EQ. ' '             ) THEN
                EFLAG = .TRUE.
                WRITE( MESG,94010 ) 'ERROR: State and/or county ' //
     &                 'code is non-integer or missing at line', IREC
                CALL M3MESG( MESG )
            END IF

C.............  Determine if SCC has proper length
            SCCLEN = LEN_TRIM( SEGMENT( 3 ) )

            IF ( SCCLEN .NE. 10 ) THEN   ! check if SCC is 10 char. wide
                EFLAG = .TRUE.
                WRITE( MESG, 94010 )
     &	                   'SCC not 10 characters wide on line ', IREC
                CALL M3MESG( MESG )
            END IF

C.............  Make sure that all of the needed real values are real...

C.............  Emissions or activity and associated data
            K = 3
            DO V = 1, NVAR

                J = DATPOS( V )
                IF( INVSTAT( J ) .EQ.  1 ) NPVAR = NPPOL
                IF( INVSTAT( J ) .EQ. -1 ) NPVAR = NPACT

                MISSFLAG = .TRUE.
                DO N = 1, NPVAR

                    K = K + 1

                    IF( .NOT. CHKREAL( SEGMENT( K ) ) ) THEN

                        EFLAG = .TRUE.
                        L = LEN_TRIM( TMPNAM( V ) )
                        WRITE( MESG,94010 ) 
     &                     'ERROR: Inventory data for "' //
     &                     TMPNAM( V )( 1:L ) // '" are not a number '//
     &                     'or have bad formatting at line', IREC
                        CALL M3MESG( MESG )

                    END IF

                    IF( SEGMENT( K ) .NE. ' ' ) MISSFLAG = .FALSE.

                END DO

                IF( NWARN .LT. MXWARN .AND. MISSFLAG ) THEN

                    L = LEN_TRIM( TMPNAM( V ) )
                    WRITE( MESG,94010 ) 'WARNING: All emissions ' //
     &                     'data for ' // TMPNAM( V )( 1:L ) //  
     &                     ' are missing at line', IREC
                    CALL M3MESG( MESG )
                    NWARN = NWARN + 1
                    SEGMENT( K ) = '0.'

                END IF

            END DO

C.............  If there has been an error, do not try to store any of the
C               records.  Instead  go to next line of file.
            IF( EFLAG ) CYCLE
       
C.............  Now use the file format definition to parse the LINE into
C               the various data fields...
            
            FIP  = ICC * 100000 + 1000 * STR2INT( SEGMENT( 1 ) ) +
     &             STR2INT( SEGMENT( 2 ) )

            TSCC = SEGMENT( 3 )

C.............  Ensure vehicle type code from SCC is an integer
            IF( .NOT. CHKINT( TSCC( 3:6 ) ) ) THEN
	          EFLAG = .TRUE.
	          INVALID = .TRUE.
                WRITE( MESG, 94010 )
     &	         'ERROR: Vehicle type "' // TSCC( 3:6 ) // 
     &             '" not found in list of valid types at line', IREC
                CALL M3MESG( MESG )
                IVT = 0
	          J = 0

C.............  If an integer, match with unsorted integer list
            ELSE
                IVT = STR2INT( TSCC( 3:6 ) )
                J   = -1 
                DO J = 1, NVTYPE
                    IF( IVT .EQ. IVTIDLST( J ) ) EXIT
                END DO
                VTYPE = CVTYPLST( J )

            END IF

C.............  Ensure that vehicle type is valid
            IF ( J .LT. 0 ) THEN 
                EFLAG = .TRUE.
	          INVALID = .TRUE.
                WRITE( MESG, 94010 )
     &	         'ERROR: Vehicle type "' // TSCC( 3:6 ) //
     &             '" not found in list of valid types at line', IREC
                CALL M3MESG( MESG )

            END IF

C.............  Ensure road class code from SCC is an integer
            IF( .NOT. CHKINT( TSCC( 8:10 ) ) ) THEN
	          EFLAG = .TRUE.
	          INVALID = .TRUE.
	          WRITE( MESG, 94010 )
     &                 'ERROR: Road class "' // TSCC( 8:10 ) //
     &                 '" is not a valid integer at line', IREC
	          CALL M3MESG( MESG )
                  RWT = 0
	          J = 0

	      ELSE
	          RWT = STR2INT( TSCC( 8:10 ) ) 
                  J = FIND1( RWT, NRCLAS, AMSRDCLS )

	      END IF
 
C.............  Ensure that road class is valid and convert from road class
C               to roadway type
            IF ( J .LT. 0 ) THEN
                EFLAG = .TRUE.
	          INVALID = .TRUE.
                WRITE( MESG, 94010 )
     &	         'ERROR: Road class "' // TSCC( 8:10 ) // 
     &             '" not found in list of valid classes at line', IREC
                CALL M3MESG( MESG )

            ELSE IF( J .GT. 0 ) THEN
                RWT = RDWAYTYP( J )

            END IF

C.............  Sum emissions for invalid records
            IF ( INVALID ) THEN

                IDROP = IDROP + 1
                DO V = 1, NVAR
	              K = NMBVAR3 + ( V-1 ) * NPVAR + 1
                    VDROP( V ) = VDROP( V ) + STR2REAL( SEGMENT( K ) )
                END DO
                CYCLE    ! To next input line

            END IF
	
C.............  Create string source characteristics. Pad with zeros,
C               if needed
C.............  Make adjustments to pad with zeros, if needed
            WRITE( CFIP,94120 ) FIP
            CALL PADZERO( CFIP )
            CALL PADZERO( TSCC )
            WRITE( CRWT,RWTFMT ) RWT
            WRITE( CIVT,VIDFMT ) IVT

C.............  Store source characteristics if dimension is okay
            SS = SS + 1

            IF( SS .LE. NRAWIN ) THEN
                IFIPA  ( SS ) = FIP
                IRCLASA( SS ) = RWT
                IVTYPEA( SS ) = IVT
                CLINKA ( SS ) = CLNK
                CVTYPEA( SS ) = VTYPE
                TPFLGA ( SS ) = TPF
                INVYRA ( SS ) = INY
                CSCCA  ( SS ) = TSCC
                XLOC1A ( SS ) = BADVAL3
                YLOC1A ( SS ) = BADVAL3
                XLOC2A ( SS ) = BADVAL3
                YLOC2A ( SS ) = BADVAL3
            END IF 

            K = 3              
            DO V = 1, NVAR

                ES = ES + 1

                J = DATPOS( V )
                IF( INVSTAT( J ) .EQ.  1 ) NPVAR = NPPOL
                IF( INVSTAT( J ) .EQ. -1 ) NPVAR = NPACT

                IF ( ES .LE. NRAWBV ) THEN

                    INDEXA ( ES ) = ES
                    INRECA ( ES ) = SS                    

                    WRITE( CCOD,94125 ) J

                    CALL BLDCSRC( CFIP, CRWT, CLNK, CIVT, TSCC, ' ', 
     &                            ' ', CCOD, CSOURCA( ES ) )

C.....................  Store main data value
                    K = K + 1
                    VAL = STR2REAL( SEGMENT( K ) )
                    POLVLA ( ES,1 ) = INVDCNV( J ) * VAL

C.....................  Store related values (if any)
                    DO N = 2, NPVAR

                        K = K + 1
                        VAL = STR2REAL( SEGMENT( K ) )

                        POLVLA ( ES,N ) = VAL

                    END DO

                END IF

            END DO     ! loop through data variables
	
        END DO             ! end of loop for reading input file
              
12      CONTINUE           ! end of read on input file

C.........  Update saved cumulative counts
        NSRCSAV = SS       !  source
        NSRCVAR = ES       !  source*pollutant

        NDROP   = NDROP + IDROP

C.........  Write message if overflow occurred
        IF( NSRCSAV .GT. NRAWIN ) THEN

            EFLAG = .TRUE.
            MESG = 'INTERNAL ERROR: Source memory allocation ' //
     &             'insufficient for IDA inventory'
            CALL M3MSG2( MESG )

        END IF

        IF( NSRCVAR .GT. NRAWBV ) THEN  ! Check for memory overflow

            WRITE( MESG, 94010 )
     &        'INTERNAL ERROR: Number of valid src x variables ' //
     &        'encountered: ', NRAWOUT, CRLF() // BLANK5 //
     &        'Maximum number of raw records allowed: ', NRAWBV

            CALL M3MSG2( MESG )
            CALL M3EXIT( PROGNAME, 0, 0, ' ', 2 )      

        ELSE
            NRAWOUT = NSRCVAR

        END IF
	
C.........  Deallocate local allocatable arrays 
        DEALLOCATE( TMPNAM, DATPOS, SEGMENT )

C.........  Return from subroutine 
        RETURN

C******************  FORMAT  STATEMENTS   ******************************

C...........   Formatted file I/O formats............ 93xxx

93000   FORMAT( A )

C...........   Internal buffering formats............ 94xxx

94010   FORMAT( 10( A, :, I8, :, 1X ) )

94120   FORMAT( I6.6 )

94125   FORMAT( I5 )

        END SUBROUTINE RDIDAMB
