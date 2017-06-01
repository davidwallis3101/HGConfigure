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


########################## Programs ##########################

# Disable Programs
$programs = invoke-restMethod `
    -uri ($Server + "/api/HomeAutomation.HomeGenie/Automation/Programs.List/") `
    -verbose:$false

foreach ($program in ($programs|where {$_.IsEnabled -eq $true})) {
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

foreach ($interface in ($interfaces|where {$_.IsEnabled -eq $true})) {
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

write-verbose ("Uploading Interface {0}" -f $interfaceFileName)
$resp = invoke-restMethod -InFile $interfaceFileName -uri ($Server + "/api/HomeAutomation.HomeGenie/Config/Interface.Import/") `
   -Method POST `
   -ContentType "multipart/form-data"`
   -verbose:$false

Write-verbose ("`n*******************************`n" + $resp.ResponseValue + "`n*******************************")

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

########################## Disable Inbuilt Schedules ##########################

# Disable Existing Schedules
write-verbose "Getting schedules"
$schedules = invoke-restMethod `
    -uri ($Server + "/api/HomeAutomation.HomeGenie/Automation/Scheduling.List") `
    -verbose:$false

foreach ($schedule in ($schedules|where {$_.IsEnabled -eq $true})) {
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