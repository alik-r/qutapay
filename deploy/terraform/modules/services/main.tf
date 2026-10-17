locals {
  cfg = yamldecode(file("${path.module}/services.yaml"))

  # setproduct(["svc-a","svc-b"], ["prod"]) -> ["svc-a","prod"], ["svc-b","prod"]
  identities = {
    for p in setproduct(keys(local.cfg.services), local.cfg.envs) :
    "${p[0]}-${p[1]}" => merge(local.cfg.services[p[0]], { svc = p[0], env = p[1] })
  }

  # One secret per (secret, env): secret1-test, secret1-prod
  secret_names = toset(flatten([
    for id, i in local.identities : [for s in i.secrets : "${s}-${i.env}"]
  ]))

  # Grant maps below all have the same shape: 
  # flatten() builds a list of {key, identity, <object>}
  secret_grants = { for g in flatten([
    for id, i in local.identities : [for s in i.secrets : { key = "${id}/${s}", identity = id, secret = "${s}-${i.env}" }]
  ]) : g.key => g }

  publish_grants = { for g in flatten([
    for id, i in local.identities : [for t in i.publish : { key = "${id}/${t}", identity = id, topic = "${t}-${i.env}" }]
  ]) : g.key => g }

  subscribe_grants = { for g in flatten([
    for id, i in local.identities : [for s in i.subscribe : { key = "${id}/${s}", identity = id, sub = "${s}-${i.env}" }]
  ]) : g.key => g }
}

output "envs" { value = toset(local.cfg.envs) }
output "identities" { value = local.identities }
output "db_identities" { value = { for id, i in local.identities : id => i if i.db } }
output "secret_names" { value = local.secret_names }
output "secret_grants" { value = local.secret_grants }
output "publish_grants" { value = local.publish_grants }
output "subscribe_grants" { value = local.subscribe_grants }
