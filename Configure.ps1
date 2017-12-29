<#
.SYNOPSIS
    Get-Something

.DESCRIPTION
    Long description

.PARAMETER Server
    The hg server url

.EXAMPLE
    PS C:\> Configure.ps1 -Server "Http://10.1.1.1:80"

.LINK
    https://github.com/davidwallis3101/HGConfigure
#>
[cmdletbinding()]
Param(
    [String]$Server = "http://10.4.1.4:80"
)

function Invoke-MultipartFormDataUpload {
    [CmdletBinding()]
    PARAM
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$InFile,

        [string]$ContentType,

        [parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
        [Uri]$Uri,

        [System.Management.Automation.PSCredential]$Credential
    )

    BEGIN
    {
        if (-not (Test-Path $InFile))
        {
            $errorMessage = ("File {0} missing or unable to read." -f $InFile)
            $exception =  New-Object System.Exception $errorMessage
            $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, 'MultipartFormDataUpload', ([System.Management.Automation.ErrorCategory]::InvalidArgument), $InFile
            $PSCmdlet.ThrowTerminatingError($errorRecord)
        }

        if (-not $ContentType)
        {
            Add-Type -AssemblyName System.Web

            $mimeType = [System.Web.MimeMapping]::GetMimeMapping($InFile)

            if ($mimeType)
            {
                $ContentType = $mimeType
            }
            else
            {
                $ContentType = "application/octet-stream"
            }
        }
    }
    PROCESS
    {
        Add-Type -AssemblyName System.Net.Http

        $httpClientHandler = New-Object System.Net.Http.HttpClientHandler

        if ($Credential) {
            $networkCredential = New-Object System.Net.NetworkCredential @($Credential.UserName, $Credential.Password)
            $httpClientHandler.Credentials = $networkCredential
        }

        $httpClient = New-Object System.Net.Http.Httpclient $httpClientHandler

        $packageFileStream = New-Object System.IO.FileStream @($InFile, [System.IO.FileMode]::Open)

        $contentDispositionHeaderValue = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue "form-data"
        $contentDispositionHeaderValue.Name = "fileData"

        # Modified for HG as regex looks for quotes around the file name
        $contentDispositionHeaderValue.FileName = '"{0}"' -f (Split-Path $InFile -leaf)

        $streamContent = New-Object System.Net.Http.StreamContent $packageFileStream
        $streamContent.Headers.ContentDisposition = $contentDispositionHeaderValue
        $streamContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue $ContentType

        $content = New-Object System.Net.Http.MultipartFormDataContent
        $content.Add($streamContent)

        try {
            $response = $httpClient.PostAsync($Uri, $content).Result

            if (!$response.IsSuccessStatusCode) {
                $responseBody = $response.Content.ReadAsStringAsync().Result
                $errorMessage = "Status code {0}. Reason {1}. Server reported the following message: {2}." -f $response.StatusCode, $response.ReasonPhrase, $responseBody

                throw [System.Net.Http.HttpRequestException] $errorMessage
            }

            return $response.Content.ReadAsStringAsync().Result
        }
        catch [Exception] {
            $PSCmdlet.ThrowTerminatingError($_)
        }
        finally {
            if($null -ne $httpClient) {
                $httpClient.Dispose()
            }

            if($null -ne $response) {
                $response.Dispose()
            }
        }
    }
    END { }
}


########################## Programs ##########################

# Disable Programs
$programs = invoke-restMethod `
    -uri ($Server + "/api/HomeAutomation.HomeGenie/Automation/Programs.List/") `
    -verbose:$false

foreach ($program in ($programs|Where-Object {$_.IsEnabled -eq $true})) {
    write-verbose ("Disabling program: {0} Address: {1}" -f $program.Name, $program.Address)
    $null = invoke-restMethod `
        -uri ($Server + "/api/HomeAutomation.HomeGenie/Automation/Programs.Disable/$($program.Address)")`
        -verbose:$false
}

########################## Set Location ##########################

$locationData = @{
    'name' = "Leeds, UK";
    'latitude' = 53.8003459;
    'longitude' = -1.5497609000000239;
}

write-verbose "setting location"
invoke-restMethod `
    -uri ($Server + "/api/HomeAutomation.HomeGenie/Config/System.Configure/Location.Set/") `
    -body (convertto-json $locationData -compress) `
    -Method POST `
    -verbose:$false

# Get Location
write-verbose "get location"
invoke-restMethod -uri ($Server + "/api/HomeAutomation.HomeGenie/Config/System.Configure/Location.Get/") -verbose:$false

########################## Interfaces ##########################

# Only gets enabled interfaces:
#$interfaces = invoke-restMethod -uri ($Server + "/api/HomeAutomation.HomeGenie/Config/Interfaces.List/")

# Get Interfaces
$interfaces = invoke-restMethod `
    -uri ($Server + "/api/HomeAutomation.HomeGenie/Config/Interfaces.ListConfig/") `
    -verbose:$false

foreach ($interface in ($interfaces|Where-Object {$_.IsEnabled -eq $true})) {
    write-verbose ("Disabling interface: {0}" -f $interface.Domain)
    $null = invoke-restMethod `
         -uri ($Server + "/api/MIGService.Interfaces/$($interface.Domain)/IsEnabled.Set/0/") `
         -verbose:$false
}


########################## Install Interface ##########################


# Install Interfaces (Config.cs for this info)
# (If no args provided then it will use mig_interface_import.zip)
# or download interface:

$interfaceFileName = "c:\users\davidw\desktop\MIG-Echobridge.zip"

write-verbose ("Uploading Interface: {0}" -f $interfaceFileName)

$resp = Invoke-MultipartFormDataUpload `
    -InFile $interfaceFileName `
    -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/Interface.Import/") `
    -contentType "application/form-data" `
    -Verbose

$msg = $resp |ConvertFrom-Json

# There is a bug in that the wrong markdown is returned when uploading an interface
Write-verbose ("`n*******************************`n" + $msg.ResponseValue + "`n*******************************")

write-verbose "Installing uploaded interface"
# TODO check response value
$null = (invoke-restMethod `
    -uri ($Server + "/api/HomeAutomation.HomeGenie/Config/Interface.Install") `
    <# -contentType "application/x-zip-compressed" #> `
    -verbose:$false)

# write-verbose "installing interface using download"
# Add-Type -AssemblyName System.Web
# $interfaceDownloadUrl = [System.Web.HttpUtility]::UrlEncode("https://github.com/davidwallis3101/HomegenieEchoBridge/blob/master/MIG-EchoBridge.zip")
# invoke-restMethod -uri ($Server + "/api/HomeAutomation.HomeGenie/Config/System.Configure/Interface.Import/$interfaceDownloadUrl")


########################## Get Schedules ##########################
write-verbose "Getting schedules"
$schedules = invoke-restMethod `
    -uri ($Server + "/api/HomeAutomation.HomeGenie/Automation/Scheduling.List") `
    -verbose:$false

########################## Disable Schedules ##########################
foreach ($schedule in ($schedules| Where-Object {$_.IsEnabled -eq $true})) {
    write-verbose ("Disabling schedule: {0}" -f $schedule.Name)
    $null = invoke-restMethod `
        -uri ($Server + "/api/HomeAutomation.HomeGenie/Automation/Scheduling.Disable/$($schedule.Name)")`
        -verbose:$false
}


########################## Restart ##########################

# invoke-restMethod -uri ($Server + "/api/HomeAutomation.HomeGenie/Config/System.Configure/Service.Restart/")



########################## TODO ##########################

# Install Packages

# event history

# HG.WebApp.Store.set('UI.EventsHistory', true);

# /Config/System.Configure/SystemLogging.Disable/
# /Config/System.Configure/SystemLogging.Enable/
# /Config/System.Configure/SystemLogging.IsEnabled/


# Backup