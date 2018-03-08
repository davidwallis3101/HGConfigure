<#
.SYNOPSIS
    Get-Something

.DESCRIPTION
    Long description

.PARAMETER Server
    The hg server url

.EXAMPLE
    PS C:\> Configure.ps1 -Server "http://10.1.1.1:80"

.LINK
    https://github.com/davidwallis3101/HGConfigure
#>

[cmdletbinding()]
Param(
    [String]$ServerIp = "10.4.1.4",
    [int]$port = 80,
    [string] $proto = "http"
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

clear-host

# Needs Invoke-MsBuild
# Can be installed from the gallery with install-module invoke-msbuild -Repository psGallery

# Increment text in the file
# $file = "C:\Users\davidw\source\repos\mig-interface-skelton\MIG-Interface\InterfaceSkelton.cs"

# [regex]$pattern = "FINDME(\d{0,10})"
# $RESULT = Select-String -path $file -pattern $pattern
# [int]$version = $RESULT.Matches.Groups[1].Value
# $version++

# $fileContent = (get-content $file)

# $fileContent -Replace("FINDME(\d{0,10})", "FINDME$($version)") | Set-Content $file

# # trigger the build
# $Build = Invoke-MsBuild -Path "C:\Users\davidw\source\repos\mig-interface-skelton\MIG-Interface.sln" -ErrorAction Stop
# If (-not $Build.BuildSucceeded) {
#     throw "Build Failed"
# }

$ServerAddress = ("{0}://{1}:{2}" -f $proto, $ServerIp, $port)

$VerbosePreference = "Continue"


########################## Install Interface ##########################


write-verbose "Disabling Interface"
invoke-restMethod `
    -uri ("$ServerAddress/api/MIGService.Interfaces/Example.InterfaceSkelton/IsEnabled.Set/0/") `
    -verbose `
    -TimeoutSec 5


# Install Interfaces (Config.cs for this info)
# (If no args provided then it will use mig_interface_import.zip)
# or download interface:

$interfaceFileName = "C:\Users\davidw\source\repos\mig-interface-skelton\MIG-Interface\Output\MIG-Interface.zip"

write-verbose ("Uploading Interface: {0}" -f $interfaceFileName)

$resp = Invoke-MultipartFormDataUpload `
    -InFile $interfaceFileName `
    -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/Interface.Import/") `
    -contentType "application/form-data" `
    -Verbose

$msg = $resp | ConvertFrom-Json

# invoke-restMethod `
#     -InFile $interfaceFileName `
#     -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/Interface.Import/") `
#     -Method POST `
#     -ContentType "multipart/form-data" `
#     -Headers @{'Accept-Encoding'='gzip, deflate'} `
#     -verbose:$true

# TODO get markdown that is returned from installing the interface
Write-verbose ("`n*******************************`n" + $msg.ResponseValue + "`n*******************************")

write-verbose "Installing uploaded interface"
# TODO check response value
$null = invoke-restMethod `
    -uri "$ServerAddress/api/HomeAutomation.HomeGenie/Config/Interface.Install" `
    -verbose:$false

# Get Interfaces
$interfaces = invoke-restMethod `
     -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/Interfaces.ListConfig/") `
     -verbose:$false
$interfaces | FL

# Disable All
# foreach ($interface in $Interfaces) {
#     write-verbose ("Interface: {0}" -f $interface.Domain)
#     $null = invoke-restMethod `
#         -uri ("$ServerAddress/api/MIGService.Interfaces/$($interface.Domain)/IsEnabled.Set/0/") `
#         -verbose:$false
# }

# Enable Example
write-verbose "Enabling Interface"
invoke-restMethod `
    -uri ("$ServerAddress/api/MIGService.Interfaces/Example.InterfaceSkelton/IsEnabled.Set/1/") `
    -verbose `
    -TimeoutSec 5


