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

clear-host

$ServerAddress = ("{0}://{1}:{2}" -f $proto, $ServerIp, $port)

$VerbosePreference = "Continue"

########################## Programs ##########################
# Getting Programs
$programs = invoke-restMethod `
    -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Automation/Programs.List/") `
    -verbose:$false


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
         -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Automation/Programs.Delete/$($program.Address)")`
         -verbose:$false
}

########################## Groups ##########################
# Get groups
$groups = invoke-restMethod `
    -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/Groups.List/Control/") `
    -verbose:$false

write-verbose "Deleting groups with no modules"
foreach ($group in $groups) {
  if ($group.Modules.Count -eq 0) {
      write-verbose ("Deleting group: [{0}]" -f $group.Name)
      $null = invoke-restMethod `
          -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/Groups.Delete/Control/") `
          -ContentType 'application/x-www-form-urlencoded' `
          -Body $group.Name `
          -Method Post `
          -verbose:$false
  }
}

# Delete Color lights group
write-verbose "Deleting color lights group"
$null = invoke-restMethod `
    -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/Groups.Delete/Control/") `
    -ContentType 'application/x-www-form-urlencoded' `
    -Body "Color Lights" `
    -Method Post `
    -verbose:$false


$automationGroups = invoke-restMethod `
    -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/Groups.List/Automation/") `
    -verbose:$false

# Getting Programs again
$programs = invoke-restMethod `
-uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Automation/Programs.List/") `
-verbose:$false

foreach ($automationGroup in $automationGroups) {
  $programsInAutomationGroup = $programs | Where-Object {$_.Group -eq $automationGroup.Name}

  if ($programsInAutomationGroup.Count -eq 0) {
      write-verbose ("Removing automation group {0} as it has no programs" -f $automationGroup.Name)
      $null = invoke-restMethod `
          -uri ("$ServerAddress/api/HomeAutomation.HomeGenie/Config/Groups.Delete/Automation/") `
          -ContentType 'application/x-www-form-urlencoded' `
          -Body $automationGroup.Name `
          -Method Post `
          -Verbose:$false
  }
}

########################## Set Location ##########################

$locationData = @{
    'name' = "Leeds, UK";
    'latitude' = 53.8003459;
    'longitude' = -1.5497609000000239;
}

write-verbose "Setting location"
$null = invoke-restMethod `
    -uri "$ServerAddress/api/HomeAutomation.HomeGenie/Config/System.Configure/Location.Set/" `
    -body (convertto-json $locationData -compress) `
    -Method POST `
    -verbose:$false


# Disable Interfaces
$interfacesToDisable = @(
    @{Domain = "Protocols.UPnP"},
    @{Domain = "HomeAutomation.ZWave"},
    @{Domain = "HomeAutomation.X10"}
)

foreach ($interface in $interfacesToDisable) {
    write-verbose ("Disabling interface: {0}" -f $interface.Domain)
    $null = invoke-restMethod `
         -uri ("$ServerAddress/api/MIGService.Interfaces/$($interface.Domain)/IsEnabled.Set/0/") `
         -verbose:$false
}
# TODO Delete interfaces

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


# Create Devices Group
# Check it exists prior

# http://192.168.0.161/api/HomeAutomation.HomeGenie/Config/Groups.Add/Control/
# add presence detection modules to group
# Modify full json and post back
#http://192.168.0.161/api/HomeAutomation.HomeGenie/Config/Groups.Save/

# Name virtual module
# http://192.168.0.161/api/HomeAutomation.HomeGenie/Config/Modules.Update/
# update json