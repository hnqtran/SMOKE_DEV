
        PROGRAM GRDMAT

C***********************************************************************
C  program body starts at line 152
C
C  DESCRIPTION:
C     Creates the gridding matrix for any source category and creates the
C     "ungridding" matrix for mobile sources.
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

C...........   MODULES for public variables
C...........   This module is the source inventory arrays
        USE MODSOURC

C...........   This module contains the cross-reference tables
        USE MODXREF

C.........  This module contains the information about the source category
        USE MODINFO

        IMPLICIT NONE

C...........   INCLUDES:
        
        INCLUDE 'EMCNST3.EXT'   !  emissions constant parameters
        INCLUDE 'PARMS3.EXT'    !  I/O API parameters
        INCLUDE 'IODECL3.EXT'   !  I/O API function declarations
        INCLUDE 'FDESC3.EXT'    !  I/O API file description data structures.

C...........   EXTERNAL FUNCTIONS and their descriptions:
        
        CHARACTER*2            CRLF
        LOGICAL                DSCM3GRD
        LOGICAL                ENVYN
        CHARACTER(LEN=IODLEN3) GETCFDSC
        INTEGER                PROMPTFFILE
        CHARACTER*16           PROMPTMFILE
        CHARACTER*16           VERCHAR
   
        EXTERNAL  CRLF, ENVYN, DSCM3GRD, GETCFDSC, PROMPTFFILE, 
     &            PROMPTMFILE, VERCHAR

C...........   LOCAL PARAMETERS
        CHARACTER*50  SCCSW          ! SCCS string with version number at end

        PARAMETER   ( SCCSW   = '@(#)$Id$'
     &              )

C...........   LOCAL VARIABLES and their descriptions:

C...........   Gridding Matrix

        INTEGER, ALLOCATABLE :: GMAT( : ) ! Contiguous gridding matrix

C...........   Ungridding Matrix

        INTEGER, ALLOCATABLE :: UMAT( : ) ! Contiguous ungridding matrix

C.........  Array that contains the names of the inventory variables needed 
C           for this program
        CHARACTER(LEN=IOVLEN3) IVARNAMS( MXINVARR )

C...........   File units and logical/physical names
c        INTEGER         ADEV    !  for adjustments file
        INTEGER         LDEV    !  log-device
        INTEGER         KDEV    !  for link defs file
        INTEGER         GDEV    !  for surrogate coeff file
        INTEGER      :: MDEV = 0!  mobile sources codes file
        INTEGER      :: SDEV = 0!  ASCII part of inventory unit no.
        INTEGER         XDEV    !  for surrogate xref  file

        CHARACTER*16    ANAME   !  logical name for ASCII inventory input file
        CHARACTER*16    ENAME   !  logical name for i/o api inventory input file
        CHARACTER*16    GNAME   !  logical name for grid matrix output file
        CHARACTER*16    UNAME   !  logical name for ungrid matrix output file

C...........   Other local variables
        
        INTEGER         L1, K     !  indices and counters.

        INTEGER         CMAX    ! max number srcs per cell
        INTEGER         CMIN    ! min number srcs per cell
        INTEGER         CMAXU   ! max number cells per source
        INTEGER         CMINU   ! min number cells per source
        INTEGER         ENLEN   ! length of the emissions inven name
        INTEGER         IOS     ! i/o status
        INTEGER         NK      ! Number of gridding coefficients 
        INTEGER         NKU     ! Number of ungridding coefficients
        INTEGER         NINVARR ! no. of inventory characteristics
        INTEGER         NCOLS   ! no. of grid columns
        INTEGER         NGRID   ! no. of grid cells
        INTEGER         NMATX   ! no cell-source intersections
        INTEGER         NROWS   ! no. of grid rows
        INTEGER         MXCSRC  ! max no cells per source
        INTEGER         MXSCEL  ! max no sources per cell

        REAL            CAVG   ! average number sources per cell
        REAL            XCELL  ! Cell size, X direction
        REAL            XCENT  ! Center of coordinate system
        REAL            XORIG  ! X origin
        REAL            YCELL  ! Cell size, Y direction
        REAL            YCENT  ! Center of coordinate system
        REAL            YORIG  ! Y origin

        LOGICAL      :: AFLAG   = .FALSE.  ! true: use grid adjustments file
        LOGICAL      :: DFLAG   = .FALSE.  ! true: use link defs file
        LOGICAL      :: UFLAG   = .FALSE.  ! true: create ungridding matrix

        CHARACTER*16            COORD    !  coordinate system name
        CHARACTER*16            COORUNIT !  coordinate system projection units
        CHARACTER*16            GRDNM    !  grid name
        CHARACTER*16            SRGFMT   !  surrogates format
        CHARACTER*80            GDESC    !  grid description
        CHARACTER*300           MESG     !  message buffer

        CHARACTER(LEN=IODLEN3)  IFDESC2, IFDESC3 !  fields 2 & 3 from PNTS FDESC

        CHARACTER*16 :: PROGNAME = 'GRDMAT'   !  program name

C***********************************************************************
C   begin body of program GRDMAT
        
        LDEV = INIT3()

C.........  Write out copywrite, version, web address, header info, and prompt
C           to continue running the program.
        CALL INITEM( LDEV, SCCSW, PROGNAME )

C.........  Get environment variables that control this program
        AFLAG = ENVYN( 'GRDMAT_ADJUST',
     &                 'Use grid adjustments file or not', 
     &                 .FALSE., IOS )

        DFLAG = ENVYN( 'GRDMAT_LINKDEFS',
     &                 'Use link definitions file or not', 
     &                 .FALSE., IOS )

C.........  Temporary section for disallowing optional files
        IF( AFLAG ) THEN
            MESG = 'NOTE: Grid adjustments file is not supported yet!'
            CALL M3MSG2( MESG )
            AFLAG = .FALSE.
        END IF

        IF( DFLAG ) THEN
            MESG = 'NOTE: Link definitions file is not supported yet!'
            CALL M3MSG2( MESG )
            DFLAG = .FALSE.
        END IF

C.........  Set source category based on environment variable setting
        CALL GETCTGRY

C.........  Get inventory file names given source category
        CALL GETINAME( CATEGORY, ENAME, ANAME )

C.........   Get file names and open files
        ENAME = PROMPTMFILE( 
     &          'Enter logical name for the I/O API INVENTORY file',
     &          FSREAD3, ENAME, PROGNAME )
        ENLEN = LEN_TRIM( ENAME )

c        IF( AFLAG ) 
c     &  ADEV = PROMPTFFILE( 
c     &           'Enter logical name for ADJUSTMENT FACTORS file',
c     &           .TRUE., .TRUE., CRLF // 'ADJUST', PROGNAME )

C.........  Get additional files for non-point sources
        IF( CATEGORY .NE. 'POINT' ) THEN

            SDEV = PROMPTFFILE( 
     &           'Enter logical name for the ASCII INVENTORY file',
     &           .TRUE., .TRUE., ANAME, PROGNAME )

            XDEV = PROMPTFFILE( 
     &           'Enter logical name for GRIDDING SURROGATE XREF file',
     &           .TRUE., .TRUE., CRL // 'GREF', PROGNAME )

            GDEV = PROMPTFFILE( 
     &           'Enter logical name for SURROGATE COEFFICIENTS file',
     &           .TRUE., .TRUE., CRL // 'GPRO', PROGNAME )

            IF( CATEGORY .EQ. 'MOBILE' ) THEN
                MESG = 'Enter logical name for MOBILE CODES file'
                MDEV = PROMPTFFILE( MESG, .TRUE., .TRUE., 'MCODES',
     &                              PROGNAME )

                IF( DFLAG ) KDEV = PROMPTFFILE( 
     &               'Enter logical name for LINK DEFINITIONS file',
     &               .TRUE., .TRUE., CRL // 'GLNK', PROGNAME )

            END IF  ! End of mobile file opening

        END IF  ! End of non-point file opening

C.........  Get header description of inventory file, error if problem
        IF( .NOT. DESC3( ENAME ) ) THEN
            MESG = 'Could not get description of file "' //
     &             ENAME( 1:ENLEN ) // '"'
            CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )

C.........  Otherwise, store source-category-specific header information, 
C           including the inventory pollutants in the file (if any).  Note that 
C           the I/O API head info is passed by include file and the
C           results are stored in module MODINFO.
        ELSE

            CALL GETSINFO

C.............  Store non-category-specific header information
            IFDESC2 = GETCFDSC( FDESC3D, '/FROM/', .TRUE. )
            IFDESC3 = GETCFDSC( FDESC3D, '/VERSION/', .TRUE. )

        END IF

C.........  Set inventory variables to read for all source categories
        IVARNAMS( 1 ) = 'IFIP'

        SELECT CASE ( CATEGORY )

        CASE ( 'AREA' )
            NINVARR = 3
            IVARNAMS( 2 ) = 'CSCC'
            IVARNAMS( 3 ) = 'CSOURC'

        CASE ( 'MOBILE' )
            NINVARR = 10
            IVARNAMS( 2 ) = 'IRCLAS'
            IVARNAMS( 3 ) = 'IVTYPE'
            IVARNAMS( 4 ) = 'CSOURC'
            IVARNAMS( 5 ) = 'CSCC'
            IVARNAMS( 6 ) = 'CLINK'
            IVARNAMS( 7 ) = 'XLOC1'
            IVARNAMS( 8 ) = 'YLOC1'
            IVARNAMS( 9 ) = 'XLOC2'
            IVARNAMS( 10 ) = 'YLOC2'

        CASE ( 'POINT' )
            NINVARR = 3
            IVARNAMS( 2 ) = 'XLOCA'
            IVARNAMS( 3 ) = 'YLOCA'

        END SELECT

C.........  Allocate memory for and read in required inventory characteristics
        CALL RDINVCHR( CATEGORY, ENAME, SDEV, NSRC, NINVARR, IVARNAMS )

C.........  For non-point sources, need to read in the surrogates (which will
C           set the grid information), read in the gridding cross reference, and
C           assign the cross-reference information to the sources.
        IF( CATEGORY .NE. 'POINT' ) THEN

C.............  Build unique lists of SCCs and country/state/county codes
C               from the inventory arrays
            CALL GENUSLST

C.............  For mobile sources, read the mobile codes
            IF( MDEV .GT. 0 ) CALL RDMVINFO( MDEV )

            CALL M3MSG2( 'Reading gridding cross-reference file...' )

C.............  Read the gridding cross-reference
            CALL RDGREF( XDEV )

            CALL M3MSG2( 'Reading gridding surrogates file...' )

C.............  Read the surrogates header and check that it is consistent
C               with the grid description from the DSCM3GRD call
C.............  Also, obtain the format of the file.
            CALL RDSRGHDR( GDEV, SRGFMT, GRDNM, GDESC, XCENT, YCENT, 
     &                     XORIG, YORIG, XCELL, YCELL, NCOLS, NROWS )

C.............  Allocate memory for and read the gridding surrogates file
            CALL RDSRG( GDEV, SRGFMT, XCENT, YCENT, XORIG, 
     &                  YORIG, XCELL, YCELL, NCOLS, NROWS )

C..............  Read the link definition file
c            CALL RDLNKDEF( )

C.............  Allocate memory for indices to surrogates tables for each source
            ALLOCATE( SRGIDPOS( NSRC ), STAT=IOS )
            CALL CHECKMEM( IOS, 'SRGIDPOS', PROGNAME )
            ALLOCATE( SGFIPPOS( NSRC ), STAT=IOS )
            CALL CHECKMEM( IOS, 'SGFIPPOS', PROGNAME )

C.............  Assigns the index of the surrogate to each source (stored
C               in SRGIDPOS passed through MODXREF)
            CALL ASGNSURG

C.........  For point sources, must get the grid information from the 
C           Models-3 grid information file
        ELSE

C.........  Get grid name from the environment and read grid parameters
            IF( .NOT. DSCM3GRD( GRDNM, GDESC, COORD, GDTYP3D, COORUNIT,
     &                          P_ALP3D, P_BET3D, P_GAM3D, XCENT3D, 
     &                          YCENT3D, XORIG3D, YORIG3D, XCELL3D,
     &                          YCELL3D, NCOLS, NROWS, NTHIK3D ) ) THEN

                MESG = 'Could not get Models-3 grid description.'
                CALL M3EXIT( PROGNAME, 0, 0, MESG, 2 )
            END IF

        END IF   ! If point sources or not

C.........  Compute total number of grid cells
        NGRID = NCOLS * NROWS

C.........  Write message stating grid name and description
        L1 = LEN_TRIM( GRDNM )
        MESG = 'NOTE: Grid "' // GRDNM( 1:L1 ) // 
     &         '" set; defined as' // CRLF() // BLANK10 // GDESC
        CALL M3MSG2( MESG )

C.........  Depending on source category, convert coordinates, determine size
C           of gridding matrix, and allocate gridding matrix.

        SELECT CASE( CATEGORY )

        CASE( 'AREA' )

C.............  Determine sizes for allocating area gridding matrix 
            CALL SIZGMAT( CATEGORY, NSRC, NGRID, MXSCEL, MXCSRC, NMATX )

C.............  Allocate memory for mobile source gridding matrix
            ALLOCATE( GMAT( NGRID + 2*NMATX ), STAT=IOS )
            CALL CHECKMEM( IOS, 'GMAT', PROGNAME )

        CASE( 'MOBILE' )

C.............  Convert mobile source coordinates from lat-lon to output grid
            CALL CONVRTXY( NSRC, GDTYP3D, P_ALP3D, P_BET3D, P_GAM3D,
     &                     XCENT3D, YCENT3D, XLOC1, YLOC1 )
            CALL CONVRTXY( NSRC, GDTYP3D, P_ALP3D, P_BET3D, P_GAM3D, 
     &                     XCENT3D, YCENT3D, XLOC2, YLOC2 )

C.............  Determine sizes for allocating mobile gridding matrix 
            CALL SIZGMAT( CATEGORY, NSRC, NGRID, MXSCEL, MXCSRC, NMATX )
 
C.............  Allocate memory for mobile source gridding matrix
            ALLOCATE( GMAT( NGRID + 2*NMATX ), STAT=IOS )
            CALL CHECKMEM( IOS, 'GMAT', PROGNAME )

C.............  Allocate memory for mobile source ungridding matrix
            ALLOCATE( UMAT( NSRC + 2*NMATX ), STAT=IOS )
            CALL CHECKMEM( IOS, 'UMAT', PROGNAME )

        CASE( 'POINT' )

C.............  Convert point source coordinates from lat-lon to output grid
            CALL CONVRTXY( NSRC, GDTYP3D, P_ALP3D, P_BET3D, P_GAM3D, 
     &                     XCENT3D, YCENT3D, XLOCA, YLOCA )

C.............  Set the number of source-cell intersections
            NMATX = NSRC

C.............  Allocate memory for point source gridding matrix
            ALLOCATE( GMAT( NGRID + NSRC ), STAT=IOS )
            CALL CHECKMEM( IOS, 'GMAT', PROGNAME )

        END SELECT

C.........  Get file names; open output gridding matrix (and ungridding matrix
C           for mobile) using grid characteristics from DSCM3GRD() above        
        CALL OPENGMAT( NMATX, IFDESC2, IFDESC3, GNAME, UNAME )
        UFLAG = ( UNAME .NE. 'NONE' )

        CALL M3MSG2( 'Generating gridding matrix...' )

C.........  Generate gridding matrix for given source category, and write it
C           out.  It is necessary to write it out while in the subroutine,
C           because of the type transformation from real to integer that
C           is done so the sparse i/o api format can be used.

        SELECT CASE( CATEGORY )

        CASE( 'AREA' )

            CALL GENAGMAT( GNAME, MXSCEL, NSRC, NGRID, NMATX, 
     &                     GMAT( 1 ), GMAT( NGRID+1 ), 
     &                     GMAT( NGRID+NMATX+1 ), NK, CMAX, CMIN )

        CASE( 'MOBILE' )

            CALL GENMGMAT( GNAME, UNAME, MXSCEL, MXCSRC, NSRC, NGRID, 
     &                     NMATX, GMAT( 1 ), GMAT( NGRID+1 ), 
     &                     GMAT( NGRID+NMATX+1 ), UMAT( 1 ), 
     &                     UMAT( NSRC+1 ), UMAT( NSRC+NMATX+1 ),
     &                     NK, CMAX, CMIN, NKU, CMAXU, CMINU )

        CASE( 'POINT' )
   
            CALL GENPGMAT( GNAME, NSRC, NGRID, XLOCA, YLOCA, 
     &                     GMAT( 1 ), GMAT( NGRID+1 ), NK, CMAX, CMIN )

        END SELECT

C.........  Report statistics for gridding matrix

        CAVG = FLOAT( NK ) / FLOAT( NGRID )
        CALL M3MSG2( 'GRIDDING-MATRIX statistics:' )

        WRITE( MESG,94010 ) 
     &         'Total number of coefficients   :', NK   ,
     &         CRLF() // BLANK5 //
     &         'Max  number of sources per cell:', CMAX,
     &         CRLF() // BLANK5 //
     &         'Min  number of sources per cell:', CMIN

        L1 = LEN_TRIM( MESG )
        WRITE( MESG,94020 ) MESG( 1:L1 ) // CRLF() // BLANK5 //
     &         'Mean number of sources per cell:', CAVG

        CALL M3MSG2( MESG )

C.........  Report statistics for ungridding matrix
        IF( UFLAG ) THEN

            CAVG = FLOAT( NKU ) / FLOAT( NSRC )
            CALL M3MSG2( 'UNGRIDDING-MATRIX statistics:' )

            WRITE( MESG,94010 ) 
     &        'Total number of coefficients   :', NKU ,
     &        CRLF() // BLANK5 //
     &        'Max  number of cells per source:', CMAXU,
     &        CRLF() // BLANK5 //
     &        'Min  number of cells per source:', CMINU

            WRITE( MESG, 94020 ) MESG( 1:LEN_TRIM( MESG ) ) //
     &        CRLF() // BLANK5 //
     &        'Mean number of cells per source:', CAVG

            CALL M3MSG2( MESG )

        END IF 

C.........  End of program
      
        CALL M3EXIT( PROGNAME, 0, 0, ' ', 0 )

C******************  FORMAT  STATEMENTS   ******************************

C...........   Informational (LOG) message formats... 92xxx

92000   FORMAT( 5X, A )

92010   FORMAT( 5X, A, :, I12 )

92020   FORMAT( 5X, A, :, F17.4 )


C...........   Formatted file I/O formats............ 93xxx

93000   FORMAT( A )

93010   FORMAT( A16 )


C...........   Internal buffering formats............ 94xxx

94010   FORMAT( 10( A, :, I10, :, 1X ) )

94020   FORMAT( A, :, F8.2 )

        END PROGRAM GRDMAT


