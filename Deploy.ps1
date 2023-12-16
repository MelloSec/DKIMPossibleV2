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

# Install Modules
if(!(Get-Module MSOnline)){Install-Module -Name MSOnline -Confirm:$false -Force
    Import-Module MSOnline}
    
    
    if(!(Get-Module ExchangeOnlineManagement)){ Install-Module -Name ExchangeOnlineManagement -Confirm:$false -Force }
    Import-Module ExchangeOnlineManagement
    
    # Connect to MSOL and Exchange Online
    Connect-MsolService
    Connect-ExchangeOnline 

    # Create the new domain
    function Create-Domain($domain){
        if(!(Get-MsolDomain -domainname $domain -ErrorAction SilentlyContinue))
    {
        Write-Host "Domain not found, creating new custom domain"
        New-MsolDomain -Name $domain
    }
    Get-MsolDomainVerificationDns -DomainName $domain -Mode DnsTxTRecord
    }
    $domain = $DOMAINNAME.$DOMAINSUFFIX
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
    

    Run-ScriptWithParams ".\Gen-Main.ps1" $ParamsMain

    terraform init
    terraform plan
    terraform apply
    
    # Enable DKIM for the tenant
    Read-Host "Verify terraform applied your records. Press any key to continue."
    
    Write-Output "Enabling DKIM."
    New-DkimSigningConfig -DomainName $domain -Enabled $true
    Set-DkimSigningConfig -Identity $domain -Enabled $true




