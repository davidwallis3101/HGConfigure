<#
.SYNOPSIS
    Get-Something

.DESCRIPTION
    Long description

.PARAMETER IpAddress
    The hg server ip

.PARAMETER Port
    The hg server port

.EXAMPLE
    PS C:\> Configure.ps1 -Server "http://127.0.0.1:80"

.LINK
    https://github.com/davidwallis3101/HGConfigure
#>
[cmdletbinding()]
Param(
    [String]$IpAddress = "192.168.0.161",

    [String]$Port = "80"
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

[String]$Server = ("http://{0}:{1}" -f $IpAddress, $Port)


$interfacesFolder = Join-Path $PSScriptRoot "Interfaces"


########################## Programs ##########################

# Disable All Programs
$programs = invoke-restMethod `
    -uri ($Server + "/api/HomeAutomation.HomeGenie/Automation/Programs.List/") `
    -verbose:$false

foreach ($program in ($programs|Where-Object {$_.IsEnabled -eq $true})) {
    write-verbose ("Disabling program: {0} Address: {1}" -f $program.Name, $program.Address)
    $null = invoke-restMethod `
        -uri ($Server + "/api/HomeAutomation.HomeGenie/Automation/Programs.Disable/$($program.Address)")`
        -verbose:$false
}

########################## Programs ##########################
# Delete programs
$programsToDelete = @(
    @{Name = "Group Lights ON"; Address = 6},
    @{Name = "Group Lights OFF"; Address = 7},
    @{Name = "Sunrise Colors Scenario"; Address = 8},
    @{Name = "Level Memory"; Address = 16},
    @{Name = "Philips Hue Bridge"; Address = 26},
    # @{Name = "Zone Sensors"; Address = 29},
    #@{Name = "Weather Underground"; Address = 34},
    @{Name = "Level Poll"; Address = 39},
    @{Name = "Meter Watt Poll"; Address = 40},
    @{Name = "IR/RF remote control events forwarding"; Address = 73},
    @{Name = "Meter.Watts events forwarding"; Address = 74},
    @{Name = "Status.Level events forwarding"; Address = 75},
    @{Name = "Sensor.* events forwarding"; Address = 76},
    @{Name = "MQTT Network"; Address = 77},
    @{Name = "Basic Thermostat"; Address = 78},
    @{Name = "Energy Monitor"; Address = 81},
    @{Name = "Energy Saving Mode"; Address = 82},
    @{Name = "Set to 100% when switched on"; Address = 84},
    @{Name = "Generic IP Camera"; Address = 88},
    @{Name = "Security Alarm System"; Address = 90},
    @{Name = "Query on Wake Up"; Address = 91},
    @{Name = "Z-Wave Thermostat Poll"; Address = 92},
    #@{Name = "Multi Instance/Channel  Virtual Modules"; Address = 93},
    @{Name = "Turn Off Delay"; Address = 112},
    @{Name = "X10 RF Virtual Modules Mapper"; Address = 121},
    @{Name = "E-Mail Account"; Address = 142},
    @{Name = "Favourites Links"; Address = 180},
    @{Name = "Windows Phone Push Notification Service"; Address = 200},
    @{Name = "Virtual Modules Demo"; Address = 400},
    @{Name = "Demo - Toggle Door"; Address = 401},
    @{Name = "Demo - Motion Detected"; Address = 402},
    @{Name = "Demo - Simulate Temperature"; Address = 403},
    @{Name = "Demo - Simulate Luminance"; Address = 404},
    @{Name = "IR Remote Controller"; Address = 505}
)

foreach ($program in $programsToDelete) {
    write-verbose ("Deleting program: {0} Address: {1}" -f $program.Name, $program.Address)
     $null = invoke-restMethod `
         -uri ($Server + "/api/HomeAutomation.HomeGenie/Automation/Programs.Delete/$($program.Address)") `
         -verbose:$false
}

# Getting Programs
$programs = invoke-restMethod `
    -uri ($Server + "/api/HomeAutomation.HomeGenie/Automation/Programs.List/") `
    -verbose:$false

# Get Automation Groups
$automationGroups = invoke-restMethod `
    -uri ($Server + "/api/HomeAutomation.HomeGenie/Config/Groups.List/Automation/") `
    -verbose:$false

foreach ($automationGroup in $automationGroups) {
  $programsInAutomationGroup = $programs | Where-Object {$_.Group -eq $automationGroup.Name}

  if ($programsInAutomationGroup.Count -eq 0) {
      write-verbose ("Removing automation group {0} as it has no programs" -f $automationGroup.Name)
      $null = invoke-restMethod `
          -uri ($Server + "/api/HomeAutomation.HomeGenie/Config/Groups.Delete/Automation/") `
          -ContentType 'application/x-www-form-urlencoded' `
          -Body $automationGroup.Name `
          -Method Post `
          -Verbose:$false
  }
}

########################## Groups ##########################
# Get groups
$groups = invoke-restMethod `
    -uri ($Server + "/api/HomeAutomation.HomeGenie/Config/Groups.List/Control/") `
    -verbose:$false

write-verbose "Deleting groups with no modules"
foreach ($group in $groups) {
  if ($group.Modules.Count -eq 0) {
      write-verbose ("Deleting group: [{0}]" -f $group.Name)
      $null = invoke-restMethod `
          -uri ($Server + "/api/HomeAutomation.HomeGenie/Config/Groups.Delete/Control/") `
          -ContentType 'application/x-www-form-urlencoded' `
          -Body $group.Name `
          -Method Post `
          -verbose:$false
  }
}

# Delete Color lights group
write-verbose "Deleting color lights group"
$null = invoke-restMethod `
    -uri ($Server + "/api/HomeAutomation.HomeGenie/Config/Groups.Delete/Control/") `
    -ContentType 'application/x-www-form-urlencoded' `
    -Body "Color Lights" `
    -Method Post `
    -verbose:$false


##########################  Disable Un-Needed Interfaces ##########################
$interfacesToDisable = @(
    @{Domain = "Protocols.UPnP"},
    @{Domain = "HomeAutomation.ZWave"},
    @{Domain = "HomeAutomation.X10"}
)

# # Get Interfaces
# $interfaces = invoke-restMethod `
#     -uri ($Server + "/api/HomeAutomation.HomeGenie/Config/Interfaces.ListConfig/") `
#     -verbose:$false

foreach ($interface in $interfacesToDisable) {
    write-verbose ("Disabling interface: {0}" -f $interface.Domain)
    $null = invoke-restMethod `
         -uri ($Server + "/api/MIGService.Interfaces/$($interface.Domain)/IsEnabled.Set/0/") `
         -verbose:$false
}

########################## Set Location ##########################

$locationData = @{
    'name' = "Leeds, UK";
    'latitude' = 53.8003459;
    'longitude' = -1.5497609000000239;
}

write-verbose "Setting location"
invoke-restMethod `
    -uri ($Server + "/api/HomeAutomation.HomeGenie/Config/System.Configure/Location.Set/") `
    -body (convertto-json $locationData -compress) `
    -Method POST `
    -verbose:$false

# Get Location
write-verbose "get location"
invoke-restMethod -uri ($Server + "/api/HomeAutomation.HomeGenie/Config/System.Configure/Location.Get/") -verbose:$false

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
    @{Domain = "Protocols.MqttBrokerService"},
    @{Domain = "HomeAutomation.EchoBridge"},
    @{Domain = "HomeAutomation.TexecomInterface"}
)

foreach ($interface in $interfacesToEnable) {
    write-verbose ("Enabling interface: {0}" -f $interface.Domain)
    $null = invoke-restMethod `
         -uri ($Server + "/api/MIGService.Interfaces/$($interface.Domain)/IsEnabled.Set/1/") `
         -verbose:$false
}


# write-verbose "installing interface using download"
# Add-Type -AssemblyName System.Web
# $interfaceDownloadUrl = [System.Web.HttpUtility]::UrlEncode("https://github.com/davidwallis3101/HomegenieEchoBridge/blob/master/MIG-EchoBridge.zip")
# invoke-restMethod -uri ($Server + "/api/HomeAutomation.HomeGenie/Config/System.Configure/Interface.Import/$interfaceDownloadUrl")


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