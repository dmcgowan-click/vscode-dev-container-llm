---
name: stc
description: Workflow for reading a standard template construct (STC) based on user inputs, and based on these inputs, either; A) review the stc, report back on potential ambiguity or design issues, and suggest improvements, B) generate new code bases based on the stc. Triggers include "stc", "standard construct template", "review stc", "trigger stc"
author: Douglas McGowan
---

# STC Workflow

Locate a STC based on inputs and either; A) review the stc, report back on potential ambiguity or design issues, and suggest improvements, B) generate new code bases based on the stc

## Requirements

Read / Write permissions to the `stc` folder. Typically located within the root of your repo, but locations can vary

## Helper Scripts

None yet defined

## Core Workflow

### 1. Locate STC folder and read definitions

Search for an `stc` folder within the repo. If a folder is not found, prompt the user to provide a path to the `stc` folder.

Once located, search for `DRAFT.md` or `DETAIL.md` within the `stc` folder. These are the STC definition files.

> **NOTE:** The file structure is evolving — currently there may be one or both of these files. Read all that exist and combine their content to form the full STC catalogue.

### 2. Confirm STC type, name and action

If not decipherable from the user input, prompt the user for the following inputs:

* STC type
  * Module
  * Stack
* STC Action
  * Ensure when reviewing, aligning and generating, all parent headers in the STC are read for global instructions that apply to all child definitions. For example, `## Modules` applies to all module definitions beneath it, `# Standard Template Constructs` applies to every definition in the file.
  * For reviewing and generating
    * The name of the STC definition to read. This corresponds to a `### <Name>` header within the STC files (e.g., `### IAM`, `### Identity`).
      * All STCs must fall under a parent header of `## Stacks` or `## Modules`. Report back to the user if this is not the case, and halt workflow until the STC is corrected.
    * Review
      * Review the STC, report back on potential ambiguity or design issues, and suggest improvements
    * Generate
      * Generate (or replace) code based on the STC
  * For aligning
    * Alignment
      * Review all STC definitions under `## Modules` or `## Stacks` (based on type) and identify inconsistencies

### 3. Action STC

#### If action is review

Review the STC, report back on potential ambiguity or design issues, and suggest improvements. Offer to edit the STC definition to make these updates.

The ideal state is where AI can create the codebase from the STC with minimal user inputs and will consistently create the codebase the same way based on the STC definition.

The STC definition should be self-sufficient to determine:
* The programming language to use
* The target code location (derived from naming conventions below)
* Required dependencies / `package.json` contents (if applicable)
* Parent folder structure

If any of these cannot be determined from the STC, flag it as a review finding and suggest how to make the definition explicit.

NOTE: Sensible environment-specific inputs (org ID, domain, project ID, etc.) are fine — these can never be predefined and will be unique to each environment.

#### If action is generate

Review the STC, if potential ambiguity or design issues, report back and offer to perform a `review` action first.

Once STC is acceptably reviewed, generate code based on the STC:

1. **Determine output path** — Derive from the STC type and name using the naming conventions below:
   * Stack → `stacks/<name>/` (e.g., `### Identity` → `stacks/identity/`)
   * Module → `modules/<name>/` (e.g., `### IAM` → `modules/iam/`)
2. **Replace existing code** — If the target path already exists, warn the user and confirm, then **replace** the code entirely. Generation is a full replacement, not a merge.
3. **Prompt for environment-specific inputs** — Collect any values the STC cannot predefine (e.g., organisation ID, domain name, project ID). Present these as a clear list before generating.
4. **Populate config YAML** — Generate `Pulumi.<env>.yaml` files for the stack:
   * Where the STC defines config keys, populate them with the real values collected in step 3 in `Pulumi.<env>.yaml`. Where existing `Pulumi.<env>.yaml` files have real key/values, preserve them.
   * Also generate a `Pulumi.<env>.sample.yaml` with the same keys as `Pulumi.<env>.yaml` but all values as placeholders.
5. **Generate code** — Create the directory structure and files, including `package.json` and any config files as specified by the STC. Follow conventions from existing sibling stacks/modules in the repo.

#### If action is alignment

Review all STC definitions under `## Modules` or `## Stacks` (based on type) and identify inconsistencies in:

* Input field naming and types (e.g. `pulumi.Input<string>` usage)
* Validation patterns (e.g. "validation deferred to API" vs explicit checks)
* Return structure conventions
* Common field handling (e.g. `bindings`, `labels`/`tags`, target parent fields)

**Output:** A comparison table showing the discrepancy and a suggested standardisation. After presenting findings, offer the user to apply the suggested changes to the STC definitions.

**Example:**

| Field | Module `folder` | Module `project` | Suggestion |
|-------|----------------|------------------|------------|
| Input Types | `organisation`, `folder` as `Input<string>` | `organisation`, `folder`, `billing` as `Input<string>` | Consistent — no change needed |
| Validation caveat | Present | Present | Aligned |
| `name` validation | 3–30 chars | 1–25 chars (reserving postfix) | Both valid — domain-specific rules, no change needed |

## Naming Conventions

* `## Stacks` in the STC refers to the `stacks/` parent directory in the repo root
* `## Modules` in the STC refers to the `modules/` parent directory in the repo root
* `### <Name>` headers (e.g., `### Identity`, `### IAM`) map to a subfolder within the parent directory. Folder names are always **lowercase** (e.g., `### Identity` → `stacks/identity/`, `### Project` → `modules/project/`)