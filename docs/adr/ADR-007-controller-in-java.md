# ADR-007 · Controller in Java 21

Status: proposed, awaiting confirmation

## Context

The controller talks to Ranger, Trino, OpenMetadata and Keycloak over REST and
JDBC. Ranger's client library and policy model, Trino's JDBC driver and
OpenMetadata's Java SDK are all Java. Go would give a single static binary and a
smaller runtime image.

## Decision

Java 21, Maven, one executable jar that runs as CLI and as daemon, packaged in a
distroless image. Ranger's own model classes are reused to avoid re-typing its
policy JSON. Picocli for the command line.

## Consequences

- Reuse of Ranger and OpenMetadata client code shortens M1.
- Image size and startup time are worse than Go. Acceptable for a controller that
  runs as a daemon and in CI, not on a laptop hot path.
- Integration tests use Testcontainers to bring up the whole stack.

## Alternatives

Go with hand-written clients: cleaner binary, more code to write for the Ranger
model, revisit if the Java toolchain becomes a contributor barrier.
