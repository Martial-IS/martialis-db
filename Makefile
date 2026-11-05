### Martialis database Makefile
###
### This IS the toolchain. Every step is a standard tool driven by a
### declarative file in this repository. The one program is the Martialis
### Index (pipeline/scripts/index.py), which needs only python3.
###
###   database/**/*.yaml
###     |  jv                    JSON Schema validation + duplicate ids (blocking)
###     |  yq + jq + riot        YAML -> JSON-LD -> RDF
###     |  jena update + pipeline/rules/  EDTF bounds, materialised
###     |                        edges, dataset front matter
###     v
###   export/data.ttl
###     |  jena sparql           ontology coverage, SKOS and reference integrity (blocking)
###     |  jena shacl            structural shapes (blocking), quality shapes (report)
###     |  robot reason          OWL 2 DL (HermiT)
###     |  jena sparql + pipeline/reports/  reports
###     |  lychee                link health
###
###   database/{persons,styles}
###     |  yq + python3          pipeline/scripts/index.py (stdlib only)
###     v
###   export/martialis-index.json
###
### Run 'make tools' once (downloads six binaries into tools/), then
### 'make validate'. Only java is expected to be already installed.
###
### Frederico Muñoz <fsm@martial.is>, Martialis Project
###

SHELL   := /bin/bash
# Every recipe runs with `pipefail`, so `a | b` fails if EITHER side fails.
# Without it a recipe reports only its last command's status, and since the
# whole pipeline is filters - yq | jq, sparql | tail | tr - sed - the failure
# of the tool that actually does the work is exactly the one that gets
# discarded: a broken query or a crashed parser looks like an empty result,
# the recipe succeeds, and an empty artifact is written and announced as
# success.
.SHELLFLAGS := -o pipefail -c
# A bare `make` prints the target list instead of running the first target.
.DEFAULT_GOAL := help
TOOLS   := tools
JENA    := $(TOOLS)/jena/bin
YQ      ?= $(TOOLS)/yq
JQ      ?= $(TOOLS)/jq
JV      ?= $(TOOLS)/jv
ROBOT   ?= $(TOOLS)/robot
LYCHEE  ?= $(TOOLS)/lychee
RIOT    ?= $(JENA)/riot
UPDATE  ?= $(JENA)/update
SPARQL  ?= $(JENA)/sparql
SHACL   ?= $(JENA)/shacl
export JENA_HOME = $(CURDIR)/$(TOOLS)/jena

ONTOLOGY := ontology/martialis.ttl
VOCAB    := ontology/vocabularies.ttl
DATASET  := ontology/dataset.ttl
CATALOG  := ontology/catalog-v001.xml
DATA     := export/data.ttl
SCHEMAS  := database/schemas
# Every schema with a matching database/<name>s/ directory is an entity type.
# The seven basenames (event, org, person, place, ranking-system, source,
# style) are chosen so the owning directory really is exactly `$(name)s`.
# A schema with no directory would be validated by nothing; UNOWNED_SCHEMAS
# below turns that into a failure.
SCHEMA_NAMES := $(basename $(basename $(notdir $(wildcard $(SCHEMAS)/*.schema.json))))
ENTITY_TYPES := $(foreach n,$(SCHEMA_NAMES),$(if $(wildcard database/$(n)s),$(n)))
UNOWNED_SCHEMAS := $(filter-out $(ENTITY_TYPES),$(SCHEMA_NAMES))
SCHEMA_MAP := https://martial.is/schemas/=$(CURDIR)/$(SCHEMAS)/
ENTITY_YAML := $(shell find database -name '*.yaml' -not -path 'database/templates/*')

# The hand-authored shapes graphs declare owl:imports <https://w3id.org/martialis/ontology>.
# That is correct metadata for a published shapes graph and stays in the
# files; it is stripped only for local validation, because Jena's SHACL
# dereferences owl:imports over HTTP and the shapes target concrete classes
# and need no ontology axioms to run.
#
# This is NOT a temporary 404 workaround - keep it even after the w3id
# redirect resolves. Letting validation fetch over the network would make
# every `make shacl` and every CI run depend on w3id being up, which is the
# thing worth avoiding. (Jena's shacl CLI has no flag to skip imports; a
# local location-mapping would be the only alternative.)
NOIMPORT = sed '/owl:imports/d'

.PHONY: help tools model model-install imports validate version-check schema changed check review \
        rdf shacl quality reasoner sources provenance \
        dashboard styles links worklist reports-json clean-reports \
        index index-report index-sensitivity

## ---------------------------------------------------------------- agents

## List every documented target (the default goal).
## A bare `make` prints this instead of running `tools`.
help:
	@echo "Martialis database - make targets"; echo
	@awk '/^## -/ { next } \
	     /^## / { if (d == "") d = substr($$0, 4); next } \
	     /^[a-zA-Z0-9_.][a-zA-Z0-9_. -]*:([^=]|$$)/ { if ($$1 ~ /^\./) { d=""; next } \
	       t = $$0; sub(/:.*/, "", t); n = split(t, ts, " "); \
	       if (d != "") for (i = 1; i <= n; i++) printf "  %-18s %s\n", ts[i], d; d = "" }' $(MAKEFILE_LIST)
	@echo; echo "  check / review default to the working-tree changes; override with FILES=\"path ...\"."

## List the changed/new database YAML files (templates excluded).
## Deleted files are excluded: there is nothing left to validate, and `check`
## would fail trying to open them. `check` and `review` use this when FILES is empty.
## core.quotePath=false keeps non-ASCII paths raw: git otherwise emits them as an
## escaped, quoted string (".../\\346\\227\\245...") that `test -f` cannot open, so
## every CJK-named Source (wikipedia-ja/内藤高治.yaml, ...) was silently skipped.
changed:
	@{ git -c core.quotePath=false diff --name-only; \
	   git -c core.quotePath=false diff --name-only --cached; \
	   git -c core.quotePath=false ls-files --others --exclude-standard; } \
	  | sort -u | grep -E '^database/.*\.yaml$$' | grep -v '^database/templates/' \
	  | while read -r f; do test -f "$$f" && printf '%s\n' "$$f"; done || true

## ---------------------------------------------------------------- tools

## Fetch every external tool into tools/ (gitignored). Needs only java.
## Versions are pinned so the gate is reproducible; CI keys its tool cache on
## this Makefile's hash, so bumping a version here refreshes the cache.
## Jena comes from Maven Central: dlcdn only carries current releases, and
## archive.apache.org is sometimes unreachable.
YQ_VERSION     := v4.53.6
JQ_VERSION     := jq-1.8.1
JV_VERSION     := v6.0.3
JENA_VERSION   := 6.2.0
ROBOT_VERSION  := v1.9.10
LYCHEE_VERSION := lychee-v0.24.2
tools:
	@mkdir -p $(TOOLS)
	@echo "==> yq";     curl -fsSL -o $(TOOLS)/yq https://github.com/mikefarah/yq/releases/download/$(YQ_VERSION)/yq_linux_amd64 && chmod +x $(TOOLS)/yq
	@echo "==> jq";     curl -fsSL -o $(TOOLS)/jq https://github.com/jqlang/jq/releases/download/$(JQ_VERSION)/jq-linux-amd64 && chmod +x $(TOOLS)/jq
	@echo "==> jv";     curl -fsSL https://github.com/santhosh-tekuri/jsonschema/releases/download/$(JV_VERSION)/jv-$(JV_VERSION)-linux-amd64.tar.gz | tar xz -C $(TOOLS) jv && chmod +x $(TOOLS)/jv
	@echo "==> jena";   curl -fsSL https://repo1.maven.org/maven2/org/apache/jena/apache-jena/$(JENA_VERSION)/apache-jena-$(JENA_VERSION).tar.gz | tar xz -C $(TOOLS) && rm -rf $(TOOLS)/jena && mv $(TOOLS)/apache-jena-$(JENA_VERSION) $(TOOLS)/jena
	@echo "==> robot";  curl -fsSL -o $(TOOLS)/robot.jar https://github.com/ontodev/robot/releases/download/$(ROBOT_VERSION)/robot.jar && printf '#!/usr/bin/env bash\nexec java -jar "$$(dirname "$$0")/robot.jar" "$$@"\n' > $(TOOLS)/robot && chmod +x $(TOOLS)/robot
	@# --wildcards: GNU tar otherwise treats `*/lychee` as a literal path.
	@echo "==> lychee"; curl -fsSL https://github.com/lycheeverse/lychee/releases/download/$(LYCHEE_VERSION)/lychee-x86_64-unknown-linux-gnu.tar.gz | tar xz --wildcards -C $(TOOLS) --strip-components=1 '*/lychee' && chmod +x $(TOOLS)/lychee
	@# `curl -f` checks the HTTP status, not that the whole body arrived: a
	@# truncated binary execs but crashes, and surfaces much later as a
	@# confusing schema failure. Every tool must answer a probe.
	@for probe in "$(YQ) --version" "$(JQ) --version" "$(JV) --help" "$(RIOT) --version" "$(ROBOT) --version" "$(LYCHEE) --version"; do \
	  out=$$($$probe 2>&1); \
	  test -n "$$out" || { echo "tools: '$$probe' produced no output - it is broken, re-run 'make tools'"; exit 1; }; \
	done
	@echo "tools ready."

## ------------------------------------------------------------------ model

## Regenerate the artifacts derived from model/martialis.yaml (maintainer).
## Refreshes model/martialis-enums.yaml in place (the model imports it), then
## writes the rest into local-docs/gen/: context.jsonld, martialis.ttl,
## martialis.shacl.ttl and the seven per-type JSON Schemas. Maintainer tool
## only - unlike every other target this one needs the Python venv under
## tools/linkml-venv, pinned by pipeline/requirements-model.txt (the
## file has the venv command).
## OUT overrides the output directory: make model OUT=/tmp/gen.
## Installing the result into schemas/, ontology/ and database/schemas/ under
## the committed filenames is a reviewed copy, not part of this target: the
## committed artifacts are what `schema`/`rdf`/`shacl` consume, and they must
## never require the venv.
##
## Each LinkML generator writes a raw artifact under $(GEN)/raw; a jq filter or
## a SPARQL Update in pipeline/model/ turns it into the committed form. ROBOT
## writes the OWL file and a sorted riot pass the SHACL file, so both are
## byte-stable across runs.
LINKML ?= $(TOOLS)/linkml-venv/bin/linkml
GEN     = $(or $(OUT),local-docs/gen)
MODEL  := model/martialis.yaml
BANNER  = GENERATED FILE - DO NOT EDIT. Built by make model from $(1); regenerate with `make model && make model-install`.
model: export PYSTOW_HOME = $(CURDIR)/tools/pystow
model: export XDG_DATA_HOME = $(CURDIR)/tools/xdg
model:
	@mkdir -p $(GEN)/raw
	@# The concept enums first: the model imports them. enums.jq fails on no
	@# scheme or a scheme with no concepts.
	@$(SPARQL) --data=$(VOCAB) --query=pipeline/model/enums.rq --results=json | $(JQ) -f pipeline/model/enums.jq \
	  | $(YQ) -P | { echo '# $(call BANNER,$(VOCAB))'; cat; } > $(GEN)/raw/enums.yaml
	@mv $(GEN)/raw/enums.yaml model/martialis-enums.yaml
	@$(LINKML) validate $(MODEL)
	@$(YQ) -o json $(MODEL) > $(GEN)/raw/model.json
	@# --base: without it a bare ULID reference resolves against the file path.
	@$(LINKML) generate jsonld-context --xsd-anyuri-as-iri --base https://martial.is/entity/ $(MODEL) \
	  | $(JQ) -S --slurpfile m $(GEN)/raw/model.json --arg note '$(call BANNER,$(MODEL))' -f pipeline/model/context.jq \
	  > $(GEN)/context.jsonld
	@# The ontology targets OWL 2 DL. --xsd-anyuri-as-iri makes uri slots object
	@# properties; --no-skip-vacuous-local-range-axioms keeps every value type
	@# as a class-local restriction, because no global range is asserted on a
	@# term the ontology does not own; --metadata-profile rdfs makes each
	@# description the term's rdfs:comment.
	@$(LINKML) generate owl --no-metaclasses --no-type-objects --no-add-ols-annotations \
	  --no-skip-vacuous-local-range-axioms --skip-vacuous-min-zero-cardinality-axioms \
	  --consolidate-cardinality-axioms --no-use-native-uris --xsd-anyuri-as-iri --metadata-profile rdfs \
	  $(MODEL) > $(GEN)/raw/owl.raw.ttl
	@$(UPDATE) --data=$(GEN)/raw/owl.raw.ttl --namedGraph=$(VOCAB) --namedGraph=model/ontology-overlay.ttl \
	  $(addprefix --namedGraph=,$(wildcard ontology/imports/*-module.ttl)) \
	  --update=pipeline/model/owl.ru --dump 2> $(GEN)/raw/owl.log | $(RIOT) --syntax=trig --output=ttl > $(GEN)/raw/owl.ttl
	@rows=$$($(SPARQL) --data=$(GEN)/raw/owl.ttl --query=pipeline/model/owl-check.rq --results=tsv | tail -n +2) \
	  || { echo "model: owl-check.rq failed - the ontology is unverified"; exit 1; }; \
	test -z "$$rows" || { echo "model: fix model/martialis.yaml or the overlay:"; printf '%s\n' "$$rows" | sed 's/^/  /'; exit 1; }
	@$(ROBOT) convert --catalog $(CATALOG) --input $(GEN)/raw/owl.ttl --output $(GEN)/raw/owl.robot.ttl
	@grep -q 'owl:Class' $(GEN)/raw/owl.robot.ttl || { echo "model: the ontology declares no class"; exit 1; }
	@{ echo '# $(call BANNER,$(MODEL))'; cat model/ontology-comment.txt $(GEN)/raw/owl.robot.ttl; } > $(GEN)/martialis.ttl
	@$(JQ) -r -f pipeline/model/patterns.jq $(GEN)/raw/model.json > $(GEN)/raw/patterns.ttl
	@$(LINKML) generate shacl --non-closed --suffix Shape $(MODEL) > $(GEN)/raw/shacl.raw.ttl
	@$(UPDATE) --data=$(GEN)/raw/shacl.raw.ttl --namedGraph=$(GEN)/raw/patterns.ttl --update=pipeline/model/shacl.ru --dump \
	  2> $(GEN)/raw/shacl.log | $(RIOT) --syntax=trig --output=nq | LC_ALL=C sort > $(GEN)/raw/shacl.nt
	@grep -q 'NodeShape' $(GEN)/raw/shacl.nt || { echo "model: the shapes graph has no node shape"; exit 1; }
	@{ grep '^@prefix' $(GEN)/raw/shacl.raw.ttl; echo '@prefix owl: <http://www.w3.org/2002/07/owl#> .'; \
	  echo '@prefix dcterms: <http://purl.org/dc/terms/> .'; cat $(GEN)/raw/shacl.nt; } \
	  | $(RIOT) --syntax=ttl --formatted=ttl | { echo '# $(call BANNER,$(MODEL))'; cat; } > $(GEN)/martialis.shacl.ttl
	@for pair in $(MODEL_INSTALL); do \
	  $(LINKML) generate json-schema --top-class $${pair%%:*} --closed --no-metadata $(MODEL) \
	  | $(JQ) -S --slurpfile m $(GEN)/raw/model.json --arg slug $${pair##*:} --arg note '$(call BANNER,$(MODEL))' \
	      -f pipeline/model/schema.jq > $(GEN)/$${pair%%:*}.schema.json || exit 1; \
	done
	@echo "model: enums installed; context, ontology, shapes and $(words $(MODEL_INSTALL)) schemas -> $(GEN)"

## Copy a generated tree into the committed locations.
## Separate from `model` so regenerating and republishing stay two deliberate steps, but one command:
##   make model && make model-install && make validate
## The mapping is explicit because the generator names schemas after the class
## (Person.schema.json) and the corpus names its directories after the plural
## (database/persons/). Any missing generated file is a hard error, so a
## half-empty install cannot masquerade as a successful one.
MODEL_INSTALL := Person:person Place:place Organization:org Style:style Source:source Event:event RankingSystem:ranking-system
model-install:
	@set -e; OUT=$(or $(OUT),local-docs/gen); \
	for pair in $(MODEL_INSTALL); do \
	  t=$${pair%%:*}; n=$${pair##*:}; \
	  cp $$OUT/$$t.schema.json database/schemas/$$n.schema.json; \
	done; \
	cp $$OUT/context.jsonld schemas/context.jsonld; \
	cp $$OUT/martialis.ttl ontology/martialis.ttl; \
	cp $$OUT/martialis.shacl.ttl ontology/martialis.shacl.ttl; \
	echo "model-install: context, ontology, shacl and $(words $(MODEL_INSTALL)) schemas installed"

## Rebuild the PROV-O, ORG and BIBO import modules from the vendored upstream files.
## Maintainer-only, like `model`: the committed modules are what the reasoner
## loads. The ontology imports a ROBOT STAR module of each upstream ontology,
## extracted for the terms listed in ontology/imports/<name>.terms, instead of
## the whole file: no upstream file is OWL 2 DL (PROV-O puns two properties, ORG
## uses FOAF and DCTERMS terms it never declares, BIBO puns DCTERMS terms), and a
## locality-based module keeps every axiom that bears on the listed terms and
## nothing else. Each module is built in a temp file and installed only if it
## is itself OWL 2 DL.
IMPORT_MODULES := prov=prov-o.ttl org=org.ttl bibo=bibo.rdf
imports:
	@set -e; for pair in $(IMPORT_MODULES); do \
	  n=$${pair%%=*}; src=ontology/imports/$${pair##*=}; tmp=$$(mktemp --suffix=.ttl); \
	  $(ROBOT) extract --method STAR --input $$src --term-file ontology/imports/$$n.terms \
	    annotate --ontology-iri https://w3id.org/martialis/ontology/imports/$$n \
	             --annotation rdfs:comment "ROBOT STAR module of $$src for the terms in ontology/imports/$$n.terms. Generated by make imports; do not edit." \
	    --output $$tmp; \
	  $(ROBOT) validate-profile --input $$tmp --profile DL --output /dev/null \
	    || { rm -f $$tmp; echo "imports: the $$n module is not OWL 2 DL - ontology/imports/$$n-module.ttl left as it was"; exit 1; }; \
	  mv $$tmp ontology/imports/$$n-module.ttl; \
	  echo "imports: ontology/imports/$$n-module.ttl"; \
	done

## ------------------------------------------------------------- pipeline

## Check that the data and ontology version numbers agree across files.
## Two version lines, checked separately; each moves only when its own content
## changes. The data version (CITATION.cff, dcat:version in ontology/dataset.ttl)
## is the data-vX.Y.Z release tag. The ontology version (the model's version:,
## owl:versionInfo and owl:versionIRI in the overlay, both hand-authored shapes
## graphs, every vocabulary scheme, and the ontology version the dataset conforms
## to) is the ontology-vX.Y.Z tag. A file with no version at all is a failure too.
DATA_VERSIONED := ontology/dataset.ttl
ONTO_VERSIONED := ontology/dataset.ttl model/ontology-overlay.ttl \
                  ontology/martialis-constraints.shacl.ttl ontology/martialis-quality.shacl.ttl \
                  ontology/vocabularies.ttl
version-check:
	@bad=""; \
	same() { ref=$$1; src=$$2; re=$$3; shift 3; for f in "$$@"; do \
	  vs=$$(grep -o -E "$$re" $$f | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+' | sort -u); \
	  test -n "$$vs" || { bad="$$bad $$f(none)"; continue; }; \
	  for v in $$vs; do test "$$v" = "$$ref" || bad="$$bad $$f($$v, $$src has $$ref)"; done; \
	done; }; \
	d=$$(sed -n 's/^version: *//p' CITATION.cff); o=$$(sed -n 's/^version: *//p' model/martialis.yaml); \
	test -n "$$d" -a -n "$$o" || { echo "version-check: CITATION.cff or model/martialis.yaml states no version"; exit 1; }; \
	same "$$d" CITATION.cff 'dcat:version "[^"]*"' $(DATA_VERSIONED); \
	same "$$o" model/martialis.yaml '(owl:versionInfo "[^"]*"|ontology/[0-9]+\.[0-9]+\.[0-9]+>)' $(ONTO_VERSIONED); \
	test -z "$$bad" || { echo "version-check:$$bad"; exit 1; }; \
	echo "version-check: data $$d, ontology $$o"

## Full blocking pipeline (CI gate), in order, stopping on first failure.
## The version check, then four steps. The corpus-wide duplicate-id check
## lives in `schema` (which already opens every record) and the three graph
## invariants - ontology coverage, SKOS integrity and reference integrity - live
## in `rdf`, so none costs a step of its own.
## `quality` is deliberately NOT a prerequisite: it reports data-completeness
## findings (no birth date, no teacher, ...) and can never fail, so gating on it
## made the slowest non-blocking step part of the blocking one. It is a report
## (`make quality`, run by CI).
validate: version-check schema rdf shacl reasoner
	@echo "All steps passed."

## Definition of done: full gate + quality findings on the changed records.
## Runs the blocking gate, then prints the worklist rows (see `worklist`) for the
## records just changed (or FILES="a b"), including findings on their nested
## claims (missing quotation, confidence discrepancy). Slower than `check`,
## because quality takes minutes, so run it once, at the end.
review:
	@$(MAKE) --no-print-directory validate
	@$(MAKE) --no-print-directory worklist >/dev/null
	@files="$(FILES)"; \
	if [ -z "$$files" ]; then files=$$($(MAKE) --no-print-directory -s changed); fi; \
	ulids=$$(grep -h '^id:' $$files 2>/dev/null | awk '{print $$2}' | sort -u); \
	if [ -z "$$ulids" ]; then echo "review: no changed records to report on"; exit 0; fi; \
	pat=$$(echo $$ulids | tr ' ' '|'); \
	n=$$(grep -cE "$$pat" export/worklist.csv || true); \
	echo "review: $$n quality finding(s) on the changed record(s)"; \
	grep -E "$$pat" export/worklist.csv | head -40 | sed 's/^/  /' || true

## JSON Schema validation of every entity file and every template.
## jv reads YAML directly and resolves the cross-file $$refs through -m.
schema:
	@# Entity types are derived, not listed: every database/schemas/X.schema.json
	@# with a matching database/Xs/ directory. A schema with no owning directory
	@# would be validated by nothing, so it is a failure rather than a silently
	@# skipped file.
	@test -z "$(UNOWNED_SCHEMAS)" \
	  || { echo "schema: schema file(s) with no entity directory (never validated):"; \
	       printf '%s\n' $(UNOWNED_SCHEMAS) | sed 's/^/  /'; exit 1; }
	@rc=0; for s in $(ENTITY_TYPES); do \
	  g="database/$${s}s"; \
	  files=$$(find $$g -name '*.yaml'); \
	  out=$$($(JV) -d 7 -m "$(SCHEMA_MAP)" $(SCHEMAS)/$$s.schema.json $$files 2>&1) || rc=1; \
	  printf '%s\n' "$$out" | grep -v ': ok$$' || true; \
	done; \
	test $$rc -eq 0 || exit 1
	@# A YAML file under a directory no schema owns (database/misc/, a typo'd
	@# directory name) is silently skipped by the loop above and still ships to
	@# data.ttl through `make rdf`. Named rather than counted, so the message
	@# says which file, derived from what the schema actually saw.
	@all=$$(find database -name '*.yaml' -not -path 'database/templates/*' | sort); \
	covered=$$(for s in $(ENTITY_TYPES); do find database/$${s}s -name '*.yaml'; done | sort); \
	stray=$$(comm -13 <(echo "$$covered") <(echo "$$all") | grep . || true); \
	test -z "$$stray" || { echo "schema: YAML under no entity directory (never validated, still exported):"; \
	                       printf '%s\n' "$$stray" | sed 's/^/  /'; exit 1; }
	@# Duplicate IDs, of records and of the claims inside them (one namespace).
	@# JSON Schema sees one file at a time, so this is the corpus-wide check, and
	@# it belongs to the step that already opens every record. Two entities or
	@# two claims sharing an id would silently shadow each other in the export;
	@# a claim block copied as a template is the usual way in.
	@dupes=$$(find database -name '*.yaml' -not -path 'database/templates/*' -print0 \
	          | xargs -0 $(YQ) -o=json -I0 ea '[.]' \
	          | $(JQ) -r '.[] | .. | objects | select(has("id")) | .id // empty' | sort | uniq -d) \
	  || { echo "schema: duplicate-id check failed to run"; exit 1; }; \
	test -z "$$dupes" \
	  || { echo "schema: duplicate id(s) (record or claim):"; \
	       printf '%s\n' "$$dupes" | sed 's/^/  /'; exit 1; }
	@# Templates are the only files that carry `id: null` on purpose. Every
	@# record under database/ carries a real ULID, and no entity schema accepts
	@# a null. Substitute a throwaway ULID so the rest of the template is still
	@# validated - otherwise the contributor-facing examples drift from the
	@# format with nothing noticing.
	@# jv cannot read YAML from stdin (it takes `-` as a literal string), so
	@# the substituted template goes through a temp file.
	@rc=0; tmp=$$(mktemp --suffix=.yaml); \
	for t in $(ENTITY_TYPES); do \
	  $(YQ) '.id = "01ARZ3NDEKTSV4RRFFQ69G5FAV"' database/templates/$$t.yaml > $$tmp; \
	  $(JV) -q -d 7 -m "$(SCHEMA_MAP)" $(SCHEMAS)/$$t.schema.json $$tmp >/dev/null 2>&1 \
	    || { echo "  template $$t.yaml does not match $$t.schema.json"; rc=1; }; \
	done; rm -f $$tmp; test $$rc -eq 0 || exit 1
	@echo "schema: templates match their schemas"
	@echo "schema: $(words $(ENTITY_YAML)) entity files valid"

## Fast scoped pre-flight: schema + reference check on the changed records.
## Validates each against its entity JSON Schema and checks that every ULID it
## references resolves to a record. Seconds, not the full gate - the point is a
## tight loop while writing. With no FILES it uses `make changed`.
check:
	@files="$(FILES)"; \
	if [ -z "$$files" ]; then files=$$($(MAKE) --no-print-directory -s changed); fi; \
	if [ -z "$$files" ]; then echo "check: no changed database YAML files (pass FILES=...), nothing to do"; exit 0; fi; \
	rc=0; \
	for f in $$files; do \
	  t=$$(echo "$$f" | cut -d/ -f2); t=$${t%s}; \
	  s="$(SCHEMAS)/$$t.schema.json"; \
	  if [ ! -f "$$s" ]; then echo "  $$f: under no entity directory (no $$s)"; rc=1; continue; fi; \
	  out=$$($(JV) -d 7 -m "$(SCHEMA_MAP)" "$$s" "$$f" 2>&1) || rc=1; \
	  printf '%s\n' "$$out" | grep -vE ': ok$$|^$$' || true; \
	done; \
	test $$rc -eq 0 || { echo "check: schema validation FAILED"; exit 1; }; \
	echo "check: schema ok for $$(echo $$files | wc -w) file(s)"
	@# Reference resolution, two passes off one ULID -> file index (paths can
	@# contain a colon, so the id is stripped from the right). First fail on a
	@# referenced ULID with no record - JSON Schema checks only the 26-character
	@# shape, so nothing else sees it (the graph-side version runs in `rdf`).
	@# Then print every reference resolved to the referenced record's NAME: a
	@# ULID that exists but names the wrong entity is the one error no schema,
	@# SHACL or reasoner check can catch, and seeing "teacher -> Nakayama Zendo"
	@# next to a rationale about "Ozawa Torakichi" is what catches it.
	@files="$(FILES)"; \
	if [ -z "$$files" ]; then files=$$($(MAKE) --no-print-directory -s changed); fi; \
	index=$$(mktemp); ids=$$(mktemp); \
	find database -name '*.yaml' -not -path 'database/templates/*' -print0 \
	  | xargs -0 grep -H '^id:' \
	  | awk '{u=$$NF; p=$$0; sub(/:id: [^ ]+$$/, "", p); print u"\t"p}' > "$$index"; \
	cut -f1 "$$index" | sort -u > "$$ids"; \
	refs=$$(grep -hvE '^[[:space:]]*(-[[:space:]]+)?id:' $$files 2>/dev/null | grep -oE '[0-9A-HJKMNP-TV-Z]{26}' | sort -u || true); \
	missing=""; \
	for r in $$refs; do \
	  grep -qxF "$$r" "$$ids" || missing="$$missing $$r"; \
	done; \
	test -z "$$missing" || { rm -f "$$index" "$$ids"; echo "check: referenced ULID(s) with no record:$$missing"; exit 1; }; \
	echo "check: every referenced ULID resolves"; \
	echo "check: references in the changed files (each ULID must name the entity the claim means):"; \
	for f in $$files; do \
	  pairs=$$($(YQ) -o=json -I0 '.' "$$f" 2>/dev/null \
	    | $(JQ) -r '[paths(scalars) as $$p | select($$p[-1] != "id") | select((getpath($$p)|type)=="string") | select(getpath($$p)|test("^[0-9A-HJKMNP-TV-Z]{26}$$")) | "\($$p|join(".")) \(getpath($$p))"] | .[]'); \
	  test -n "$$pairs" || continue; \
	  printf '  %s\n' "$$f"; \
	  printf '%s\n' "$$pairs" | while read -r path ulid; do \
	    src=$$(awk -F'\t' -v u="$$ulid" '$$1==u{print $$2; exit}' "$$index"); \
	    if [ -z "$$src" ]; then printf '    %s -> %s  (no record)\n' "$$path" "$$ulid"; continue; fi; \
	    info=$$($(YQ) -o=json '.' "$$src" | $(JQ) -r '"\(.type)\t\((.name // .title // (if .specializationOf then "state \(.archivedDate // .accessedDate) of \(.specializationOf)" else null end)) | if type=="object" then (.en // .["ja-Latn"] // .ja // .pt // (to_entries[0].value)) else . end)"'); \
	    printf '    %s -> %s  %s (%s)\n' "$$path" "$$ulid" "$${info#*$$'\t'}" "$${info%%$$'\t'*}"; \
	  done; \
	done; \
	rm -f "$$index" "$$ids"
	@# Media URLs: a schema can check that `contentUrl` is a string, never that it
	@# resolves, and a guessed upload.wikimedia.org shard is a valid IRI that 404s.
	@# HEAD-request every image/photo/logo URL the changed files declare: a 4xx/5xx
	@# fails, except 403 and 429, which are bot-block and rate-limit rather than
	@# evidence of a dead link (the same two the `links` target accepts), and a
	@# transport error (offline) is reported but does not fail, because the URL
	@# was not disproved.
	@files="$(FILES)"; \
	if [ -z "$$files" ]; then files=$$($(MAKE) --no-print-directory -s changed); fi; \
	urls=$$(mktemp); \
	for f in $$files; do \
	  $(YQ) -o=json -I0 '.' "$$f" 2>/dev/null \
	    | $(JQ) -r '[.image?.contentUrl?, .photos[]?.contentUrl?, .logo?.contentUrl?] | .[] | select(type=="string" and test("^https?://"))'; \
	done | sort -u > "$$urls"; \
	if [ ! -s "$$urls" ]; then rm -f "$$urls"; exit 0; fi; \
	echo "check: media URLs:"; \
	rc=0; \
	while read -r url; do \
	  code=$$(curl -s -o /dev/null -w '%{http_code}' -I --max-time 15 "$$url" 2>/dev/null); \
	  [ $$? -ne 0 ] && code=000; \
	  case "$$code" in \
	    2*|3*) printf '    ok    %s\n' "$$url";; \
	    000)   printf '    ?     %s (no response - offline?)\n' "$$url";; \
	    403|429) printf '    ?     %s (HTTP %s - rate-limited or bot-blocked, not dead)\n' "$$url" "$$code";; \
	    *)     printf '    DEAD  %s (HTTP %s)\n' "$$url" "$$code"; rc=1;; \
	  esac; \
	done < "$$urls"; \
	rm -f "$$urls"; \
	test $$rc -eq 0 || { echo "check: dead media URL(s) - fetch the real URL from the source, never construct the path"; exit 1; }

## YAML -> RDF: build export/data.ttl and check its graph invariants.
## Document-shape work (one shared @context, failing on a record
## with no id, giving every nested node its @type and a deterministic @id from
## the context's generated nestedTypes map) is pipeline/scripts/prepare.jq;
## graph-shape work is pipeline/rules/*.ru, applied in filename order.
## Always regenerated: one entity filename contains a colon, which make
## cannot carry in a prerequisite list, and the step is ~8s anyway. Make
## still runs it only once per invocation however many targets need it.
rdf:
	@mkdir -p export
	@# The nested-node typing now depends on the generated map, so an absent or
	@# empty map would silently leave every nested node untyped. Fail before
	@# converting rather than let a shape-less export through.
	@$(JQ) -e '.["nestedTypes"] | length > 0' schemas/context.jsonld > /dev/null \
	  || { echo "rdf: schemas/context.jsonld carries no nestedTypes map - nested nodes would be untyped"; exit 1; }
	@# xargs splits a long file list into several yq runs, each printing its own
	@# array; `jq -s add` joins them into one. Without it prepare.jq writes one
	@# JSON-LD document per batch and riot reads only the first, silently.
	@find database -name '*.yaml' -not -path 'database/templates/*' -print0 \
	  | xargs -0 $(YQ) -o=json -I0 ea '[.]' \
	  | $(JQ) -c -s 'add' \
	  | $(JQ) --argjson ctx "$$($(JQ) '.["@context"]' schemas/context.jsonld)" \
	       --argjson types "$$($(JQ) '.["nestedTypes"]' schemas/context.jsonld)" \
	       -f pipeline/scripts/prepare.jq \
	  > export/.prepared.jsonld
	@# JSON-LD is a quads-capable syntax, so riot warns when asked for
	@# triples. Drop just that line; every other diagnostic still shows.
	@$(RIOT) -q --syntax=jsonld --output=nt export/.prepared.jsonld \
	  2> >(grep -v 'Quads syntax in the input files' >&2) > export/.raw.nt
	@# Every record file must come out as one typed entity: the count is known
	@# independently of the conversion, so a dropped batch or record fails here
	@# instead of shipping a partial export.
	@want=$$(find database -name '*.yaml' -not -path 'database/templates/*' | wc -l); \
	got=$$(grep -E '^<https://martial\.is/entity/[0-9A-HJKMNP-TV-Z]{26}> <http://www\.w3\.org/1999/02/22-rdf-syntax-ns#type> <https://w3id\.org/martialis/ontology#(Person|Organization|Place|Style|Source|Event|RankingSystem)> \.$$' export/.raw.nt \
	      | cut -d' ' -f1 | sort -u | wc -l); \
	test "$$got" -eq "$$want" \
	  || { echo "rdf: $$want record files but $$got entities converted - $(DATA) left as it was"; exit 1; }
	@# One --update per rule file, in filename order: Jena applies repeated
	@# --update flags in the order given.
	@# No rule reads the ontology, and the vocabulary is no rule's input
	@# either, so neither is loaded.
	@$(UPDATE) --data=export/.raw.nt --data=$(DATASET) \
	           $(foreach r,$(wildcard pipeline/rules/*.ru),--update=$(r)) --dump 2>/dev/null \
	  | $(RIOT) -q --syntax=trig --output=turtle 2>/dev/null > export/.data.ttl
	@# Two reasons this does not write straight to $(DATA). The redirection
	@# `> $(DATA)` truncates the COMMITTED export the instant the recipe
	@# starts, so any failure in the pipeline above left a 0-byte data.ttl on
	@# disk for the next `git commit -a` to pick up. And riot exits 0 on empty
	@# input, so a step that produced nothing is indistinguishable from a
	@# successful export of nothing. Both are caught before the artifact is
	@# touched: build to a temp, check the result, then move.
	@#
	@# The check has to be about entity triples, not just a triple count:
	@# --data=$(DATASET) contributes the dataset front matter regardless of
	@# what happens to the data, so a pipeline that collapsed to nothing still
	@# emits ~18 metadata triples and would sail past `-gt 0`. An export that
	@# mentions no entity IRI at all is not an export.
	@n=$$($(RIOT) --output=nt export/.data.ttl 2>/dev/null | wc -l); \
	ent=$$(grep -c 'martial\.is/entity/' export/.data.ttl || true); \
	test "$$n" -gt 0 && test "$$ent" -gt 0 \
	  || { echo "rdf: no entity triples in the result - $(DATA) left as it was"; rm -f export/.data.ttl; exit 1; }; \
	mv export/.data.ttl $(DATA); \
	echo "rdf: $$n triples -> $(DATA)"
	@rm -f export/.prepared.jsonld export/.raw.nt
	@# The three graph invariants run here, in the same recipe, so they cost no
	@# extra make step. Each fails closed: a query that does not parse is caught
	@# by its own exit status - captured BEFORE any pipe, because `cmd | tail`
	@# reports tail's status and a parse failure would look exactly like a query
	@# that found nothing - and an empty thing to check is a failure rather
	@# than a clean pass.
	@#
	@# pipeline/checks/ontology-coverage.rq: every martialis: term reaching the
	@# export must be declared in the ontology. An undeclared nested-node class
	@# has no generated shape, so no sh:targetClass matches the node and nothing
	@# validates it; an undeclared type has the same effect. The generated JSON
	@# Schema already rejects an unknown key, so this is the independent
	@# graph-side check, silent in every other step. Rule predicates are
	@# declared in model/ontology-overlay.ttl, so this is the only detector of a
	@# rule emitting an undeclared predicate.
	@test -s $(DATA) && test -s $(ONTOLOGY) \
	  || { echo "ontology coverage: missing $(DATA) or $(ONTOLOGY)"; exit 1; }
	@# Vacuity guard: if the export mentions no martialis: terms the query below
	@# finds nothing to check and would report a clean pass while proving nothing.
	@n=$$(grep -c 'w3id\.org/martialis/ontology#' $(DATA) || true); \
	test "$$n" -gt 0 || { echo "ontology coverage: $(DATA) mentions no martialis: terms - nothing to verify"; exit 1; }
	@out=$$($(SPARQL) --data=$(DATA) --data=$(ONTOLOGY) \
	          --query=pipeline/checks/ontology-coverage.rq --results=tsv 2>/dev/null) \
	  || { echo "ontology coverage: query failed - terms are unverified"; exit 1; }; \
	rows=$$(printf '%s\n' "$$out" | tail -n +2); \
	if [ -n "$$rows" ]; then \
	  echo "ontology coverage: undeclared martialis: term(s) reach the export"; \
	  printf '%s\n' "$$rows" | sed 's/^/  /'; exit 1; \
	fi; \
	echo "ontology coverage: every martialis: term in the export is declared"
	@# pipeline/checks/skos-integrity.rq: SKOS integrity conditions (S13/S14,
	@# notation/inScheme presence, inScheme resolving to a declared scheme)
	@# plus the house no-lowercase-initial-prefLabel rule, over the hand-authored
	@# vocabulary. Not OWL axioms - HermiT does not see them - and not covered by
	@# SHACL, which targets the DATA graph, not the vocabulary itself.
	@n=$$(grep -c 'skos:Concept' $(VOCAB) || true); \
	test "$$n" -gt 0 || { echo "skos integrity: $(VOCAB) declares no skos:Concept - nothing to verify"; exit 1; }
	@out=$$($(SPARQL) --data=$(VOCAB) \
	          --query=pipeline/checks/skos-integrity.rq --results=tsv 2>/dev/null) \
	  || { echo "skos integrity: query failed - the vocabulary is unverified"; exit 1; }; \
	rows=$$(printf '%s\n' "$$out" | tail -n +2); \
	if [ -n "$$rows" ]; then \
	  echo "skos integrity: violation(s) found in $(VOCAB)"; \
	  printf '%s\n' "$$rows" | sed 's/^/  /'; exit 1; \
	fi; \
	echo "skos integrity: $(VOCAB) satisfies S13/S14, notation/inScheme and label-case"
	@# pipeline/checks/reference-integrity.rq: every entity IRI used as an object
	@# must resolve to a described record. A cross-reference to a ULID no record
	@# carries is a dangling IRI that RDF, the JSON Schema (which checks only the
	@# 26-character shape) and every structural shape accept silently; this is
	@# the only detector. Fails closed: the query's own status is captured before
	@# any pipe, and an export that mentions no entity IRIs is a failure rather
	@# than a vacuously clean pass.
	@test -s pipeline/checks/reference-integrity.rq \
	  || { echo "reference integrity: pipeline/checks/reference-integrity.rq missing"; exit 1; }
	@n=$$(grep -c 'martial\.is/entity/' $(DATA) || true); \
	test "$$n" -gt 0 || { echo "reference integrity: $(DATA) mentions no entity IRIs - nothing to verify"; exit 1; }
	@out=$$($(SPARQL) --data=$(DATA) \
	          --query=pipeline/checks/reference-integrity.rq --results=tsv 2>/dev/null) \
	  || { echo "reference integrity: query failed - references are unverified"; exit 1; }; \
	rows=$$(printf '%s\n' "$$out" | tail -n +2); \
	if [ -n "$$rows" ]; then \
	  echo "reference integrity: dangling cross-reference(s) - no such record:"; \
	  printf '%s\n' "$$rows" | sed 's/^/  /'; exit 1; \
	fi; \
	echo "reference integrity: every referenced entity resolves"

## SHACL validation of the export (blocking).
## Two shapes graphs: the shapes generated from
## model/martialis.yaml plus the hand-authored data-level constraints that
## cannot be derived from the model. `cat` them into one graph because Jena's
## shacl CLI takes a single --shapes file. vocabularies.ttl rides along as data
## so the concept-scheme shapes have concepts to resolve against.
##
## The engine's own exit status (a malformed shapes file, a bad sh:sparql, a
## Jena crash) is checked separately from "ran but reported violations", and
## neither diagnostic path swallows stderr, so a failure always says why.
shacl: rdf
	@$(NOIMPORT) ontology/martialis.shacl.ttl > export/.shapes.ttl
	@$(NOIMPORT) ontology/martialis-constraints.shacl.ttl >> export/.shapes.ttl
	@cat $(DATA) $(VOCAB) > export/.shacl-data.ttl
	@if ! $(SHACL) validate --shapes export/.shapes.ttl --data export/.shacl-data.ttl \
	     > export/.structural.ttl 2> export/.shacl-stderr; then \
	  echo "shacl: the SHACL engine failed to run"; cat export/.shacl-stderr >&2; \
	  rm -f export/.shapes.ttl export/.shacl-data.ttl export/.structural.ttl export/.shacl-stderr export/.control.ttl export/.control-stderr; \
	  exit 1; \
	fi; \
	if grep -q 'sh:conforms *true' export/.structural.ttl; then \
	  echo "shacl: conforms"; \
	else \
	  $(SPARQL) --data=export/.structural.ttl --query=pipeline/reports/report-findings.rq --results=text; \
	  rm -f export/.shapes.ttl export/.shacl-data.ttl export/.structural.ttl export/.shacl-stderr export/.control.ttl export/.control-stderr; \
	  exit 1; \
	fi
	@# Negative control: the validation above proves the corpus conforms, but a
	@# validator that accepts everything would look identical. Validate a small
	@# fixture that deliberately breaks a few hand-authored blocking constraints
	@# and require the report to say it does not conform and to name them. The
	@# fixture is plain triples, not a record, so no entity directory owns it.
	@# An unexpected conform, or a report that fails to name the constraints the
	@# fixture targets, is a hard failure.
	@test -s pipeline/fixtures/reject-shapes.ttl \
	  || { echo "shacl: negative-control fixture pipeline/fixtures/reject-shapes.ttl missing"; exit 1; }; \
	if ! $(SHACL) validate --shapes export/.shapes.ttl --data pipeline/fixtures/reject-shapes.ttl \
	     > export/.control.ttl 2> export/.control-stderr; then \
	  echo "shacl: the SHACL engine failed on the negative control"; cat export/.control-stderr >&2; \
	  exit 1; \
	fi; \
	if grep -q 'sh:conforms *true' export/.control.ttl; then \
	  echo "shacl: negative control conforms - validation would not reject a known-bad graph"; \
	  exit 1; \
	fi; \
	for s in PersonBirthAfterDeathShape TimeIntervalOrderShape SiteContainmentCycleShape SourceSpecializationShape UnidentifiedTeacherAnchorShape SameAsUniqueShape IdentityAssertionSelfShape StyleRelationSelfShape AffiliationSelfShape; do \
	  grep -q "$$s" export/.control.ttl \
	    || { echo "shacl: negative control rejected but does not name $$s"; exit 1; }; \
	done; \
	grep -q 'TeacherInteraction has no evidence' export/.control.ttl \
	  || { echo "shacl: negative control rejected but the evidence constraint did not fire"; exit 1; }; \
	for m in 'and no anchor asserts' 'and no period asserts'; do \
	  grep -q "$$m" export/.control.ttl \
	    || { echo "shacl: negative control rejected but the unidentified-teacher constraint '$$m' did not fire"; exit 1; }; \
	done; \
	for m in 'is itself a dated state' 'carries no title, sourceType or partOf' 'has dated states' 'neither archivedDate nor accessedDate' 'needs a title and a sourceType'; do \
	  grep -q "$$m" export/.control.ttl \
	    || { echo "shacl: negative control rejected but the dated-state constraint '$$m' did not fire"; exit 1; }; \
	done; \
	echo "shacl: negative control rejected as expected"
	@# Shape aliveness: a hand-authored constraint whose target class or path no
	@# longer occurs in the export matches nothing, and a shape that matches
	@# nothing reports no violation - a live constraint and a dead one are
	@# indistinguishable on a clean corpus. pipeline/checks/shape-alive.rq
	@# returns one row per target-bearing hand-authored shape with its focus
	@# count and any property paths no focus node carries (presence constraints
	@# are exempt: their absence is the violation). Fail closed: the query's own
	@# status is captured before any pipe, the empty result is a failure, and the
	@# number of shapes examined must equal the target declarations counted
	@# independently in the shapes file.
	@test -s ontology/martialis-constraints.shacl.ttl \
	  || { echo "shape aliveness: ontology/martialis-constraints.shacl.ttl missing"; exit 1; }; \
	want=$$(grep -cE '^[[:space:]]*sh:target(Class|SubjectsOf|ObjectsOf|Node)[[:space:]]' ontology/martialis-constraints.shacl.ttl || true); \
	test "$$want" -gt 0 \
	  || { echo "shape aliveness: no target-bearing hand-authored shape in ontology/martialis-constraints.shacl.ttl"; exit 1; }; \
	out=$$($(SPARQL) --data=$(DATA) --data=ontology/martialis-constraints.shacl.ttl \
	          --query=pipeline/checks/shape-alive.rq --results=tsv 2>/dev/null) \
	  || { echo "shape aliveness: query failed - hand-authored constraints are unverified"; exit 1; }; \
	rows=$$(printf '%s\n' "$$out" | tail -n +2 | grep . || true); \
	got=$$(printf '%s\n' "$$rows" | grep -c . || true); \
	test "$$got" = "$$want" \
	  || { echo "shape aliveness: examined $$got shape row(s), shapes file declares $$want target(s) - refusing to pass"; exit 1; }; \
	dead=$$(printf '%s\n' "$$rows" | awk -F'\t' '$$3 == 0 || ($$3 > 0 && $$4 != "")' || true); \
	if [ -n "$$dead" ]; then \
	  echo "shape aliveness: hand-authored constraint(s) match nothing in $(DATA)"; \
	  printf '%s\n' "$$dead" | sed 's/^/  /'; exit 1; \
	fi; \
	echo "shape aliveness: $$got hand-authored constraint shape(s) still match the export"
	@rm -f export/.shapes.ttl export/.shacl-data.ttl export/.structural.ttl export/.shacl-stderr export/.control.ttl export/.control-stderr

## Quality/completeness SHACL report (informational: never fails).
quality: rdf
	@$(NOIMPORT) ontology/martialis-quality.shacl.ttl > export/.qshapes.ttl
	@cat $(DATA) $(VOCAB) > export/.shacl-data.ttl
	@$(SHACL) validate --shapes export/.qshapes.ttl --data export/.shacl-data.ttl 2>/dev/null > export/quality-report.ttl
	@$(SPARQL) --data=export/quality-report.ttl --query=pipeline/reports/report-findings.rq --results=text
	@rm -f export/.qshapes.ttl export/.shacl-data.ttl
	@# Same aliveness question as the blocking shapes, asked of the quality
	@# shapes. Reporting only: a dead quality shape is printed here, never a
	@# reason to fail, matching this target's contract. The query's own status
	@# is not checked for the same reason; an empty result is flagged rather
	@# than read as a pass.
	@out=$$($(SPARQL) --data=$(DATA) --data=ontology/martialis-quality.shacl.ttl \
	          --query=pipeline/checks/shape-alive.rq --results=tsv 2>/dev/null); \
	if [ -z "$$out" ]; then \
	  echo "quality shape aliveness: query produced nothing - quality shapes unverified"; \
	else \
	  rows=$$(printf '%s\n' "$$out" | tail -n +2 | grep . || true); \
	  dead=$$(printf '%s\n' "$$rows" | awk -F'\t' '$$3 == 0 || ($$3 > 0 && $$4 != "")' || true); \
	  if [ -n "$$dead" ]; then \
	    echo "quality shape aliveness: quality shape(s) match nothing (reporting only):"; \
	    printf '%s\n' "$$dead" | sed 's/^/  /'; \
	  else \
	    echo "quality shape aliveness: every quality shape still matches the export"; \
	  fi; \
	fi

## OWL 2 DL conformance and ontology/data consistency (blocking).
## The ontology targets OWL 2 DL (it says so with dcterms:conformsTo), so the
## step checks the profile first and then reasons with HermiT, whose verdict is
## only sound for DL input.
##
## The ontology and the export are merged into ONE document before either check.
## OWLAPI decides each triple's role (class, object or data property,
## annotation) from the declarations it has seen when it parses a document;
## parsed on its own, export/data.ttl declares nothing, so every property value
## became an annotation, which HermiT ignores - the check saw the data's types
## and none of its values. --catalog resolves every owl:imports IRI (the PROV-O,
## ORG and BIBO modules, and the two alignments) to a local file, so the step
## runs offline.
## Each check has a negative control: a fixture it must reject.
reasoner: rdf
	@tmp=$$(mktemp --suffix=.ttl); rep=$$(mktemp); res=$$(mktemp --suffix=.ttl); trap 'rm -f "$$tmp" "$$rep" "$$res"' EXIT; \
	$(RIOT) --output=turtle $(ONTOLOGY) $(DATA) > $$tmp 2>/dev/null && test -s $$tmp \
	  || { echo "reasoner: could not merge $(ONTOLOGY) and $(DATA)"; exit 1; }; \
	if ! $(ROBOT) validate-profile --catalog $(CATALOG) --input $$tmp --profile DL --output $$rep >/dev/null 2>&1; then \
	  echo "reasoner: the ontology with the export is not OWL 2 DL:"; head -20 $$rep | sed 's/^/  /'; exit 1; \
	fi; \
	echo "reasoner: ontology and export are OWL 2 DL"; \
	out=$$($(ROBOT) reason --catalog $(CATALOG) --input $$tmp --reasoner HermiT --output $$res 2>&1); rc=$$?; \
	printf '%s\n' "$$out" | grep -v "Unwise IRI\|WARNING\|^$$" || true; \
	test $$rc -eq 0 || { echo "reasoner: HermiT did not find the merge consistent (see above; robot explain --mode inconsistency names the axioms)"; exit 1; }; \
	echo "reasoner: consistent"
	@# Negative controls, merged with the ontology the same way. reject-reasoner*
	@# fixtures must be inconsistent: one breaks a disjointness axiom through
	@# types, one only through a property value, which proves values reach
	@# HermiT. reject-profile.ttl must fail the DL check.
	@tmp=$$(mktemp --suffix=.ttl); rep=$$(mktemp); res=$$(mktemp --suffix=.ttl); trap 'rm -f "$$tmp" "$$rep" "$$res"' EXIT; \
	n=0; for f in pipeline/fixtures/reject-reasoner*.ttl; do \
	  $(RIOT) --output=turtle $(ONTOLOGY) $$f > $$tmp 2>/dev/null \
	    || { echo "reasoner: could not merge the ontology and $$f"; exit 1; }; \
	  if $(ROBOT) reason --catalog $(CATALOG) --input $$tmp --reasoner HermiT --output $$res >/dev/null 2>&1; then \
	    echo "reasoner: negative control $$f is consistent - the reasoner would not reject a known-bad graph"; exit 1; \
	  fi; n=$$((n+1)); \
	done; \
	test $$n -ge 2 || { echo "reasoner: expected at least 2 reject-reasoner fixtures, found $$n"; exit 1; }; \
	$(RIOT) --output=turtle $(ONTOLOGY) pipeline/fixtures/reject-profile.ttl > $$tmp 2>/dev/null \
	  || { echo "reasoner: could not merge the ontology and the profile fixture"; exit 1; }; \
	if $(ROBOT) validate-profile --catalog $(CATALOG) --input $$tmp --profile DL --output $$rep >/dev/null 2>&1; then \
	  echo "reasoner: negative control reject-profile.ttl is in OWL 2 DL - the profile check would not reject a pun"; exit 1; \
	fi; \
	echo "reasoner: $$n reasoner controls and the profile control rejected as expected"

## Curation worklist: every quality finding, one row per finding.
## Each row is attributed to the record it belongs to (a finding on a nested
## claim names its owning record plus the path below it). `make quality` is the count view; this is
## the "what do I research next" view, and `review` filters it by ULID.
## Filter it like any text: `make worklist | grep "birth date"`.
worklist: quality
	@$(SPARQL) --data=export/quality-report.ttl --data=$(DATA) \
	           --query=pipeline/reports/worklist.rq --results=csv 2>/dev/null > export/worklist.csv
	@echo "worklist: $$(($$(wc -l < export/worklist.csv) - 1)) findings -> export/worklist.csv"
	@tail -n +2 export/worklist.csv | cut -d, -f1 | sort | uniq -c | sort -rn | sed 's/^/  /'

## ------------------------------------------------------------- reports

## Print the report: every query in pipeline/reports/<target>/.
## Add a .rq file, get a report section.
## pipeline/reports/examples/ is not a report target: it holds the runnable
## queries the documentation points at, and reports-json executes them, so CI
## parse-checks them and they cannot rot.
## Each query's exit status is checked: without this a malformed query in a
## non-final position prints nothing (stderr is suppressed) and the target
## still succeeds, so the report silently loses a section.
provenance dashboard styles: rdf
	@rc=0; for q in pipeline/reports/$@/*.rq; do \
	  echo; echo "== $$(basename $$q .rq)"; \
	  $(SPARQL) --data=$(DATA) --data=$(ONTOLOGY) --data=$(VOCAB) \
	            --query=$$q --results=text 2>/dev/null \
	    || { echo "  QUERY FAILED: $$q"; rc=1; }; \
	done; test $$rc -eq 0 || exit 1

## The same reports as SPARQL JSON results, one file per query.
## For machine consumers (CI artifacts, dashboards).
##
## Parallel, because the queries are independent and each costs a JVM start.
## xargs does the error handling: it exits 123 if any child fails, and each
## child prints which query failed.
reports-json: rdf
	@mkdir -p export/reports
	@# The path transform runs on the name WITHOUT the directory: replacing
	@# every slash, as a one-liner tempts you to, also eats the one in
	@# export/reports/ and silently scatters the files into the repo root.
	@find pipeline/reports -name '*.rq' | sort \
	  | xargs -P $$(nproc) -I{} bash -c ' \
	      out="$${1#pipeline/reports/}"; \
	      out="$${out//\//-}"; out="$${out%.rq}.json"; \
	      $(SPARQL) --data=$(DATA) --data=$(ONTOLOGY) --data=$(VOCAB) \
	                --query="$$1" --results=json > "export/reports/$$out" 2>/dev/null \
	        || { echo "  QUERY FAILED: $$1" >&2; exit 1; }' _ {}
	@echo "reports-json: $$(ls export/reports | wc -l) files -> export/reports/"

## Source integrity: duplicates by url/doi/isbn, and the CSL-JSON export.
##
## The CSL-JSON is written to a temp file and moved into place only once its
## item count equals the number of Source files, so a failure (jq exits 0 on
## empty input) leaves the committed artifact untouched.
sources: rdf
	@$(SPARQL) --data=$(DATA) --query=pipeline/reports/sources/duplicates.rq --results=text 2>/dev/null
	@tmp=$$(mktemp); trap 'rm -f "$$tmp"' EXIT; \
	if ! $(YQ) -o=json -I0 ea '[.]' database/sources/*/*.yaml | $(JQ) -f pipeline/scripts/csl.jq > $$tmp; then \
	  echo "sources: CSL-JSON generation failed - export/sources.csl.json left as it was"; exit 1; \
	fi; \
	want=$$(ls database/sources/*/*.yaml | wc -l); n=$$($(JQ) 'length' $$tmp); \
	test "$$n" = "$$want" \
	  || { echo "sources: $$n CSL-JSON items for $$want source files - refusing to write it"; exit 1; }; \
	mv $$tmp export/sources.csl.json; \
	echo "sources: $$n CSL-JSON items -> export/sources.csl.json"

## The Martialis Index (method: https://martial.is/ranking-methodology).
##
## pipeline/scripts/index.py needs only python3, no packages: yq turns the Person
## and Style records into one JSON array for it. The index is built to a temp
## file and moved into place only once `index.py validate` passes, so a failure
## leaves the committed export/martialis-index.json untouched.
INDEX   := export/martialis-index.json
RECORDS := export/.records.json
PYTHON  ?= python3

$(RECORDS): $(shell find database/persons database/styles -name '*.yaml')
	@mkdir -p export
	@find database/persons database/styles -name '*.yaml' -print0 \
	  | xargs -0 $(YQ) -o=json -I0 ea '[.]' | $(JQ) -c -s 'add' > $@

index: $(RECORDS)
	@tmp=$$(mktemp); trap 'rm -f "$$tmp"' EXIT; \
	$(PYTHON) pipeline/scripts/index.py compute $(RECORDS) $$tmp \
	  && $(PYTHON) pipeline/scripts/index.py validate $$tmp \
	  && mv $$tmp $(INDEX)

## Top 25 and the per-era tables of the committed index.
index-report:
	@$(PYTHON) pipeline/scripts/index.py report --era $(INDEX)

## How the ranking moves across the parameter grid, and what the branch correction does.
index-sensitivity: $(RECORDS)
	@$(PYTHON) pipeline/scripts/index.py sensitivity $(RECORDS)

## External link health (slow, needs network).
##
## Fails closed: a failed query, an empty URL list (lychee happily checks zero
## links) and a missing lychee binary are all errors, never a clean report. It
## stays out of `validate` because it needs the network.
links: rdf
	@urls=$$($(SPARQL) --data=$(DATA) --query=pipeline/reports/urls.rq --results=csv 2>/dev/null) \
	  || { echo "links: pipeline/reports/urls.rq failed - nothing was checked"; exit 1; }; \
	printf '%s\n' "$$urls" | tail -n +2 | tr -d '"' > export/urls.txt; \
	n=$$(grep -c . export/urls.txt || true); \
	test "$$n" -gt 0 \
	  || { echo "links: the query produced no URLs - refusing to report a clean link check"; exit 1; }; \
	echo "links: $$n URLs -> export/urls.txt (lychee is slow and needs the network)"
	@# 403 (bot-block) and 429 (rate limit) dominate a run and are NOT evidence
	@# of a dead link. Measured over the full corpus: 404 x52, 429 x70, 403 x44,
	@# transport x31. Retries absorb the transient ones; if the unverifiable
	@# categories still swamp the real 404s, `--accept '200..=299,403,429'` makes
	@# the exit status mean "dead links only", at the cost of those two
	@# categories no longer appearing in the report.
	@$(LYCHEE) export/urls.txt --suggest --no-progress --max-retries 3 --retry-wait-time 2 \
	  --format json --output export/link-report.json

## Delete the generated report files under export/.
clean-reports:
	@rm -rf export/reports export/link-report.json export/quality-report.ttl export/worklist.csv export/urls.txt export/.[a-z]*
