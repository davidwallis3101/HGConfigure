# <Option Name="IPAddress" Value="192.168.0.14" />
# <Option Name="Port" Value="10001" />
# <Option Name="UDLPassword" Value="1234" />
# <Option Name="DontAutoReconnect" Value="False" />

# $null = invoke-restMethod `
# -uri ($Server + "/api/MIGService.Interfaces/HomeAutomation.TexecomInterface/IsEnabled.Set/0/") `
# -verbose:$false

# invoke-restMethod `
#     -uri ($Server + "/api/MIGService.Interfaces/HomeAutomation.TexecomInterface/Options.Get/UDLPassword/") `
#     -verbose:$true

Function Set-InterfaceOption {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        $Domain,

        $Server,

        $port = 80,

        $OptionName,

        $Value
    )
    if ($PSCmdlet.ShouldProcess($Domain)) {
        Invoke-RestMethod `
        -uri ("http://{0}:{1}/api/MIGService.Interfaces/{2}/Options.Set/{3}/{4}"-f $Server, $port, $Domain, $OptionName, $Value) `
            -verbose -DisableKeepAlive
    }
}

Function Enable-Interface {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        $Domain,

        $Server,

        $port = 80
    )
    if ($PSCmdlet.ShouldProcess($Domain)) {
        Invoke-RestMethod `
            -uri ("http://{0}:{1}/api/MIGService.Interfaces/{2}/IsEnabled.Set/1/"-f $Server, $port, $domain) `
            -verbose:$true
    }
}

Function Disable-Interface {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        $Domain,

        $Server,

        $port = 80
    )
    if ($PSCmdlet.ShouldProcess($Domain)) {
        Invoke-RestMethod `
            -uri ("http://{0}:{1}/api/MIGService.Interfaces/{2}/IsEnabled.Set/0/"-f $Server, $port, $domain) `
            -verbose:$true
    }
}

Function Get-InterfaceOption {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        $Domain,

        $Server,

        $port = 80,

        $OptionName
    )
    if ($PSCmdlet.ShouldProcess($Domain)) {
        Invoke-RestMethod `
            -uri ("http://{0}:{1}/api/MIGService.Interfaces/{2}/Options.Get/{3}" -f $Server, $port, $Domain, $OptionName) `
            -verbose -DisableKeepAlive
    }
}
# Disable-Interface -Server 192.168.0.161 -Domain HomeAutomation.TexecomInterface
# # Set-InterfaceOption -Server 192.168.0.161 -Domain HomeAutomation.TexecomInterface -OptionName IpAddress -Value 192.168.0.14
# # Enable-Interface -Server 192.168.0.161 -Domain HomeAutomation.TexecomInterface
# #Set-InterfaceOption -Server 192.168.0.161 -Domain HomeAutomation.TexecomInterface -OptionName IPAddress -Value 192.168.0.14
# Enable-Interface -Server 192.168.0.161 -Domain HomeAutomation.TexecomInterface


# Write-Host "------------"
# Start-sleep -seconds 5

#Get-InterfaceOption -Server 192.168.0.161 -Domain HomeAutomation.TexecomInterface -OptionName IPAddress

# /api/MIGService.Interfaces/HomeAutomation.TexecomInterface/Options.Get/IPAddress/
# /api/MIGService.Interfaces/Options.Get/IPAddress


/api/HomeAutomation.HomeGenie/Automation/Programs.Compile/