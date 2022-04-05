<##############################################################################

File:		Hash.ps1
Name:		Hash
Purpose:	Contains two functions  Get-StringHash and  Get-FileHash

Parameters:    

Called by:	
Calls:          

Errors:		

Author:		ffortunto
Date:		20180205
Version:	1.0.0.7

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

--------	--------------	---------------------------------------------------
20180327	ffortunato		fixing flower box. setting version number 1.0.0.7
							Getting rid of Get-FileHash there is now a native
							powersehll function for this functionality.

##############################################################################>

function Get-StringHash
{

<#

.SYNOPSIS
This function gets the hash value of a string.

.DESCRIPTION
This function takes a string as input and computes a 

.PARAMETER stringToHash
The string that will be hashed.

.EXAMPLE
Get-StringHash "foo"

#>
    [CmdletBinding(
        SupportsShouldProcess=$True
    )]
    param (
        [parameter(Mandatory=$true,
            Position = 0,
            HelpMessage=’This is the string to retrieve the hash value.’
            )]
        [alias("s")]
        [string]$stringToHash)

begin
{

} #begin

process
{

# Create Input Data 
	$enc = [system.Text.Encoding]::UTF8
	$data1 = $enc.GetBytes($stringToHash) 

# Create a New SHA1 Crypto Provider 
	$crypt = New-Object -TypeName System.Security.Cryptography.SHA256 #MD5CryptoServiceProvider

# Now hash and display results 
	$hash = [System.BitConverter]::ToString($crypt.ComputeHash($data1))

	return $hash -replace '-',''

} #process

end
{

} #end
} #function

export-modulemember -function Get-StringHash

<#
function Get-FileHash
{

<#

.SYNOPSIS
This function gets that hash value of a string.

.DESCRIPTION
...

.PARAMETER stringToHash
The string that will be hashed.

.EXAMPLE
Get-FileHash "c:\foo.txt"

#><#
    [CmdletBinding(
        SupportsShouldProcess=$True
    )]
    param (
        [parameter(Mandatory=$true,
            Position = 0,
            HelpMessage=’This is the string to retrieve the hash value.’
            )]
        [alias("f")]
        [string]$fileNameToHash)

begin
{

} #begin

process
{

	$crypt  = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
	$hash = [System.BitConverter]::ToString($crypt.ComputeHash([System.IO.File]::ReadAllBytes($fileNameToHash)))
	return $hash -replace '-',''

} #process

end
{

} #end
} #function

export-modulemember -function Get-FileHash
#>