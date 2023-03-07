output "cloudflare_tunnel_secret" {
  description = "Tunnel certificate credentials file. To be encrypted with SOPS and stored in NixOS config."
  value = jsonencode({
    "AccountTag"   = data.cloudflare_zone.syoi.account_id
    "TunnelSecret" = base64encode(random_password.tunnel_secret.result)
    "TunnelID"     = cloudflare_tunnel.code_server.id
    "TunnelName"   = cloudflare_tunnel.code_server.name
  })
  sensitive = true
}
