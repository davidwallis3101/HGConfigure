[cmdletbinding()]
Param(
    [String]$IpAddress = "192.168.0.161",
    [String]$Port = "80"
)
$verbosePreference = "Continue"

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

[String]$Server = ("http://{0}:{1}" -f $IpAddress, $Port)


$interfacesFolder = "C:\Users\Davidw\Source\repos\TexecomInterface\MIG-Interface\Output"

########################## Install Interfaces ##########################

foreach ($interface in (Get-ChildItem -path $interfacesFolder -Filter *.zip))
{
    write-verbose ("Uploading Interface: {0}" -f  $interface.fullname)

    $resp = Invoke-MultipartFormDataUpload `
        -InFile  $interface.fullname `
        -uri ("$Server/api/HomeAutomation.HomeGenie/Config/Interface.Import/") `
        -contentType "application/form-data" `
        -Verbose

    $msg = $resp | ConvertFrom-Json

    # There is a bug in that the wrong markdown is returned when uploading an interface
    Write-verbose ("`n*******************************`n" + $msg.ResponseValue + "`n*******************************")

    write-verbose "Installing uploaded interface"
    $null = (invoke-restMethod `
        -uri ($Server + "/api/HomeAutomation.HomeGenie/Config/Interface.Install") `
        -verbose:$false)

    #Might not be needed, but do it anyway..
    start-sleep -seconds 2
}

########################## Enable Interfaces ##########################
$interfacesToEnable = @(
    @{Domain = "HomeAutomation.TexecomInterface"}
)

foreach ($interface in $interfacesToEnable) {
    write-verbose ("Enabling interface: {0}" -f $interface.Domain)
    $null = invoke-restMethod `
         -uri ($Server + "/api/MIGService.Interfaces/$($interface.Domain)/IsEnabled.Set/1/") `
         -verbose:$false
}