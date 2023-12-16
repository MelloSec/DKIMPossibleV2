[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $domain = "slyfox.cloud",
    [Parameter()]
    [string]
    $domName = "slyfox",
    [Parameter()]
    [string]
    $tld = "cloud",
    [Parameter()]
    [string]
    $onMicrosoft= "8n77wm",
    [Parameter()]
    [string]
    $spf = "20.232.123.123",
    [Parameter()]
    [string]
    $mail= "20.232.123.123",
    [Parameter()]
    [string]
    $inputFile= "NewNameCheapTemplate.tf",
    [Parameter()]
    [string]
    $file= "main.tf"
)


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
    $dom = Create-Domain $domain
    
    # Retrieve Verification record from domain creation
    $ver = $dom.Text
    Write-Output $dom.Text
    Write-Output "Use $ver to verify DNS for your domain."    
    
    # Modify template
    Write-Output "Starting Templater to replace the value for $file."    
    python3 Templater.py $inputFile -d $domName -t $tld -v $ver -o $onMicrosoft -s $spf -f $file
    
    # Clean up terraform template to avoid record conflicts
    $cleanup = ".\Resources"
    mkdir $cleanup
    mv $inputFile $cleanup
    mv Templater.py $cleanup
    
    # Terraform 
    # terraform init
    # terraform plan
    # terraform apply
    
    # Enable DKIM for the tenant
    Read-Host "Verify terraform applied your records. Press any key to continue."
    
    Write-Output "Enabling DKIM."
    New-DkimSigningConfig -DomainName $domain -Enabled $true
    Set-DkimSigningConfig -Identity $domain -Enabled $true