param(
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$DOMAINNAME,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$DOMAINSUFFIX,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$VMNAME,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$AZREGION
)

# Check and create .\Deploy directory if it doesn't exist
$deployPath = ".\Deploy"
if (-not (Test-Path -Path $deployPath)) {
    New-Item -ItemType Directory -Path $deployPath
}

# Copy main.tf template to .\Deploy
$templatePath = ".\templates\main.tf"
$deployFilePath = Join-Path $deployPath "main.tf"
Copy-Item -Path $templatePath -Destination $deployFilePath -Force

# Function to replace placeholder in file
function Replace-PlaceholderInFile {
    param($filePath, $placeholder, $value)
    (Get-Content $filePath) -replace "<<<$placeholder>>>", $value | Set-Content $filePath
}

# Replace placeholders with parameter values
# if($DOMAINNAME) { Write-Output "Value of domainname is:"  "$DOMAINNAME" }
# if ($DOMAINNAME) { Replace-PlaceholderInFile -filePath $deployFilePath -placeholder "DOMAINNAME" -value $DOMAINNAME }
# if ($VMNAME) { Replace-PlaceholderInFile -filePath $deployFilePath -placeholder "VMNAME" -value $VMNAME }
# if ($AZREGION)  { Replace-PlaceholderInFile -filePath $deployFilePath -placeholder "AZREGION" -value $AZREGION }

Write-Output "Value of domainname is:"  "$DOMAINNAME" 
Replace-PlaceholderInFile -filePath $deployFilePath -placeholder "DOMAINNAME" -value $DOMAINNAME 
Replace-PlaceholderInFile -filePath $deployFilePath -placeholder "VMNAME" -value $VMNAME 
Replace-PlaceholderInFile -filePath $deployFilePath -placeholder "AZREGION" -value $AZREGION 
Replace-PlaceholderInFile -filePath $deployFilePath -placeholder "DOMAINSUFFIX" -value $DOMAINSUFFIX




# pipeline USage
# $params = @{
#     DOMAINNAME = "exampledomain"
#     VMNAME = "myvm"
#     AZREGION = "eastus"
# }

# $params | .\Gen-Main.ps1
