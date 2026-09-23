# Remove telemetry implementation

Applies to every target. Removes collection, HTTP transmission, queues,
identification, throttle persistence, API/session emitters, agent detection and
automatic upstream update/marketing requests. Removes fingerprinting dependencies
from both the package manifest and lockfile. Compatibility commands stay inert;
normal local diagnostics, database connections and snippet features remain.

The patch also provides the existing writable-home fallback for containers.
It applies strictly to the reviewed upstream source; incompatible hunks fail.

See [Telemetry audit](../../docs/Design/Telemetry-audit.md) for the source review,
build gates, remaining non-telemetry network features and verification limits.
Run `bash tests/workflow-logic.sh`; the bundle builder additionally exercises the
compiled CLI with enabled telemetry settings and intercepted outbound requests.
