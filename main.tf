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

resource "cloudflare_access_application" "code_server_ssh" {
  zone_id = data.cloudflare_zone.syoi.id
  name    = "code-server (SSH access)"
  domain  = cloudflare_record.code_server_ssh.hostname
  type    = "ssh"
}

resource "cloudflare_access_policy" "code_server_ssh_access" {
  application_id = cloudflare_access_application.code_server_ssh.id
  zone_id        = data.cloudflare_zone.syoi.id
  name           = "code-server SSH Access"
  precedence     = "1"
  decision       = "allow"

  include {
    email = [for user in local.users : user.email]
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
  name    = "code"
  content = "${cloudflare_tunnel.code_server.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "code_server_ssh" {
  zone_id = data.cloudflare_zone.syoi.id
  name    = "ssh"
  content = "${cloudflare_tunnel.code_server.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "leaderboard" {
  zone_id = data.cloudflare_zone.syoi.id
  name    = "leaderboard"
  content = "${cloudflare_tunnel.code_server.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "git" {
  zone_id = data.cloudflare_zone.syoi.id
  name    = "git"
  content = "${cloudflare_tunnel.code_server.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_r2_bucket" "forgejo" {
  account_id = data.cloudflare_zone.syoi.account_id
  name       = "forgejo-data"
}

resource "cloudflare_r2_bucket" "forgejo-repo" {
  account_id = data.cloudflare_zone.syoi.account_id
  name       = "forgejo-repo"
}

resource "cloudflare_r2_bucket" "forgejo-litestream" {
  account_id = data.cloudflare_zone.syoi.account_id
  name       = "forgejo-litestream"
}

# resource "proxmox_vm_qemu" "syoi" {
#   name = "syoi-code"
#   desc = "VM instance for hosting code.syoi.org"

#   target_node = "pve"
#   vmid        = 501

#   clone = "null"

#   bios    = "ovmf"
#   qemu_os = "l26"
#   agent   = 1

#   memory  = 4096
#   balloon = 2048
#   sockets = 1
#   cores   = 4
#   cpu     = "host"
#   scsihw  = "virtio-scsi-pci"

#   disk {
#     type    = "scsi"
#     storage = "local-lvm"
#     size    = "64G"
#     format  = "raw"
#   }

#   network {
#     model  = "virtio"
#     bridge = "vmbr2"
#   }

#   // manually plug in custom Nix ISO and deploy NixOS config flake
#   oncreate         = false
#   automatic_reboot = false
# }

resource "tfe_workspace" "code-syoi-org" {
  name           = "code-syoi-org"
  organization   = "syoi-org"
  execution_mode = "local"
}
