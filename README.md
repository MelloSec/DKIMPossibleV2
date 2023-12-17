# DKIMPossibleV2
Proof-of-Concept tool that onboards your Namecheap domain to Office 365 using MSOL and EXO modules, then spins up the required mail security records to get you up to cruising speed. 

Deploy script creates your deployment from templates folder, replaces values and kicks off powershell and terraform.

Sets DKIM signing config after your domain is verified in the portal. Will pause for however long you need.

State is stored in a DigitalOcean S3 backend. Script will ask your your keys when needed. Local deployment is not supported but should work, may be a little buggy, though. 


## Usage
I made this as easy as possible because of my own shortcomings. This is what it takes, this is what it expects. Modify this as you see fit, the values will be passed from the Deploy script to the Gen-Whatever scripts to create the templates. Runs from .\Deploy\, which is deleted and recreated each run.

### Generate a new Key Vault, use an S3 backend to onboard a domain, onboard your domain and verify
```powershell
$params = @{
    s3enabled = $true # only supported way right now
    genKeyVault = $true
    BUCKET = "mrbucket"
    BUCKETKEY = "dkimpossiblev2"
    BUCKETREGION = "us-east-1"
    BUCKETENDPOINT = "nyc3"
    VAULTNAME = "sorrowsettc2"
    VAULTGROUP = "sorrowsettc2"    
    DOMAINNAME = "phishery"
    DOMAINSUFFIX = "org"
    DOMAIN = "phishery.org"
    DEFAULTTENANTSUBDOMAIN = "x666x" # the XXXXX.onmicrosoft.com subd
}
.\Deploy.ps1 @params
```
