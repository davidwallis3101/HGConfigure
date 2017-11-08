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
    [String]$ServerIp = "192.168.0.81",
    [int]$port = 80,
    [string] $proto = "http"
)

$ServerAddress = ("{0}://{1}:{2}" -f $proto, $ServerIp, $port)
$ServerAddress

$VerbosePreference = "Continue"

########################## Programs ##########################

# Getting Programs
$programs = invoke-restMethod `
    -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Automation/Programs.List/") `
    -verbose:$false

# $programs | Select Name, Address |Sort-Object Address

# Disable Programs
foreach ($program in ($programs | Where-Object {$_.IsEnabled -eq $true})) {
    write-verbose ("Disabling program: {0} Address: {1}" -f $program.Name, $program.Address)
    $null = invoke-restMethod `
        -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Automation/Programs.Disable/$($program.Address)")`
        -verbose:$false
}

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
    #@{Name = "IR/RF remote control events forwarding"; Address = 73},
    #@{Name = "Meter.Watts events forwarding"; Address = 74},
    #@{Name = "Status.Level events forwarding"; Address = 75},
    #@{Name = "Sensor.* events forwarding"; Address = 76},
    #@{Name = "MQTT Network"; Address = 77},
    @{Name = "Basic Thermostat"; Address = 78},
    @{Name = "Energy Monitor"; Address = 81},
    @{Name = "Energy Saving Mode"; Address = 82},
    @{Name = "Set to 100% when switched on"; Address = 84},
    @{Name = "Generic IP Camera"; Address = 88},
    @{Name = "Security Alarm System"; Address = 90},
    @{Name = "Query on Wake Up"; Address = 91},
    @{Name = "Z-Wave Thermostat Poll"; Address = 92},
    #@{Name = "Multi Instance/Channel  Virtual Modules"; Address = 93},
    #@{Name = "Turn Off Delay"; Address = 112},
    @{Name = "X10 RF Virtual Modules Mapper"; Address = 121},
    @{Name = "E-Mail Account"; Address = 142},
    @{Name = "Favourites Links"; Address = 180},
    @{Name = "Windows Phone Push Notification Service"; Address = 200},
    @{Name = "Virtual Modules Demo"; Address = 400},
    @{Name = "Demo - Toggle Door"; Address = 401},
    @{Name = "Demo - Motion Detected"; Address = 402},
    @{Name = "Demo - Simulate Temperature"; Address = 403},
    @{Name = "Demo - Simulate Luminance"; Address = 404}
    #,@{Name = "IR Remote Controller"; Address = 505}
)

foreach ($program in $programsToDelete) {
    write-verbose ("Deleting program: {0} Address: {1}" -f $program.Name, $program.Address)
     $null = invoke-restMethod `
         -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Automation/Programs.Delete/$($program.Address)")`
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
    -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/System.Configure/Location.Set/") `
    -body (convertto-json $locationData -compress) `
    -Method POST `
    -verbose:$false

# Get Location
write-verbose "get location"
invoke-restMethod -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/System.Configure/Location.Get/") -verbose:$false

########################## Interfaces ##########################

# Only gets enabled interfaces:
#$interfaces = invoke-restMethod -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/Interfaces.List/")

# Get Interfaces
$interfaces = invoke-restMethod `
    -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/Interfaces.ListConfig/") `
    -verbose:$false

foreach ($interface in ($interfaces | Where-Object {$_.IsEnabled -eq $true})) {
    write-verbose ("Disabling interface: {0}" -f $interface.Domain)
    $null = invoke-restMethod `
         -uri ("$ServerAddress/api/MIGService.Interfaces/$($interface.Domain)/IsEnabled.Set/0/") `
         -verbose:$false
}


########################## Install Interface ##########################


# Install Interfaces (Config.cs for this info)
# (If no args provided then it will use mig_interface_import.zip)
# or download interface:

$interfaceFileName = "C:\Users\Davidw\Source\repos\TexecomInterface\MIG-Interface\Output\MIG-TexecomInterface.zip"

write-verbose ("Uploading Interface {0}" -f $interfaceFileName)
$resp = invoke-restMethod `
    -InFile $interfaceFileName `
    -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/Interface.Import/") `
    -Method POST `
    -ContentType "multipart/form-data"`
    -verbose:$false

    $resp |fl 
Write-verbose ("`n*******************************`n" + $resp.ResponseValue + "`n*******************************")

write-verbose "Installing uploaded interface"
# TODO check response value
$null = invoke-restMethod `
    -uri "$ServerAddress/api/HomeAutomation.HomeGenie/Config/Interface.Install" `
    <# -contentType "application/x-zip-compressed" #> `
    -verbose:$false

# write-verbose "installing interface using download"
# Add-Type -AssemblyName System.Web
# $interfaceDownloadUrl = [System.Web.HttpUtility]::UrlEncode("https://github.com/davidwallis3101/HomegenieEchoBridge/blob/master/MIG-EchoBridge.zip")
# invoke-restMethod -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/System.Configure/Interface.Import/$interfaceDownloadUrl")

########################## Disable Inbuilt Schedules ##########################

# Disable Existing Schedules
write-verbose "Getting schedules"
$schedules = invoke-restMethod `
    -uri "$ServerAddress/api/HomeAutomation.HomeGenie/Automation/Scheduling.List" `
    -verbose:$false

foreach ($schedule in ($schedules | where-object {$_.IsEnabled -eq $true})) {
    write-verbose ("Disabling schedule: {0}" -f $schedule.Name)
    $null = invoke-restMethod `
        -uri "$ServerAddress/api/HomeAutomation.HomeGenie/Automation/Scheduling.Disable/$($schedule.Name)" `
        -verbose:$false
}


# Create Groups - this will add duplicates!
write-verbose "Creating Groups"
$null = invoke-restMethod `
    -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/Groups.Add/Control/") `
    -ContentType 'application/x-www-form-urlencoded' `
    -Body "AGroupName" `
    -Method Post `
    -verbose:$false

# Modify group
# send json to http://192.168.0.81/api/HomeAutomation.HomeGenie/Config/Groups.Save/

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

# $null = invoke-restMethod `
#     -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/Groups.Save/") `
#     -Body $exampleJson `
#     -Method Post `
#     -verbose:$false

######################### Restart ##########################
# invoke-restMethod -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/System.Configure/Service.Restart/")


# Backup
write-verbose "Backing up $ServerIp"
$OutputFolder = "\\Iomega\Data\Homegenie\Backups" # Change this to the place where you want to save backups to.
$outputFile = "{0}\homegenie_backup_config_{1}_{2}.zip" -f $OutputFolder, ($ServerIp.Split(".")[3]), (get-date -uformat "%d-%m-%Y_%H-%M-%S")

$null = Invoke-WebRequest `
    -Uri "$ServerAddress/api/HomeAutomation.HomeGenie/Config/System.Configure/System.ConfigurationBackup" `
    -OutFile $outputFile `
    -verbose:$false

write-verbose "Backed up $serverIP to $outputFile"

# Install Package


#$packageUrl = "https://raw.githubusercontent.com/genielabs/homegenie-packages/master/packages/AVR/Yamaha%20AVR"
#$packageUrl = "https://raw.githubusercontent.com/genielabs/homegenie-packages/master/packages/Irrigation%20Control/Garden%20Sprinkler%20System"
$packageUrl = "https://raw.githubusercontent.com/genielabs/homegenie-packages/master/packages/Security/Antijamming"

write-verbose "Installing package from $packageUrl"

invoke-restMethod `
    -Uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/Package.Install/{0}" -f [System.Web.HttpUtility]::UrlEncode($packageUrl)) `
    -verbose:$false

#     http://192.168.0.81/api/HomeAutomation.HomeGenie/Config/Package.Install/https%3A%2F%2Fraw.githubusercontent.com%2Fgenielabs%2Fhomegenie-packages%2Fmaster%2Fpackages%2FAVR%2FYamaha%2520AVR
######################### TODO ##########################



# event history

# HG.WebApp.Store.set('UI.EventsHistory', true);

# /Config/System.Configure/SystemLogging.Disable/
# /Config/System.Configure/SystemLogging.Enable/
# /Config/System.Configure/SystemLogging.IsEnabled/

