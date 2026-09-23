# Telemetry removal and upstream review

Audited upstream main on 2026-09-23:
[`1270eeb5425c`](https://github.com/mongodb-js/mongosh/tree/1270eeb5425c13c10f9b25241cff43c1c4b82e6f).

The previous patch replaced the CLI analytics sink and device-ID function, but
that was incomplete. `logging-and-telemetry.ts` still collected command counts,
sequences, session timing, connection and Identify events, detected agent
environments, and wrote full telemetry payloads to local logs. The HTTP client,
queues and throttle persistence code were still exported by the logging package.
Update requests carried OS information in their User-Agent.

The expanded checksum-verified patch removes:

- The HTTP telemetry client, compressed Cookie payloads, and event schemas.
- Analytics queues, forwarding targets, throttle files, and session collectors.
- API/session telemetry emitters and agent-environment detection.
- Device/OS fingerprint collection and the three fingerprinting dependencies,
  including their package-lock entries and native-addon build registration.
- Automatic upstream update/marketing requests and cached marketing messages.

Historical interface names and inert compatibility commands remain. In
particular, `enableTelemetry()` and `disableTelemetry()` report that telemetry
has been removed. Configuration reads report false/empty, and attempts to enable
telemetry or configure an endpoint fail. Environment settings and old config
files cannot restore the removed implementation. Help text describes this.

Local diagnostic logs, shell history, database connections, authentication,
user scripts and snippet downloads remain normal shell features. They are not a
telemetry transport. Snippet-index retrieval can happen at interactive startup;
set `snippetIndexSourceURLs` to an empty string to disable snippets. Remaining
shell HTTP requests carry only the mongosh version in the added User-Agent,
without a device ID or OS fingerprint. This fork is not an offline shell or a
network sandbox for user scripts.

## Build gates

`releases/telemetry-audit.json` records SHA-256 hashes of the reviewed, patched
source, build configuration and scripts, package manifests and dependency lock.
Both source preparation and bundle building compare the file inventory and
hashes before dependency installation. Ordinary source/dependency drift warns.
Automated indicator checks stop on known hashes, new suspicious keywords and new
URL literals; no whole-source review or AI approval is required. Build from a
fresh source checkout because compilation changes generated files.

The production bundle is scanned for the removed implementation signatures,
including those coming from dependencies. Packaging repeats this check so a
cached pre-fix bundle is rejected. This scan supplements source review; keyword
absence alone is not proof that arbitrary new code cannot collect data.

When upstream changes, the automated indicator checks identify evidence in the
changed source. Legitimate URLs/keywords can be recorded in the baseline as
ordinary configuration. Release commands do not silently approve findings.


## Verification

`bash tests/workflow-logic.sh` runs offline patch application, no-op sink,
local-logging, negative source-change, dependency-change and packaging tests.
The unchanged upstream fixture includes the entire patch surface.

`releases/build-bundle.sh` also runs `tests/telemetry-runtime.test.mjs` against
the actual webpack bundle. It starts eval and REPL sessions with old enabled
config, an endpoint environment override and an agent environment. It tries both
compatibility commands and config setters, checks normal JavaScript evaluation,
and checks for telemetry log records and throttle files. A preload hook records
outbound request attempts even if the application catches the resulting error.
Snippets are disabled for this test to isolate background telemetry requests.
The test uses an isolated home path without changing the user's HOME.

The September 23 validation used Node.js 26.9.0 and npm 12.0.2: patch application,
source audit, dependency installation, all 18 CLI workspaces, webpack bundle,
version readback, and both runtime sessions passed. Webpack emitted optional
module warnings. Platform archives and database-connected sessions were not run.

The earlier patch-context fix's local compilation used an unpatched source
directory: git apply inherited the enclosing repository and skipped its paths.
The patch fixture tests were valid. This audit corrected the validation setup:
each extracted source gets its own Git repository, patch application is checked,
and the patched source hashes must match before building.

Both release workflows explicitly name their telemetry-checked bundle build.
Source and artifact failures now print `::error::Telemetry audit failed`;
runtime regression failures also produce an error annotation and stop packaging.
An empty bundle is rejected. Both packaging paths continue to scan the downloaded
JavaScript before fetching a runtime. Local audit tests and compiled eval/REPL
network-guard tests passed again with these gates.


## Best-effort release indicator policy

Source and lockfile hash changes alone now warn. New suspicious keywords,
known telemetry/security hashes, or new URL literals stop source checks;
existing bundle signatures and runtime network checks remain enforced.
No AI approval or comprehensive source review is required. See
[release checks](../../releases/README-release.md) for allowlist configuration.
