param(
    # Define all parameters that might be used
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKET,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKETKEY,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKETREGION,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$BUCKETENDPOINT,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$VAULTNAME,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$VAULTGROUP,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$DOMAINNAME,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$DOMAINSUFFIX,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$DEFAULTTENANTSUBDOMAIN,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [string]$DOMAIN,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [switch]$genKeyVault,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [bool]$s3enabled = $true

)

function Run-ScriptWithParams {
    param($ScriptPath, $Params)
    & $ScriptPath @Params
}

# Prepare parameter sets for each script
$ParamsKeyVault = @{
    VAULTNAME = $VAULTNAME
    VAULTGROUP = $VAULTGROUP

}

$ParamsBackend = @{
    BUCKET = $BUCKET
    BUCKETKEY = $BUCKETKEY
    BUCKETREGION = $BUCKETREGION
    BUCKETENDPOINT = $BUCKETENDPOINT
}

# Check and create .\Deploy directory if it doesn't exist
$deployPath = ".\Deploy"
if(Test-Path $deployPath) { Remove-Item $deployPath -Recurse -Force}
if (-not (Test-Path -Path $deployPath)) {
    New-Item -ItemType Directory -Path $deployPath -Force
}
if ($genKeyVault)
{ Run-ScriptWithParams ".\Gen-KeyVault.ps1" $ParamsKeyVault }

if ($s3enabled)
{
    Run-ScriptWithParams ".\Gen-Backend.ps1" $ParamsBackend
}

Set-Location -Path $deployPath

# # Install Modules
if(!(Get-Module MSOnline)){Install-Module -Name MSOnline -Confirm:$false -Force }
# Check if MSOnline module is loaded, import it if not
if (!(Get-Module -Name MSOnline)) {
    Import-Module MSOnline
}

if(!(Get-Module ExchangeOnlineManagement)){ Install-Module -Name ExchangeOnlineManagement -Confirm:$false -Force }
# Check if ExchangeOnlineManagement module is loaded, import it if not
if (!(Get-Module -Name ExchangeOnlineManagement)) {
    Import-Module ExchangeOnlineManagement
}
        
# Ask the user if they want to connect to MSOL and Exchange Online
$userChoice = Read-Host "Do you want to connect to MSOL and Exchange Online? (Y/N)"

if ($userChoice -eq "y" -or $userChoice -eq "Y") {
    # Connect to MSOL
    Write-Output "Connecting to MSOL"
    Connect-MsolService

    # Connect to Exchange Online
    Write-Output "Connecting to Exchange Online"
    Connect-ExchangeOnline 
} else {
    # User chose not to connect
    Write-Output "Skipping connection steps to O365, assumes you're already signed in."
}


    
    # Create the new domain
    function Create-Domain($domain){
        if(!(Get-MsolDomain -domainname $domain -ErrorAction SilentlyContinue))
    {
        Write-Host "Domain not found, creating new custom domain"
        New-MsolDomain -Name $domain
    }
    Get-MsolDomainVerificationDns -DomainName $domain -Mode DnsTxTRecord
    }
   
    $dom = Create-Domain $domain
    
    # Retrieve Verification record from domain creation
    $ver = $dom.Text
    Write-Output $dom.Text
    Write-Output "Use $ver to verify DNS for your domain." 
    $MSVERIFICATION = $ver   

    $ParamsMain = @{
        DOMAINNAME = $DOMAINNAME
        DOMAINSUFFIX = $DOMAINSUFFIX
        MSVERIFICATION = $MSVERIFICATION
        DEFAULTTENANTSUBDOMAIN = $DEFAULTTENANTSUBDOMAIN
    }
    Run-ScriptWithParams "..\Gen-Main.ps1" $ParamsMain

    $ParamsProviders = @{

        VAULTNAME = $VAULTNAME
        VAULTGROUP = $VAULTGROUP
    }
    Run-ScriptWithParams "..\Gen-Providers.ps1" $ParamsProviders

    if ($s3enabled){
        $AWS_ACCESS_KEY_ID = Read-Host "Enter DigitalOcean S3 Key ID" -AsSecureString
        
        $AWS_SECRET_ACCESS_KEY = Read-Host "Enter DigitalOcean S3 Secret Access Key" -AsSecureString
        
        # Convert SecureString to Plain Text (for temporary use)
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AWS_ACCESS_KEY_ID)
        $PlainAWS_ACCESS_KEY_ID = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AWS_SECRET_ACCESS_KEY)
        $PlainAWS_SECRET_ACCESS_KEY = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        
        # Configure AWS CLI
        aws configure set aws_access_key_id $PlainAWS_ACCESS_KEY_ID --profile digitalocean
        aws configure set aws_secret_access_key $PlainAWS_SECRET_ACCESS_KEY --profile digitalocean
        aws configure set default.region us-east-1 --profile digitalocean
        
        $env:AWS_PROFILE="digitalocean"
        # export AWS_PROFILE=digitalocean
        
        # Initialize and copy tf to backend
        # terraform init -migrate-state
        # terraform init -reconfigure
        terraform init -force-copy
        terraform plan
        terraform apply
        }
        else {

            $env:AWS_ACCESS_KEY_ID = $null
            $env:AWS_SECRET_ACCESS_KEY = $null
            $env:AWS_SESSION_TOKEN = $null
            

            terraform init -reconfigure
            terraform plan
            terraform apply
        }
        
    
    # Enable DKIM for the tenant
    Read-Host "Verify your domain in the AzureAd portal > custom domains > domain > 'Verify', otherwise it may take a bit before you can perform DKIM validation. Press any key to continue."
    
    Read-Host "Ready for DKIM?! I'm excited for you. Any key for yes, ctrl+c to cancel."
    Write-Output "Creating a new DKIM signing configuration for $domain."
    New-DkimSigningConfig -DomainName $domain -Enabled $true

    Write-Output "Turning on DKIM signing for $domain"
    Set-DkimSigningConfig -Identity $domain -Enabled $true




