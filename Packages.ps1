Function Get-Package {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        $Domain,

        $Server,

        $port = 80
    )

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $results = Invoke-RestMethod `
        -uri "https://api.github.com/repos/bounz/homegenie-packages/contents/packages"


    ForEach ($package in $results.GetEnumerator()){
        $package
    }
}


Function Install-Package {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        $Domain,

        $Server,

        $port = 80,

        $Package
    )
    if ($PSCmdlet.ShouldProcess($Package)) {
        Invoke-RestMethod `
            -uri ("http://{0}:{1}/api/HomeAutomation.HomeGenie/Config/Package.Install/$Package" -f $Server, $Port)
    }
}

Install-Package -Server 192.168.0.161 -Package "https%3A%2F%2Fraw.githubusercontent.com%2FBounz%2Fhomegenie-packages%2Fmaster%2Fpackages%2FIrrigation%2520Control%2FGarden%2520Sprinkler%2520System"