param(
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKET,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKETKEY,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKETREGION,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKETENDPOINT
)

# Check and create .\Deploy directory if it doesn't exist
$deployPath = ".\Deploy"
if (-not (Test-Path -Path $deployPath)) {
    New-Item -ItemType Directory -Path $deployPath
}

# Copy backend.tf template to .\Deploy
$templatePath = ".\templates\backend.tf"
$deployFilePath = Join-Path $deployPath "backend.tf"
Copy-Item -Path $templatePath -Destination $deployFilePath

# Function to replace placeholder in file
function Replace-PlaceholderInFile {
    param($filePath, $placeholder, $value)
    Write-Output "Replacing $placeholder with $value in $filePath"
    
    # Read the file content
    $content = Get-Content -Path $filePath -Raw

    # Replace the content
    $newContent = $content -replace "<<<$placeholder>>>", $value

    # Write the new content back to the file
    Set-Content -Path $filePath -Value $newContent

    # Output the updated content for debugging
    Write-Output "Updated content of $filePath"
    Get-Content -Path $filePath
}

# Replace placeholders with parameter values
if ($BUCKET) { Replace-PlaceholderInFile -filePath $deployFilePath -placeholder "BUCKET" -value $BUCKET }
if ($BUCKETKEY) { Replace-PlaceholderInFile -filePath $deployFilePath -placeholder "BUCKETKEY" -value $BUCKETKEY }
if ($BUCKETREGION) { Replace-PlaceholderInFile -filePath $deployFilePath -placeholder "BUCKETREGION" -value $BUCKETREGION }
if ($BUCKETENDPOINT) { Replace-PlaceholderInFile -filePath $deployFilePath -placeholder "BUCKETENDPOINT" -value $BUCKETENDPOINT }





# Pip
# $params = @{
#     BUCKET = "myBucketName"
#     BUCKETKEY = "myBucketKey"
#     BUCKETREGION = "myBucketRegion"
#     BUCKETENDPOINT = "myBucketEndpoint"
# }

# $params | .\Gen-BackEnd.ps1
