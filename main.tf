locals {
  users = { for user in csvdecode(file("./users.csv")) : user.username => user }
}

data "cloudflare_zone" "syoi" {
  name = "syoi.org"
}

resource "cloudflare_access_application" "code_server" {
  for_each = local.users
  zone_id  = data.cloudflare_zone.syoi.id
  name     = "code-server (${each.key})"
  domain   = "${cloudflare_record.code_server.hostname}/${each.key}"
  type     = "self_hosted"
}

resource "cloudflare_access_policy" "code_server_indiv_access" {
  for_each       = local.users
  application_id = cloudflare_access_application.code_server[each.key].id
  zone_id        = data.cloudflare_zone.syoi.id
  name           = "code-server Individual Access (${each.key})"
  precedence     = "1"
  decision       = "allow"

  include {
    email = [each.value.email]
  }
}

resource "random_password" "tunnel_secret" {
  length = 24
}

resource "cloudflare_tunnel" "code_server" {
  account_id = data.cloudflare_zone.syoi.account_id
  name       = "code-server"
  secret     = base64encode(random_password.tunnel_secret.result)
}

resource "cloudflare_record" "code_server" {
  zone_id = data.cloudflare_zone.syoi.id
  name    = "code-v2"
  value   = "${cloudflare_tunnel.code_server.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "proxmox_vm_qemu" "syoi" {
  name = "syoi-code"
  desc = "VM instance for hosting code.syoi.org"

  target_node = "pve"
  vmid        = 501

  clone = "null"

  bios  = "ovmf"
  agent = 1

  memory  = 4096
  balloon = 2048
  sockets = 1
  cores   = 4
  cpu     = "host"
  scsihw  = "virtio-scsi-pci"

  disk {
    type    = "scsi"
    storage = "local-lvm"
    size    = "32G"
    format  = "raw"
  }

  network {
    model  = "virtio"
    bridge = "vmbr2"
  }

  // manually plug in custom Nix ISO and deploy NixOS config flake
  oncreate         = false
  automatic_reboot = false
}

resource "tfe_workspace" "code-syoi-org" {
  name         = "code-syoi-org"
  organization = "syoi-org"
}
