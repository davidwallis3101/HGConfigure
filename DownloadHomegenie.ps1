[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$release = (Invoke-WebRequest https://api.github.com/repos/bounz/Homegenie-BE/releases | ConvertFrom-Json) | Select-Object -First 1
$releaseVersion = ($release.tag_name -replace "V","")
$fileName = $release.assets |Where-Object {$_.Name -eq ("homegenie_{0}_all.deb" -f $releaseVersion)}
Write-host "Downloading Homegenie release: $releaseVersion"
$details = (Invoke-WebRequest $fileName.url |convertFrom-Json)
Invoke-WebRequest $details.browser_download_url -Out Homegenie-BE.deb
