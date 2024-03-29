<##############################################################################

File:		dmutils.psd1
Name:		dmutils

Purpose:    This is the PowerShell manifest file for all the Data Management
			utilities. This file expresses each of the functions that are 
			exposed with this module is imported.

Called by:	
Calls:		n/a  

Errors:		

Author:		ffortunato
Date:		20171205
Version:    1.2.0.0

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################
20171205    ffortunato      Initital Iteration.
20180216    ffortunato      Adding several new functions to the module.
							Reformatting NestedModules and FunctionsToExport
							Improving Description. Working with Edit Issue
							1.0.0.4

20180216    ffortunato      1.0.0.6
20180322	ffortunato		Added Composite error handler Invoke-ErrorHandler
20180216    ffortunato      1.0.0.7 after some fun Logging fixes for QA.
20180327	ffortunato		Fixes for QA. Using native Get-FileHash removing 
                            dmutils version.
20180529	ffortunato		Adding db Table check functions.
20181009	ffortunato		New Interval Check Added. 
							1.1.0.0
20181009	ffortunato		Several bug fixes. List data table rather than 
							Get data table. 
							1.2.0.0

20190109	ffortunato		Small changes to logging to determin if file is 
							locked before writing. 
							1.2.1.0

20190109	ffortunato		New function Invoke-FileShare-Put
20190306	ochowkwale		New function ftpPut
20190419	ochowkwale		New Canvas Functions
20190919	ochowkwale		Canvas function - GetCanvasCompressedFiles
##############################################################################>

@{

# Script module or binary module file associated with this manifest.
RootModule = 'dmutils.psm1'

# Version number of this module.
ModuleVersion = "1.2.0.0"

# ID used to uniquely identify this module
GUID = 'bb1a8702-16c3-4427-aa2d-a35b42731145'

# Author of this module
Author = 'Frank Fortunato'

# Company or vendor of this module
CompanyName = 'Blue Elysium'

# Copyright statement for this module
Copyright = '(c)'

# Description of the functionality provided by this module
Description = 'This module provides core ultilities used by a number of powershell processes managed by Data Management. Functions include utilities for sending email, unzipping files, generating hashs, creating control files and maintaing issues within the ctl framework.'

# Minimum version of the Windows PowerShell engine required by this module
# PowerShellVersion = ''

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
# RequiredModules = @()

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
# FormatsToProcess = @()

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
NestedModules = @(
	#dmultils
	#".\Hash.ps1"
	 ".\Invoke-Unzip.ps1"
	,".\Send-eMail.ps1"
	,".\Invoke-ErrorHandler.ps1"
	#Canvas
	,".\Canvas\Invoke-CanvasFileCheck.ps1"
	,".\Canvas\Invoke-CanvasGet.ps1"
	,".\Canvas\Invoke-CanvasGetCompressedFiles.ps1"
	#ctl
	,".\ctl\Add-ControlFile.ps1"
	,".\ctl\Edit-Issue.ps1"
	,".\ctl\Get-IssueNamesToRetrieve.ps1"
	,".\ctl\Invoke-ctlFileToIssue.ps1"
	,".\ctl\Invoke-SQLServerJob.ps1"
	,".\ctl\Invoke-StagingPackage.ps1"
	,".\ctl\New-Issue.ps1"
	#Datetime
	,".\Datetime\Invoke-SLACheck.ps1"
	,".\Datetime\Invoke-IntervalCheck.ps1"
	#FileShare
	,".\FileShare\FileShareListCheckGet.ps1"
	,".\FileShare\Invoke-FileSharePut.ps1"
	#RestAPI
	,".\RestAPI\Get-QualtricsExport.ps1"
	#WinSCP
	,".\WinSCP\WinSCP.ps1"
	,".\WinSCP\ftpListCheckGet.ps1"
	,".\WinSCP\ftpPut.ps1"
	#Table
	,".\Table\dbIntervalCheckGet.ps1"
)

# Functions to export from this module
FunctionsToExport = @(
	# dmutils
	 "Get-dmutils"
	,"Invoke-NiceLog"
	,"Invoke_ErrorHandler"
	,"Test-IsFileLocked"
	# Hash
	#,"Get-FileHash"
	#,"Get-StringHash"
	# Unzip
	,"Invoke-Unzip"
	# e-mail
	,"Send-eMail"
	#Canvas
	,"Invoke-CanvasFileCheck"
	,"Invoke-CanvasGet"
	,"Invoke-CanvasGetCompressedFiles"
	# ctl
	,"New-Issue"
	,"Edit-Issue"
	,"Add-ControlFile"
	,"Invoke-ctlFileToIssue"
	,"Invoke-SQLServerJob"
	,"Invoke-StagingPackage"
	,"Get-IssueNamesToRetrieve"
	# Datetime
	,"Invoke-SLACheck"
	,"Invoke-IntervalCheck"
	# File Share
	,"Invoke-FileShareListCheckGet"
	,"Invoke-FileSharePut"
	# WinSCP / ftp
	,"Invoke-WinSCP"
	,"Invoke-WinSCPGet"
	,"Invoke-ftpListCheckGet"
	,"Invoke-ftpPut"
	# qualtrics
	,"Get-QualtricsExport"
	# table
	,"Invoke-dbIntervalCheckGet"
)

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess
# PrivateData = ''

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

