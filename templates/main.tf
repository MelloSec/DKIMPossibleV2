

variable "domain_name" {
  type = string
  default = "<<<DOMAINNAME>>>-<<<DOMAINSUFFIX>>>"
}

variable "domain_fqdn" {
  type = string
  default = "<<<DOMAINNAME>>>.<<<DOMAINSUFFIX>>>"
}


variable "verification_record" {
  description = "MS verification record"
  default = "<<<MSVERIFICATION>>>"
}

variable "o365_protection" {
  description = "Office 365 protection domain"
  default = "spf.protection.outlook.com"
}

variable "mail_protection" {
  description = "Mail protection domain"
  default = "mail.protection.outlook.com"
}

variable "onmicrosoft_domain" {
  type = string
  default = "<<<DEFAULTTENANTSUBDOMAIN>>>.onmicrosoft.com"
}

resource "namecheap_domain_records" "example" {
  domain = "${var.domain_fqdn}"
  mode = "merge"
  email_type = "MX"

  record {
    hostname = "@"
    type = "TXT"
    address = "${var.verification_record}"
  }

  record {
    hostname = "@"
    type     = "TXT"
    address  = "v=spf1 ip4:mail include:spf.protection.outlook.com ~all"
    ttl      = 1800
  }
// DMARC

record {
  type   = "TXT"
  ttl    = 1800
  hostname = "_dmarc"
  address = "v=DMARC1; p=none; rua=mailto:dmarc@${var.domain_name}; ruf=mailto:dmarc@${var.domain_name}"
}

  record {
    hostname = "@"
    type = "MX"
    address = "${var.domain_name}.${var.mail_protection}"
  }

  record {
    hostname = "selector1._domainkey"
    type = "CNAME"
    address = "selector1-${var.domain_name}._domainkey.${var.onmicrosoft_domain}"
  }

  record {
    hostname = "selector2._domainkey"
    type = "CNAME"
    address = "selector2-${var.domain_name}._domainkey.${var.onmicrosoft_domain}"
  }

  record {
    hostname = "autodiscover"
    type = "CNAME"
    address = "autodiscover.outlook.com"
  }

  record {
    hostname = "sip"
    type = "CNAME"
    address = "sipdir.online.lync.com"
  }

  record {
    hostname = "lyncdiscover"
    type = "CNAME"
    address = "webdir.online.lync.com"
  }

  record {
    hostname = "msoid"
    type = "CNAME"
    address = "clientconfig.microsoftonlines.net"
  }

  record {
    hostname = "enterpriseregistration"
    type = "CNAME"
    address = "enterpriseregistration.windows.net"
  }

  record {
    hostname = "enterpriseenrollment"
    type = "CNAME"
    address = "enterpriseenrollment-s.manage.microsoft.com"
  }


}


  





