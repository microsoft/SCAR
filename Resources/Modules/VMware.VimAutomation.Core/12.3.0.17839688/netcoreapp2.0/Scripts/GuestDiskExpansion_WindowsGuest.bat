:: *************************************************************************
:: Copyright 2009 VMware, Inc.  All rights reserved.
:: *************************************************************************

::
:: Disk resize script for Windows family guest OS
:: This script is used by Set-HardDisk cmdlet to resize hard disk in the guest OS
::
:: PARAMETERS
::	%1 - Bus Number
::		The number of the controller that targer hard disk is attached to. 
::    In the Windows OS is displayed as Bus. Ignored since it's missing in some OS
::	%2 - Unit number
::		Unit number of the hard disk on the controller. In the Windows OS is displayed as Target ID.
::    Integer value from the range 0 - 15.
::	%3 - Partition
::		The name of the partition to be resized. For Windows guest Os this is the drive letter.
::		If empty string ("") is passed the last partition of the disk is resized. ( i.e. "D")
::	%4 - ControllerType
::		The type of the controller that targer hard disk is attached to. 
::
:: USAGE
::    The following example will resize last partition of the disk attached to bus 0 and unit number 1
::
:: GuestDiskExpansion_WindowsGuest.bat 0 1 ""
::
::   The following example will resize "D" drive of the disk attached to bus 0 and unit number 0
::
:: GuestDiskExpansion_WindowsGuest.bat 0 0 "D"
::

@echo off
SETLOCAL ENABLEDELAYEDEXPANSION

::::::::::::::  Variables  ::::::::::::::::
set /a busnumber=%1
set ctrl_type=SCSI
if not [%4]==[""] set ctrl_type=%4
set disk_id=%ctrl_type%:%2
set disk_name=%ctrl_type%:%1:%2
if not [%3]==[""] set partition_id=%3
set script_file=%TEMP%\diskpart_script.txt
set list_output_file=%TEMP%\diskpart_disk_list.txt
set detail_output_file=%TEMP%\diskpart_disk_detail.txt

:: Run diskmgmt msc to ensure diskpart service is laready running
start diskmgmt.msc

::::::::::::::  Rescan for disk and volumes ::::::::::::::::
echo rescan > %script_file%
diskpart /s %script_file% > %list_output_file%
if errorlevel 1 (
   type %list_output_file%
   call :cleanup
   exit %errorlevel%
)

::::::::::::::  Get hard disk list  ::::::::::::::::
echo list disk > %script_file%
diskpart /s %script_file% > %list_output_file%
if errorlevel 1 (
   type %list_output_file%
   call :cleanup
   exit %errorlevel%
)

::::::::::::::  Get each hard disk details and find needed one ::::::::::::::::
for /F "tokens=2 skip=7" %%A in (%list_output_file%) do (   
   set disk_name=%%A
   :: For Windows7 and Windows2008 first hard disk details are on line 8, while in 
   :: Windows XP and Windows 2003 they are on line 9, and line 8 contains only '-' characters
   if not "!disk_name:~0,1!"=="-" (
	   echo select disk %%A > %script_file%
	   echo detail disk >> %script_file%
	   diskpart /s %script_file% > %detail_output_file%
	   if errorlevel 1 (
		  type %detail_output_file%
		  call :cleanup
		  exit %errorlevel%
	   )

	   for /F "tokens=1,2 skip=9 delims=:" %%M in (%detail_output_file%) do ( 
		  if "%%M"=="Type   " set disk_type=%%N
		  if "%%M"=="Target " set disk_target=%%N 
	   )

	   :: Trim vars%temp
	   set disk_type=!disk_type:~1,10!
	   set disk_target=!disk_target:~1,10!
	   set disk_target=!disk_target:~0,-1!

	   if "%disk_id%"=="!disk_type!:!disk_target!" ( 
		  
		  if not defined disk_number (
			 set disk_number=%%A
			 set disk_number.%%A=%%A  
		  ) else (
			 if not defined partition_id (
				:: if there are more than 1 disk with same target we need partition to locate it
				echo Specified disk %disk_name% can not be located since its not unique defined. Please specify partition.
				call :cleanup
				exit 1
			 ) else (
				set disk_number.%%A=%%A  
			 )
		  )
	   ) 
	)   
)

:disk_found
if not defined disk_number (
   echo Specified disk "%disk_name%" was not found
   call :cleanup
   exit 1
)

for /F "tokens=2* delims==" %%A in ('set disk_number.') do ( 
   :: Select found disk and get volume list
   set disk_number=%%A
   echo select disk !disk_number! > %script_file%
   echo detail disk >> %script_file%
   diskpart /s %script_file% > %detail_output_file%
   if errorlevel 1 (
      type %detail_output_file%
      call :cleanup
      exit %errorlevel%
   )

   for /F "tokens=1,2,3 skip=9" %%X in (%detail_output_file%) do ( 
      if "%%X"=="Volume" ( 
         if not "%%Y"=="###" (
            if not defined partition_id (
               :: if partition_id is not specified get last partition of the disk
               set volume_number=%%Y
            ) else (
               if /I "%%Z"=="%partition_id%" ( set volume_number=%%Y & goto :volume_found )
            )
         )
      )
   )
)

:volume_found
if not defined volume_number (
   if defined partition_id (
      echo Specified partition "%partition_id%" was not found on disk %disk_name%
   ) else (
      echo Specified disk %disk_name% has no defined partitions.
   )

   call :cleanup
   exit 1
)

::::::::::::::  Extend volume  ::::::::::::::::
echo select disk %disk_number% > %script_file%
echo select volume %volume_number% >> %script_file%
echo extend disk=%disk_number% >> %script_file%
diskpart /s %script_file% > %detail_output_file%
if errorlevel 1 (
   type %detail_output_file%
   call :cleanup
   exit %errorlevel%
)

::::::::::::::  Clean up  ::::::::::::::::
:cleanup
if exist %script_file% del %script_file%
if exist %list_output_file% del %list_output_file%
if exist %detail_output_file% del %detail_output_file%

ENDLOCAL