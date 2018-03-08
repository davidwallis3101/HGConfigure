# [string]$scriptFile = Get-Content "c:\users\davidw\desktop\Advanced_Smart_Lights.hgx" -Raw
# Add-Type -AssemblyName System.Web
# $decoded = [System.Web.HttpUtility]::HtmlDecode($scriptFile)

# $decoded

[xml]$scriptFile = Get-Content "c:\users\davidw\desktop\test.hgx"
#$Startup = $scriptFile.SelectNodes("/ProgramBlock/ScriptCondition").Inn
$Startup = $scriptFile.SelectSingleNode("/ProgramBlock/ScriptCondition").InnerText
$Source = $scriptFile.SelectSingleNode("/ProgramBlock/ScriptSource").InnerText

write-host "Startup:"
write-host $Startup
write-host "`n`n Main:"
write-host $Source
