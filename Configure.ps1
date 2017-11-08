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
    [String]$ServerIp = "http://192.168.0.81:80"
)


########################## Programs ##########################

# Disable Programs
$programs = invoke-restMethod `
    -uri ("$ServerIp/api/HomeAutomation.HomeGenie/Automation/Programs.List/") `
    -verbose:$false

foreach ($program in ($programs | Where-Object {$_.IsEnabled -eq $true})) {
    write-verbose ("Disabling program: {0} Address: {1}" -f $program.Name, $program.Address)
    $null = invoke-restMethod `
        -uri ("$ServerIp/api/HomeAutomation.HomeGenie/Automation/Programs.Disable/$($program.Address)")`
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
    -uri ("$ServerIp/api/HomeAutomation.HomeGenie/Config/System.Configure/Location.Set/") `
    -body (convertto-json $locationData -compress) `
    -Method POST `
    -verbose:$false

# Get Location
write-verbose "get location"
invoke-restMethod -uri ("$ServerIp/api/HomeAutomation.HomeGenie/Config/System.Configure/Location.Get/") -verbose:$false

########################## Interfaces ##########################

# Only gets enabled interfaces:
#$interfaces = invoke-restMethod -uri ("$ServerIp/api/HomeAutomation.HomeGenie/Config/Interfaces.List/")

# Get Interfaces
$interfaces = invoke-restMethod `
    -uri ("$ServerIp/api/HomeAutomation.HomeGenie/Config/Interfaces.ListConfig/") `
    -verbose:$false

foreach ($interface in ($interfaces | Where-Object {$_.IsEnabled -eq $true})) {
    write-verbose ("Disabling interface: {0}" -f $interface.Domain)
    $null = invoke-restMethod `
         -uri ("$ServerIp/api/MIGService.Interfaces/$($interface.Domain)/IsEnabled.Set/0/") `
         -verbose:$false
}


########################## Install Interface ##########################


# Install Interfaces (Config.cs for this info)
# (If no args provided then it will use mig_interface_import.zip)
# or download interface:

$interfaceFileName = "C:\Users\Davidw\Source\repos\TexecomInterface\MIG-Interface\Output\MIG-TexecomInterface.zip"

write-verbose ("Uploading Interface {0}" -f $interfaceFileName)
$resp = invoke-restMethod -InFile $interfaceFileName -uri ("$ServerIp/api/HomeAutomation.HomeGenie/Config/Interface.Import/") `
   -Method POST `
   -ContentType "multipart/form-data"`
   -verbose:$false

Write-verbose ("`n*******************************`n" + $resp.ResponseValue + "`n*******************************")

write-verbose "Installing uploaded interface"
# TODO check response value
$null = invoke-restMethod `
    -uri "$ServerIp/api/HomeAutomation.HomeGenie/Config/Interface.Install" `
    <# -contentType "application/x-zip-compressed" #> `
    -verbose:$false

# write-verbose "installing interface using download"
# Add-Type -AssemblyName System.Web
# $interfaceDownloadUrl = [System.Web.HttpUtility]::UrlEncode("https://github.com/davidwallis3101/HomegenieEchoBridge/blob/master/MIG-EchoBridge.zip")
# invoke-restMethod -uri ("$ServerIp/api/HomeAutomation.HomeGenie/Config/System.Configure/Interface.Import/$interfaceDownloadUrl")

########################## Disable Inbuilt Schedules ##########################

# Disable Existing Schedules
write-verbose "Getting schedules"
$schedules = invoke-restMethod `
    -uri ("$ServerIp/api/HomeAutomation.HomeGenie/Automation/Scheduling.List") `
    -verbose:$false

foreach ($schedule in ($schedules | where-object {$_.IsEnabled -eq $true})) {
    write-verbose ("Disabling schedule: {0}" -f $schedule.Name)
    $null = invoke-restMethod `
        -uri ("$ServerIp/api/HomeAutomation.HomeGenie/Automation/Scheduling.Disable/$($schedule.Name)") `
        -verbose:$false
}


# Create Groups - this will add duplicates!
invoke-restMethod `
    -uri ("$ServerIp/api/HomeAutomation.HomeGenie/Config/Groups.Add/Control/") `
    -ContentType 'application/x-www-form-urlencoded' `
    -Body "AGroupName" `
    -Method Post `
    -verbose:$false

# Modify group
send json to http://192.168.0.81/api/HomeAutomation.HomeGenie/Config/Groups.Save/

$exampleJSON = @"
[
    {
      "Name": "Dashboard",
      "Wallpaper": "wallpaper_010.jpg",
      "Modules": [
        {
          "Address": "34",
          "Domain": "HomeAutomation.HomeGenie.Automation"
        },
        {
          "Address": "90",
          "Domain": "HomeAutomation.HomeGenie.Automation"
        },
        {
          "Address": "1",
          "Domain": "HomeAutomation.BasicThermostat",
          "Widget": "homegenie/generic/unknown",
          "WidgetInstance": {
            "Name": "Unknown Module",
            "Author": "Generoso Martello",
            "Version": "2013-03-31",
            "GroupName": "",
            "IconImage": "pages/control/widgets/homegenie/generic/images/unknown.png",
            "StatusText": "",
            "Description": ""
          }
        },
        {
          "Address": "1",
          "Domain": "HomeAutomation.EnergyMonitor",
          "Widget": "homegenie/generic/unknown",
          "WidgetInstance": {
            "Name": "Unknown Module",
            "Author": "Generoso Martello",
            "Version": "2013-03-31",
            "GroupName": "",
            "IconImage": "pages/control/widgets/homegenie/generic/images/unknown.png",
            "StatusText": "",
            "Description": ""
          }
        },
        {
          "Address": "Virtual Modules",
          "Domain": "HomeGenie.UI.Separator",
          "Widget": "homegenie/generic/grouplabel",
          "WidgetInstance": {
            "Name": "UI Group Label/Separator",
            "Author": "Generoso Martello",
            "Version": "2014-07-03",
            "GroupName": "",
            "IconImage": "",
            "StatusText": "",
            "Description": ""
          }
        },
        {
          "Address": "3",
          "Domain": "HomeAutomation.PhilipsHue",
          "Widget": "homegenie/generic/unknown",
          "WidgetInstance": {
            "Name": "Unknown Module",
            "Author": "Generoso Martello",
            "Version": "2013-03-31",
            "GroupName": "",
            "IconImage": "pages/control/widgets/homegenie/generic/images/unknown.png",
            "StatusText": "",
            "Description": ""
          }
        },
        {
          "Address": "2",
          "Domain": "HomeAutomation.Demo",
          "Widget": "homegenie/generic/unknown",
          "WidgetInstance": {
            "Name": "Unknown Module",
            "Author": "Generoso Martello",
            "Version": "2013-03-31",
            "GroupName": "",
            "IconImage": "pages/control/widgets/homegenie/generic/images/unknown.png",
            "StatusText": "",
            "Description": ""
          }
        },
        {
          "Address": "1",
          "Domain": "HomeAutomation.Demo",
          "Widget": "homegenie/generic/unknown",
          "WidgetInstance": {
            "Name": "Unknown Module",
            "Author": "Generoso Martello",
            "Version": "2013-03-31",
            "GroupName": "",
            "IconImage": "pages/control/widgets/homegenie/generic/images/unknown.png",
            "StatusText": "",
            "Description": ""
          }
        },
        {
          "Address": "3",
          "Domain": "HomeAutomation.Demo",
          "Widget": "homegenie/generic/unknown",
          "WidgetInstance": {
            "Name": "Unknown Module",
            "Author": "Generoso Martello",
            "Version": "2013-03-31",
            "GroupName": "",
            "IconImage": "pages/control/widgets/homegenie/generic/images/unknown.png",
            "StatusText": "",
            "Description": ""
          }
        },
        {
          "Address": "Simulate",
          "Domain": "HomeGenie.UI.Separator",
          "Widget": "homegenie/generic/grouplabel",
          "WidgetInstance": {
            "Name": "UI Group Label/Separator",
            "Author": "Generoso Martello",
            "Version": "2014-07-03",
            "GroupName": "",
            "IconImage": "",
            "StatusText": "",
            "Description": ""
          }
        },
        {
          "Address": "401",
          "Domain": "HomeAutomation.HomeGenie.Automation"
        },
        {
          "Address": "402",
          "Domain": "HomeAutomation.HomeGenie.Automation"
        },
        {
          "Address": "403",
          "Domain": "HomeAutomation.HomeGenie.Automation"
        },
        {
          "Address": "404",
          "Domain": "HomeAutomation.HomeGenie.Automation"
        }
      ],
      "Index": 0
    },
    {
      "Name": "Color Lights",
      "Wallpaper": "wallpaper_009.jpg",
      "Modules": [
        {
          "Address": "1",
          "Domain": "HomeGenie.ZoneSensors"
        },
        {
          "Address": "1",
          "Domain": "HomeAutomation.PhilipsHue"
        },
        {
          "Address": "2",
          "Domain": "HomeAutomation.PhilipsHue"
        },
        {
          "Address": "3",
          "Domain": "HomeAutomation.PhilipsHue"
        },
        {
          "Address": "Automation",
          "Domain": "HomeGenie.UI.Separator"
        },
        {
          "Address": "8",
          "Domain": "HomeAutomation.HomeGenie.Automation"
        },
        {
          "Address": "6",
          "Domain": "HomeAutomation.HomeGenie.Automation"
        },
        {
          "Address": "7",
          "Domain": "HomeAutomation.HomeGenie.Automation"
        }
      ],
      "Index": 1
    },
    {
      "Name": "OutsideLights",
      "Wallpaper": "",
      "Modules": [],
      "Index": 2
    },
    {
      "Name": "123",
      "Wallpaper": "",
      "Modules": [],
      "Index": 3
    },
    {
      "Name": "AGroupName",
      "Wallpaper": "",
      "Modules": [
        {
          "Address": "35",
          "Domain": "HomeAutomation.HomeGenie.Automation"
        }
      ],
      "Index": 4
    }
  ]
"@

invoke-restMethod `
    -uri ("$ServerIp/api/HomeAutomation.HomeGenie/Config/Groups.Save/") `
    -Body $exampleJson `
    -Method Post `
    -verbose:$false

######################### Restart ##########################
# invoke-restMethod -uri ("$ServerIp/api/HomeAutomation.HomeGenie/Config/System.Configure/Service.Restart/")


# Backup
$OutputFolder = "\\Iomega\Data\Homegenie\Backups" # Change this to the place where you want to save backups to.
$outputFile = "{0}\homegenie_backup_config_{1}_{2}.zip" -f $OutputFolder, $ServerIp.Split(".")[3], (get-date -uformat "%d-%m-%Y_%H-%M-%S")

Invoke-WebRequest `
    -Uri "$ServerIp/api/HomeAutomation.HomeGenie/Config/System.Configure/System.ConfigurationBackup" `
    -OutFile $outputFile

######################### TODO ##########################
# Install Packages


# event history

# HG.WebApp.Store.set('UI.EventsHistory', true);

# /Config/System.Configure/SystemLogging.Disable/
# /Config/System.Configure/SystemLogging.Enable/
# /Config/System.Configure/SystemLogging.IsEnabled/

