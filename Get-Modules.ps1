<#
.SYNOPSIS
    Get-Modules

.DESCRIPTION
    Gets the modules for testing

.PARAMETER Server
    The hg server url

.EXAMPLE
    PS C:\> Configure.ps1 -Server "http://10.1.1.1:80"

.LINK
    https://github.com/davidwallis3101/HGConfigure
#>

[cmdletbinding()]
Param(
    [String]$ServerIp = "127.0.0.1",
    [int]$port = 80,
    [string] $proto = "http"
)


$ServerAddress = ("{0}://{1}:{2}" -f $proto, $ServerIp, $port)

$modules = invoke-restMethod `
    -uri "$ServerAddress/api/HomeAutomation.HomeGenie/Config/Modules.List" `
    -verbose:$false

foreach ($module in $modules) {
    write-host ("Module Name: {0}" -f $module.Name)
    $module |fl
}

