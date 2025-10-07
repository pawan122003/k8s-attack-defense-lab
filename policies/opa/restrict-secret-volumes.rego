package kubernetes.admission

deny[msg] {
  input.request.kind.kind == "Pod"
  vol := input.request.object.spec.volumes[_]
  vol.secret.name != ""
  msg := sprintf("Mounting of secrets is not allowed: %v", [vol.secret.name])
}
