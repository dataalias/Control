<##############################################################################

File:		Get-QualtricsExport.ps1
Name:		Get-QualtricsExport

Purpose:	

Params:		

Called by:	
Calls:		n/a  

Errors:		

Author:		ffortunato
Date:		20171115
Version:    v01.00

###############################################################################

       CHANGE HISTORY

###############################################################################

Date		Author			Description

########	##########      ###################################################

20171115	ffortunato		Initial iteration.

20180111	ffortunato		Passing in the complete URL.

20181205  hbangad			Added TLS 1.2 security protocol before invoke rest  
##############################################################################>

function Get-QualtricsExport {

<#

.SYNOPSIS
This function invokes a restful api call to retrieve qualtrics data.

.DESCRIPTION
Desc...

.EXAMPLE
$yyymmdd  = Get-Date -format yyyyMMdd 
$url
$survey = 'SV_0dGfIUZJtycFwkl'
$datacenterURI = 'co1'
$token='HyPbCfi7UVndaAip1nqHUe2sNMkxmof34yatsSkI'
$outfile = "c:\tmp\$survey`_$yyymmdd.zip"
Get-QualtricsExport -url $URL -apiToken $token -format 'csv' -surveyId $survey -outFile $outfile 


#>

	[CmdletBinding(
	SupportsShouldProcess=$true
	)]
	param (

	[parameter(Mandatory=$true,
		Position = 1,
		HelpMessage=’The Site URL provided by Qualtrics’
		)]
	[string]$url='https://bridgepoint.co1.qualtrics.com/API/v3/responseexports',
	[parameter(Mandatory=$true,
		Position = 2,
		HelpMessage=’Token (for authentication) provided by Qualtrics’
		)]
	[alias("tok")]
	[string]$apiToken,
	[parameter(Mandatory=$true,
		Position = 3,
		HelpMessage=’Format to return the file in (e.g. ''csv'')’
		)]
	[alias("fmt")]
	[string]$format='csv',
	[parameter(Mandatory=$true,
		Position = 4,
		HelpMessage=’Identifier for the specific report to be pulled’
		)]
	[alias("id")]
	[string]$surveyId='SV_0dGfIUZJtycFwkl',
	[parameter(Mandatory=$true,
		Position = 5,
		HelpMessage=’Local destination for the file’
		)]
	[alias("out")]
	[string]$outFile='C:\tmp\tmp.csv'
	)


begin 
{

} #begin 

process
{
try
{
    $requestHeaders = @{}
    #$requestHeaders.Add("Accept", "*/*")
    $requestHeaders.Add("X-API-TOKEN", "$apiToken")
    $requestHeaders.Add("accept-encoding", "gzip, deflate")
 
    $requestData = @{
            format = "$format"
            surveyId = "$surveyId"
            includedQuestionIds = @()
            useLabels = $true
        }
 
    $body = (ConvertTo-Json $requestData)
 
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $response = Invoke-RestMethod -Method Post -Uri $url -ContentType "application/json" -Headers $requestHeaders -Body $body
    $responseExportId = $response.result.id
}
catch
{
	$errorMessage = "Response Export ID: $responseExportId  " +  $_.Exception.Message
    throw $errorMessage
	return
}
try
{ 
    $requestData = $null
    $body = (ConvertTo-Json $requestData)
    $percentComplete = 0
    $status = ""
 
    while($percentComplete -lt 100)
    {
        $response = Invoke-RestMethod -Method Get -Uri "$url/$responseExportId" -ContentType "application/json" -Headers $requestHeaders -Body $body
 
        $status = $response.result.status
 
        if($status -eq "failed" -or $status -eq "cancelled")
        {
            # If you receive a status of cancelled or failed, please go back and regenerate a responseExportId 
            # for your desired export format - JSON, CSV, CSV 2013, XML, SPSS - and try this request again.
            write-host $response.result.info.reason
            write-host $response.result.info.nextStep
            throw 'Reason: ' + $response.result.info.reason + ' Next Step: ' + $response.result.info.nextStep
        }
 
        $percentComplete = $response.result.percentComplete
        # write-host "Response Export Progress: $percentComplete%"
    }
}
catch
{
    # write-host "Downlaod Error while testing percent complete."
	$errorMessage =  "Downlaod Error: " + $_.Exception.Message + " `r`n Occured while testing percent complete."
    throw $errorMessage
}

try { 
    if( $status -eq 'complete')
    {
        $response = Invoke-RestMethod -Method Get -Uri "$url/$responseExportId/file" -ContentType "application/json" -Headers $requestHeaders -Body $body -OutFile $outFile
         
        if(test-path $outFile)
        {
            $destination = split-path -path $outFile
            invoke-Unzip -zipFile $outFile -outpath $destination
        }
    }
    else
    {
        write-host "Downlaod Error."
        throw "Download Error: " + $_.Exception.Message + "`r`n Status was recorded as incomplete. Status: $status"
    }
}
catch
{
    $errorMessage =  "Download Error: " + $_.Exception.Message + "Error occured in final response or unzip. Zip: $outFile , Dest: $destination"
	throw $errorMessage
}
} # process
end
{

} #end

} # Function

export-modulemember -function Get-QualtricsExport 