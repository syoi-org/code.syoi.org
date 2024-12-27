terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.48.0"
    }
    proxmox = {
      source  = "Telmate/proxmox"
      version = "2.9.13"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.42.0"
    }
  }
  cloud {
    organization = "syoi-org"

    workspaces {
      name = "code-syoi-org"
    }
  }
}

provider "tfe" {
}

provider "cloudflare" {
}
