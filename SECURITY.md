# Security policy

Tagward is security software. A flaw in the compiler or the applier can open access
to data that a policy says is protected. We treat reports accordingly.

## Reporting a vulnerability

Use GitHub's private vulnerability reporting on this repository:
**Security → Report a vulnerability**. Do not open a public issue.

Include the component, the version from `versions.yaml` or the controller
version, steps to reproduce, and the impact you observed. A minimal policy
repository and a conformance case that demonstrates the leak is the ideal report.

## What to expect

- Acknowledgement within 3 working days.
- A severity assessment and a plan within 10 working days.
- A fix released with a security advisory and credit to the reporter, unless you
  prefer to stay anonymous.

## Scope

- The controller: compiler, applier, propagation, bootstrap, CLI and daemon.
- Our Helm charts and container images.
- The compose stack's default configuration.

Vulnerabilities in upstream components, Trino, Ranger, OpenMetadata, Keycloak,
OpenSearch or PostgreSQL, should be reported to those projects. Tell us as well if
Tagward's default configuration makes the issue worse.

## Supported versions

Until 1.0, only the latest release receives fixes.
