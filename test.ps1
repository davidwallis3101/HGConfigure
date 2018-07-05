# $interfaces = invoke-restMethod `
#      -uri ("http://192.168.0.161/api/HomeAutomation.HomeGenie/Config/Interfaces.ListConfig/") `
#      -verbose:$false

invoke-restMethod `
    -uri ("http://192.168.0.161/api/MIGService.Interfaces/HomeAutomation.TradfriInterface/IsEnabled.Set/1/") `
    -verbose:$false