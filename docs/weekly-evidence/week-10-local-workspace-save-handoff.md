# Local Workspace Save: Implementation and Handoff

Implementation date: 2026-08-04

## Delivered Behaviour

The dashboard now has a deliberately small UI for creating a named local copy of
the customer's current work:

1. Open **Utilities** in the workflow header.
2. Enter a value in **Workspace name** (`workspace_name`).
3. Select **Save workspace copy** (`save_workspace`).

The save is additive. An existing workspace is never overwritten. If the
normalised folder name already exists, the customer must choose another name.
The button shows a Shiny notification on success or failure, without exposing a
raw R error or local filesystem path.

## What Is Preserved

Each snapshot contains the state needed to represent the current scientific
workflow without serialising Shiny reactives or upload temp paths:

- the complete workflow artifact registry, including current/stale status,
  revisions, provenance, history, blocking reason, and next action;
- selected Task, saved Stage, and current main navigation panel;
- safe input values such as date ranges, join settings, analysis selection,
  model variables, HEV settings, and display choices;
- runtime revision markers and availability flags used by downstream
  invalidation rules;
- parsed uploads and canonical data products that are currently available;
- processed biology/environment/flow outputs, O:E results, flow statistics,
  joined and filtered analysis datasets, exclusion history, model result, and
  HEV-ready data where those objects exist.

File-upload input objects are intentionally excluded because their `datapath`
values point to temporary Shiny files. The parsed data are saved instead.

## Storage Layout

The default root is outside the repository and is resolved with:

```r
file.path(
  tools::R_user_dir("he-toolkit-dashboard", which = "data"),
  "workspaces"
)
```

It can be changed for a deployment with either:

```r
options(hetoolkit.workspace_root = "D:/approved/workspace/location")
```

or the `HE_TOOLKIT_WORKSPACE_ROOT` environment variable. The R option takes
precedence over the environment variable.

The local backend creates this structure:

```text
<workspace-root>/
  named/
    River-Avon-review/
      manifest.json
      manifest.rds
      state.rds
  objects/
    <md5-checksum>.rds
  .staging/
```

The customer-entered name remains in the manifest as `workspace_name`. A
cross-platform safe form becomes the directory name. Unicode letters and numbers
are preserved, spaces and unsafe path characters become hyphens, Windows
reserved names are prefixed, and input is never used directly as a path.

## Large-Data Design

`state.rds` contains only the relatively small workflow/session/input state.
Every dataset or model object is compressed separately and stored under its
checksum in `objects/`.

This has four important properties:

- a large table is not embedded in one monolithic session file;
- two named copies that contain byte-identical data share one stored object;
- the manifest records object checksum, compressed byte size, class, row count,
  column count, column names, and the workflow artifacts that own the object;
- state can be inspected with `dataset_names = character()` before large objects
  are loaded into memory.

The first save of a new large object still has to serialise and checksum it.
Later named copies avoid multiplying persistent storage, although they still
perform serialisation to prove that the object is unchanged.

## Atomicity and Integrity

Saving occurs in `<workspace-root>/.staging`. Dataset objects, state, both
manifests, and checksums are completed before the named directory is published
with a directory rename. A failed operation removes its staging directory and
does not create a valid-looking named workspace.

Loading checks the schema version, manifest structure, state checksum, every
requested object checksum, artifact IDs, statuses, Task ID, and Stage range.
Saving also rejects a registry that marks a critical scientific result current
when its required data object was not collected.
The restore helper then derives the resume Stage with `workflow_resume_stage()`;
it does not trust the Stage number stored at save time.

## Module Responsibilities

`R/workspace_state.R` owns the provider-neutral contract:

- `new_workspace_snapshot()`
- `validate_workspace_snapshot()`
- `prepare_workspace_for_restore()`
- `workspace_state_summary()`
- workspace-name validation and folder-name normalisation

`R/workspace_storage.R` owns persistence through S3 generics:

- `workspace_storage_save(storage, snapshot)`
- `workspace_storage_load(storage, workspace_name, dataset_names = NULL)`
- `workspace_storage_list(storage)`
- `workspace_storage_get_manifest(storage, workspace_name)`
- `workspace_storage_delete(storage, workspace_name)`
- `workspace_storage_prune_objects(storage)`

`server.R` is only the Shiny adapter. It collects currently available values,
builds a provider-neutral snapshot, and passes that snapshot to the configured
storage backend. `R/workflow_ui.R` contains only the name input and save button.

## Programmatic Restore

There is intentionally no restore UI in this change because the requested UI
scope is one input and one save button. The complete snapshot can already be
validated and read through the storage API:

```r
storage <- new_local_workspace_storage()

# Full integrity-checked load of state and all saved data objects.
snapshot <- workspace_storage_load(storage, "River Avon review")

# State-only load for inspection before large objects are read.
state_only <- workspace_storage_load(
  storage,
  "River Avon review",
  dataset_names = character()
)
```

The next restore task should apply `snapshot$state` to writable reactive values,
reconnect `snapshot$datasets` to the relevant server adapters, update supported
inputs with Shiny update functions, and navigate to the resume Stage returned by
`prepare_workspace_for_restore()`. Do not attempt to assign saved values directly
to existing `eventReactive()` expressions.

## Cloud Backend Extension Point

`new_cloud_workspace_storage(endpoint, auth_provider)` reserves the provider
configuration without coupling the dashboard to S3, Azure Blob Storage, Google
Cloud Storage, or another vendor. Its methods currently stop with a clear
"not configured" message.

To add cloud persistence, implement the same storage generics for class
`cloud_workspace_storage`. Keep `new_workspace_snapshot()` and the manifest
schema unchanged. A cloud implementation should map immutable checksum keys to
provider objects and named workspace manifests to small metadata objects. It
must provide atomic manifest publication or equivalent optimistic concurrency,
verify checksums after upload/download, and enforce authenticated per-customer
access and retention rules.

## Automated Tests

The implementation is covered by:

- `tests/testthat/test-workspace-state.R`: naming, schema validation, malformed
  state rejection, and resume-Stage derivation;
- `tests/testthat/test-workspace-storage.R`: complete round trip, manifest
  metadata, large-object deduplication, duplicate-name protection, lazy loading,
  corruption detection, delete, and orphan pruning;
- `tests/testthat/test-workflow-ui.R`: the minimal controls are rendered in the
  existing header;
- `tests/testthat/test-workflow-server.R`: the button creates a real named
  workspace and saves workflow, input, and runtime state.

Run the complete automated suite from the project root:

```powershell
Rscript tests/testthat.R
```

## Operational Notes

- A workspace may contain customer data and must be stored under the applicable
  data-handling and retention policy.
- Back up or move the whole workspace root. A directory under `named/` is not
  portable by itself because its large objects are shared through `objects/`.
- `manifest.json` is for inspection and non-R integrations. `manifest.rds` is
  the authoritative local manifest used by this backend.
- Keep schema migrations explicit. Do not silently reinterpret scientific
  fields when `workspace_schema_version` changes.
- When adding a new server-side data product, add a safe collector in
  `collect_current_workspace_datasets()` and extend round-trip coverage.
