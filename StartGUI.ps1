Import-Module Microsoft.Online.SharePoint.PowerShell
Import-Module -name "$PSScriptRoot\FlexdeskBlueprint" -Verbose
Start-FlexdeskDeploymentGUI -NoUpdateCheck
