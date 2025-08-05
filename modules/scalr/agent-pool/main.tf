terraform {
  required_providers {
    scalr = {
      source  = "scalr/scalr"
    }
  }
}

data "scalr_current_account" "this" {}

data "http" "scalr_allowlist" {
  url = "https://scalr.io/.well-known/allowlist.txt"
}

resource "scalr_agent_pool"  "webhook" {
  name        = var.agent_pool_name
}

resource "scalr_agent_pool_token" "webhook" {
  agent_pool_id = scalr_agent_pool.webhook.id
  description   = "Token for Scalr webhook agent"
}

locals {
  scalr_url = "https://${data.scalr_current_account.this.name}.scalr.io"
  # Split the response by newlines and filter out empty lines
  scalr_ips = [for ip in split("\n", trimspace(data.http.scalr_allowlist.response_body)) : "${ip}/32" if ip != ""]
}