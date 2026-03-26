# Architecture Decision Record: Go Migration Strategy for Tools

## Context
As we evaluate migrating repository tools like `tfdoc` from Python to Go, the primary objectives are removing external dependencies (like local Python environment setup and `pip` package management) and improving execution speed. As our repository tooling expands, we need a formalized strategy to determine which existing Python utility scripts (`tools/*.py`) should be migrated to Go, how they should be structured within a single Go module, and how both environments interact long-term.

## Containerization and Contributor Onboarding
A benefit of migrating to natively compiled Go binaries is the ability to easily containerize the toolkit. Because Go generates standalone executables with no runtime dependencies, the resulting tools can be packaged into lightweight, secure container images. This simplifies contributor onboarding by eliminating the need to configure local Python virtual environments or install third-party dependencies.

## Decision
We will selectively migrate tooling to Go, prioritizing scripts that are executed frequently within our CI/CD pipelines, require accurate HCL parsing, or perform heavy file-system traversals where execution speed is beneficial. We will retain Python for tasks that require loose typing, dynamic scraping, or simple string-based manipulations. 

Go tools will be unified under a single Go module located in a dedicated source folder (`tools/src/`), generating individual binaries directly into the top-level `tools/` directory via a `Makefile`.

---

## Tool Migration Strategy

A review of the current `tools/*.py` codebase identifies three clear partitions:

### Low Complexity / Medium Benefit
These scripts provide performance improvements or safety enhancements when written in statically-typed Go.

1. **`check_documentation.py`**: Already fused with the migrated `tfdoc` as the `--check` flag.
2. **`check_boilerplate.py` & `check_names.py`**: These enforce basic naming conventions and monitor file headers (licenses) via directory traversal. Implementing these in native Go provides faster execution times and allows them to share core linter logic.
3. **`check_links.py`**: Validates markdown link anchors across the repository. Go's robust `goldmark` library and parallelization capabilities make this an excellent candidate.

### High Complexity / High Benefit
- **Migrate tests to Go**: Our current framework basically parses Markdown files and runs terraform against the parsed snippets. The resulting plan is compared against a YAML manifest. Very few tests actually rely on Python code. This could potentially be converted to a highly parallel Go implementation removing the complicated python/pytest/tftest layers. Requires careful evaluation (e.g. e2e tests, etc.)
- **`plan_summary.py` / `tftest_plan_summary.py`**: These ingest structured `terraform plan` JSON outputs. Using `encoding/json` inside Go provides type-safety, ensuring changes in Terraform's internal JSON structure are caught at compile-time when mapped against Go structs. If we migrate the testing framework to Go, the implementation of these tool will be trivial.

### Low ROI (Leave in Python)
1. **`versions.py`**: only one external dependency (`click`) and not used frequently or in CI/CD. It's mostly an standarization tool.
- **`check_yaml_schema.py` & `schema_docs.py`**: Standardizing dynamic/untyped schema validation in Go involves heavy boilerplate. Python's native `jsonschema` library excels at loosely-typed structure checks.
- **`changelog.py` & `build_service_agents.py`**: Scripts making REST requests to GitHub APIs or scraping web resources should remain in Python. Dynamic scripting languages are purpose-built for data munging.

---

## Proposed Folder Structure

Rather than spawning `.mod` files per script, all Go tooling operates securely within a monolith module utilizing standard `cmd/` entrypoints:

```text
tools/
├── Makefile                     <-- (Builds all binaries into tools/)
├── tfdoc                        <-- (Compiled Go binary)
├── check_boilerplate            <-- (Future compiled Go binary)
├── check_yaml_schema.py         <-- (Retained Python script)
└── src/                         <-- (Single Go module)
    ├── go.mod
    ├── go.sum
    ├── cmd/
    │   ├── tfdoc/
    │   │   └── main.go          <-- (Entrypoint)
    │   └── check_boilerplate/
    │       └── main.go          <-- (Entrypoint)
    └── internal/
        ├── parser/              <-- (Shared HCL parsing)
        ├── linter/              <-- (Shared linting rules)
        └── render/              <-- (Shared Markdown generation)
```


## Risks
- **More difficult maintenance of Go code**: Go can present a slightly higher maintenance burden for teams primarily accustomed to Python scripting. This risk is partly mitigated by the increasing availability of LLMs.
- **Local usage requires a Go compiler**: Contributors running or developing the automated tools directly on their host machines will need to have Go installed, although containerized environments can alleviate this operational setup.
