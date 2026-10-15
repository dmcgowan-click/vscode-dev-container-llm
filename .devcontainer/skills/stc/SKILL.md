---
name: stc
description: Workflow for reading standard template construct (STC) definitions selected by a path, and either; A) review them, report back on potential ambiguity or design issues, and suggest improvements, B) generate code from them, C) align them, D) retro-fit them from the codebase. Triggers include "stc", "standard construct template", "review stc", "trigger stc", "retro stc"
author: Douglas McGowan
---

# STC Workflow

Select STC definitions by path and either; A) review them, report back on potential ambiguity or design issues, and suggest improvements, B) generate code from them, C) align them, D) retro-fit them from the codebase

## Requirements

Read / Write permissions to the `stc` folder. Typically located within the root of your repo, but locations can vary

## Helper Scripts

None yet defined

## Invocation

```
stc <path> <action>                     # every definition under <path>
stc <path> <subpath | file> <action>    # every definition under <path>/<subpath>, or the single <path>/<file>
```

* `<path>` and `<subpath>` are relative to the `stc` folder (e.g. `stacks`, `features`, `modules`)
* `<file>` may omit `.md` (e.g. `stc features organisation generate` = `stc/features/organisation.md`)
* `<action>`: `review`, `generate`, `align`, `retro`
* Word order between the path parts and the action is flexible (`stc stacks generate client` = `stc stacks client generate`)
* If the path or action can't be resolved, list the folders and files under `stc` and prompt the user

## Core Workflow

### 1. Locate STC folder and read context

Search for an `stc` folder within the repo. If a folder is not found, prompt the user to provide a path to the `stc` folder.

Once located:
* Always read `stc/GLOBAL.md`: language, tooling, framework requirements and conventions referenced by definitions. It may also describe the folder layout; follow it
* Resolve the selection (see Invocation) to a list of definition files. Any `resources/` folder holds reference assets, not definitions; read assets only when a definition references them
* **Monolithic fallback**: if `stc` has no definition folders, search for `DRAFT.md` or `DETAIL.md` in the `stc` folder. Read all that exist and combine their content to form the full STC catalogue. Definitions are `### <Name>` headers under a `## Stacks` or `## Modules` parent header. Monolithic structure only: all STCs must fall under one of these parent headers; report back if not, and halt until corrected

### 2. Classify each definition and determine applicable rules

A definition is one of:

* **Single-target definition**: declares one `* Type: <type>` and (optionally) a `* Location`. It owns everything at its location, except parts owned by cross-target definitions (below)
* **Cross-target definition**: declares `* Stacks: <name>, ...` (or `* Targets:`), naming other definitions it contributes to (e.g. a feature spanning a client and a backend). It must also list the files or parts of files it owns per target (e.g. `* Files`). Each target has its own section in the definition. For each target:
  * The target definition supplies the code location, language, tooling and shared conventions
  * The target's `Type` rules (below) apply to that part
  * A cross-target definition may declare its own `Type` (e.g. `feature`); this classifies it and needs no matching `## Type:` section unless GLOBAL defines one
* **Untyped definition** (no `Type` and no targets): apply all of GLOBAL.md, including parent sections matching the folder (e.g. `## Stacks` applies to every stack, `## Modules` to every module). This is the original behaviour and must be preserved for existing repos

Applying GLOBAL type rules:
* If GLOBAL.md contains `## Type: <type>` sections, apply the section matching the definition's (or target's) type, plus any section it inherits (e.g. "Inherits `typescript`"), plus any GLOBAL content not under a `## Type:` section. Ignore all other `## Type:` sections
* If the declared type has no matching section (and isn't a cross-target classification), report it and halt until corrected

Dependencies (`* Depends on:`) are read for context; their rules are not applied to the dependent's code unless it says so.

### 3. Confirm selection and action

If not decipherable from the user input, prompt for the path and action. Actions:
* Review: review the selected definitions, report potential ambiguity or design issues, and suggest improvements
* Generate: generate (or replace) code from the selected definitions
* Align: compare the selected definitions with each other and identify inconsistencies
* Retro: update the selected definitions to match the current codebase

### 4. Action STC

#### If action is review

Review each selected definition together with its applicable rules (step 2), report back on potential ambiguity or design issues, and suggest improvements. Offer to edit the definitions to make these updates.

The ideal state is where AI can create the codebase from the STC with minimal user inputs and will consistently create the codebase the same way based on the STC definition.

The definition (with applicable GLOBAL rules and, for cross-target definitions, its targets) should be self-sufficient to determine:
* The programming language / tooling to use
* The target code location (see Naming Conventions)
* Required dependencies (e.g. `package.json` contents, provider versions) where applicable
* Parent folder structure
* For cross-target definitions: which files or parts of files it owns in each target

If any of these cannot be determined, flag it as a review finding and suggest how to make the definition explicit.

Additional Context:

* Sensible environment-specific inputs (org ID, domain, project ID, etc.) are fine; these can never be predefined and will be unique to each environment. Do not flag as a review item
* Checking actual generated source code and config files is valid for the purpose of diff, but don't flag discrepancies as a review finding: the STC is the source of truth, not the generated code. The generated code may be out of date or have been modified by hand, so it is not a reliable source of truth
* Flag conflicts between a definition and the applicable GLOBAL rules, between a cross-target definition and its targets, and between definitions that claim ownership of the same resource, file part or Makefile target
* Flag content in a cross-target definition that is shared by others and belongs in a target definition (or GLOBAL), and content in a target definition that belongs to a single cross-target definition

#### If action is generate

Review the selected definitions; if there is potential ambiguity or design issues, report back and offer to perform a `review` action first.

Once acceptably reviewed, generate code:

1. **Order**: generate dependencies before dependents (`* Depends on:`), and a target's shared code before the cross-target parts that rely on it
2. **Determine output paths**: see Naming Conventions
3. **Replace what the definition owns**: if the target paths already exist, warn the user and confirm, then replace them. Generation is a full replacement of the files (and file parts) the definition owns, not a merge:
   * A single-target definition owns its location except the files and parts listed by cross-target definitions; leave those untouched
   * A cross-target definition replaces only the files and parts it lists; edit shared files (e.g. a router or an index that collects exports) only in the parts it owns
   * When a whole folder is selected, every file owned by the selected definitions is replaced
4. **Prompt for environment-specific inputs**: collect any values the STC cannot predefine (e.g., organisation ID, domain name, project ID). Present these as a clear list before generating
5. **Populate config**: write the collected values to the config file format defined by the applicable GLOBAL rules (e.g. `<env>.tfvars`)
   * If GLOBAL does not define a config format and the stack is a Pulumi stack, generate `Pulumi.<env>.yaml` files:
     * Where the STC defines config keys, populate them with the real values collected in step 4 in `Pulumi.<env>.yaml`. Where existing `Pulumi.<env>.yaml` files have real key/values, preserve them
     * Also generate a `Pulumi.<env>.sample.yaml` with the same keys as `Pulumi.<env>.yaml` but all values as placeholders
   * Where existing config files have real values, preserve them
6. **Generate code**: create the directory structure and files, including dependency manifests and any config files as specified. Follow conventions from existing sibling definitions in the repo
7. **Makefile**: where the definitions or applicable GLOBAL rules define Makefile targets, add or update them in the root `Makefile`, preserving targets owned by other definitions
8. **Validate**: run the lint, type-check, build and test commands the targets define (preferring any faster working-directory variants the GLOBAL rules provide), and report results

#### If action is align

Review all selected definitions and identify inconsistencies in:

* Input field naming and types (e.g. `pulumi.Input<string>` usage, snake_case vs camelCase keys)
* Validation patterns (e.g. "validation deferred to API" vs explicit checks)
* Return / output structure conventions
* Common field handling (e.g. `bindings`, `labels`/`tags`, target parent fields)
* Section structure of cross-target definitions (same headings and order)

Only compare definitions that share the same `Type` (or are all untyped).

**Output:** A comparison table showing the discrepancy and a suggested standardisation. After presenting findings, offer the user to apply the suggested changes to the definitions.

**Example:**

| Field | Module `folder` | Module `project` | Suggestion |
|-------|----------------|------------------|------------|
| Input Types | `organisation`, `folder` as `Input<string>` | `organisation`, `folder`, `billing` as `Input<string>` | Consistent, no change needed |
| Validation caveat | Present | Present | Aligned |
| `name` validation | 3–30 chars | 1–25 chars (reserving postfix) | Both valid; domain-specific rules, no change needed |

#### If action is retro

Update the selected definitions to reflect the current state of the codebase. This is a one-way operation: the codebase is the source of truth.

1. **Determine source paths**: see Naming Conventions; for cross-target definitions, the files and parts they list in each target
2. **Locate existing code**: if a source path does not exist, warn the user and exit. Advise they need to generate first
3. **Read codebase**: read the source files, dependency manifests and config files from the source paths (e.g. `index.ts`, `package.json`, `Pulumi.<env>.yaml`, `*.tf`, `<env>.tfvars`)
4. **Diff against STC**: compare the codebase against the current definition. Present a summary of differences:
   * Added fields/features in code not in the STC
   * Changed behaviour (e.g., different defaults, validation, merge logic)
   * STC fields not implemented in code (flag as "specified but unimplemented")
5. **Confirm and update**: after user confirms, update the definition to match the codebase:
   * Input definition (fields, types, optionality)
   * Dependencies
   * Validation rules
   * Requirements (logic, resource usage, module calls)
   * Return / output section
   * Fields specified in STC but not implemented in code are **removed** (codebase wins)

## Naming Conventions

* Target code location for a single-target definition, in priority order:
  1. An explicit location in the definition (e.g. `* Location` → `All code is located in app/client`)
  2. Folder structure: `<folder>/<file name>/` at the repo root (e.g. `stc/stacks/service-app-static.md` → `stacks/service-app-static/`, `stc/modules/iam.md` → `modules/iam/`)
  3. Monolithic structure: `stacks/<name>/` or `modules/<name>/`, where `<name>` is the `### <Name>` header lowercased with spaces replaced by `-` (e.g. `### Identity` → `stacks/identity/`)
* Cross-target definitions have no location of their own; each part goes to its target's location, at the paths listed in the definition
