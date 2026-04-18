package kubernetes.admission

deny[msg] {
    input.request.kind.kind == "Pod"
    input.request.object.spec.securityContext.privileged == true
    msg := "Privileged containers are not allowed"
}

deny[msg] {
    input.request.kind.kind == "Pod"
    input.request.operation == "CREATE"
    contains_host_ipc(input.request.object)
    msg := "Host IPC sharing is not allowed"
}

deny[msg] {
    input.request.kind.kind == "Pod"
    input.request.operation == "CREATE"
    contains_host_network(input.request.object)
    msg := "Host network sharing is not allowed"
}

deny[msg] {
    input.request.kind.kind == "Pod"
    vol := input.request.object.spec.volumes[_]
    vol.hostPath != ""
    msg := sprintf("HostPath volumes are not allowed: %v", [vol.hostPath.path])
}

deny[msg] {
    input.request.kind.kind == "Pod"
    input.request.object.spec.containers[_].securityContext.capabilities.add[_] != ""
    msg := "Adding capabilities is not allowed"
}

deny[msg] {
    input.request.kind.kind == "Pod"
    input.request.object.spec.containers[_].securityContext.allowPrivilegeEscalation == true
    msg := "Privilege escalation must be disallowed"
}

deny[msg] {
    input.request.kind.kind == "Pod"
    input.request.object.spec.containers[_].securityContext.runAsNonRoot != true
    msg := "Containers must run as non-root"
}

contains_host_ipc(obj) {
    obj.spec.hostIPC == true
}

contains_host_network(obj) {
    obj.spec.hostNetwork == true
}