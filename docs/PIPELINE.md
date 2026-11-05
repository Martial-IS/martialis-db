# Martialis Pipeline

The pipeline has changed a lot. The first versions were mostly about syncing YAML to RDF. I adopted
LinkML halfway through the project, when the number of things that had to be kept in sync had grown,
and the work moved to covering the things LinkML's default tools do not do for Martialis.

Every step is a standard tool driven by a declarative file in this repository: one LinkML model,
JSON Schemas, SPARQL rules, SPARQL queries, SHACL shapes. The Makefile orchestrates them.
`make tools` fetches the six binaries into `tools/`; the gate assumes only a Java runtime. The one
program is the Martialis Index (`pipeline/scripts/index.py`), which needs `python3` and no packages.

`make validate` is the blocking gate: a version check, then `schema rdf shacl reasoner`. Everything
else is a report or a maintainer step.

## Pipeline

```
model/martialis.yaml              LinkML, single source of truth (maintainer step)
      |  make model               linkml + pipeline/model/ (jq, SPARQL Update, ROBOT)
      v
local-docs/gen/                   context, ontology, structural SHACL, 7 schemas
      |  make model-install       reviewed copy into schemas/, ontology/,
      v                           database/schemas/ (committed artifacts)

database/**/*.yaml                YAML entities, ULID ids
      |  jv                       1. schema: JSON Schema + duplicate ids (blocking)
      v
  yq + jq (pipeline/scripts/prepare.jq)   2. rdf: shape, convert, rules (blocking)
      |  riot                     JSON-LD 1.1 -> RDF
      |  jena update + pipeline/rules/*.ru   EDTF bounds, derived edges
      v
export/data.ttl                   committed RDF artifact (atomic move)
      |  pipeline/checks/*.rq      ontology coverage, SKOS and reference integrity (blocking)
      |  jena shacl               3. shacl: structural SHACL + shape aliveness (blocking)
      |  jena shacl               quality SHACL (report)
      |  robot                    4. reasoner: OWL 2 DL profile + HermiT (blocking)
      |  jena sparql + pipeline/reports/  provenance, dashboard, styles (report)
      |  lychee                   link health (network, weekly) (report)

database/{persons,styles}/*.yaml
      |  yq + python3             pipeline/scripts/index.py, then its own checks
      v
export/martialis-index.json       committed Martialis Index (atomic move)
```

The gate runs them in this order and stops at the first failure.

## The gate

Each step takes its exit status from the tool that does the work and fails closed: an empty or
contradictory result is a failure, not a pass. That is deliberate. A check that finds nothing to
check proves nothing, and a validator that accepts everything proves nothing either.

**Step 1, `make schema`.** `jv` validates every entity file against its generated, closed JSON
Schema. The same step rejects duplicate ids (records and claims), a schema with no entity directory,
and a YAML file that no entity directory owns.

**Step 2, `make rdf`.** `yq` and `jq` shape the documents (`pipeline/scripts/prepare.jq`), `riot`
converts them to RDF, and `jena update` applies every rule in `pipeline/rules/`. The export is built
in a temp file and moved into place only after a non-empty entity-triple check. The same recipe then
runs three invariants over the result:

- `ontology-coverage.rq`: every `martialis:` term in the export is declared in the ontology.
- `skos-integrity.rq`: SKOS integrity (S13/S14, `skos:notation` and `skos:inScheme`, `inScheme`
  resolving to a declared scheme) plus the house no-lowercase-initial-`prefLabel` rule, over the
  hand-authored vocabulary.
- `reference-integrity.rq`: every entity IRI used as an object resolves to a described record.

**Step 3, `make shacl`.** Two shapes graphs are loaded together: `ontology/martialis.shacl.ttl`,
generated from the model, enforces referential integrity and semantic correctness over the export
(assertions typed, references pointing at entities of the right class, time intervals well-formed,
language maps well-formed); and `ontology/martialis-constraints.shacl.ttl`, hand-authored, adds the
data-level constraints LinkML cannot generate because they compare values across nodes or against a
controlled vocabulary: birth after death, a grade against the scheme its system declares, a part-of
chain against itself.

The same step checks that the hand-authored constraints still match the export
(`pipeline/checks/shape-alive.rq`), and validates `pipeline/fixtures/reject-shapes.ttl`, a known-bad
graph, which must be rejected.

Still not caught: a constraint whose logic is wrong while it still matches data (a wrong
`sh:minCount`), and a path mentioned only inside an `sh:sparql` query or a complex `sh:path`. The
aliveness query cannot derive either.

**Step 4, `make reasoner`.** The ontology targets OWL 2 DL (`dcterms:conformsTo
<http://www.w3.org/ns/owl-profile/DL>`). `make reasoner` merges `ontology/martialis.ttl` and
`export/data.ttl` into ONE document, checks it with `robot validate-profile --profile DL`, then runs
HermiT on it and fails on an unsatisfiable class or an inconsistent model. It also checks the
negative-control fixtures, so a reasoner that accepts everything fails.

## Reports

`make quality` writes `export/quality-report.ttl` and never fails. It reports incomplete data:
persons without teachers, assertions without sources or confidence, missing periods, missing
rationales. The other reports (`provenance`, `dashboard`, `styles`, `sources`, `links`, `worklist`,
`reports-json`) are for finding work, not for gating. `make links` needs the network and runs in the
weekly CI job.
