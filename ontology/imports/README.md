# Import modules

The Martialis ontology is OWL 2 DL. The vocabularies it reuses are not OWL 2 DL as published, so
`ontology/martialis.ttl` does not import any of them whole.

**PROV-O, ORG and BIBO** are imported as ROBOT STAR modules. Their axioms affect Martialis classes
and properties. A STAR module keeps only the axioms that involve the terms in a `.terms` file.

`make imports` builds `prov-module.ttl`, `org-module.ttl` and `bibo-module.ttl` from the vendored
files. It writes a module only if ROBOT confirms the result is OWL 2 DL. The modules are generated
and committed. To change one, edit its `.terms` file and rerun `make imports`. Do not edit the
module.

`make model` also copies each imported term's declaration into `martialis.ttl`, so the ontology
still parses without its imports.

**DCTERMS, SKOS, schema.org, FaBiO, FOAF, VANN and MOD** are not imported. Their terms are declared
in `model/ontology-overlay.ttl`, under "Reused external terms". Each declaration gives the term the
role the ontology uses it in. This is the MIREOT approach: include only the minimum needed to refer
to an external term.

## Why not import them whole?

- PROV-O declares `prov:specializationOf` and `prov:wasRevisionOf` as both annotation and object
  properties. OWL 2 DL does not allow that.
- ORG uses FOAF and DCTERMS terms that it does not declare.
- BIBO uses DCTERMS terms that it does not declare.
- DCTERMS, SKOS and schema.org are RDF vocabularies, not OWL 2 DL ontologies.

## Files

The copies were fetched on 2026-08-27.

- `prov-o.ttl`: PROV-O, <http://www.w3.org/ns/prov-o>. Licence: W3C-20150513. Input to
  `prov-module.ttl`.
- `org.ttl`: W3C Organization Ontology, <http://www.w3.org/ns/org>. Licence: PDDL-1.0 (the file's
  `dct:license`). Input to `org-module.ttl`.
- `bibo.rdf`: BIBO, <http://purl.org/ontology/bibo/>. Licence: none stated upstream (see
  `LICENSES/LicenseRef-BIBO-unstated.txt`). Input to `bibo-module.ttl`.
- `skos.rdf`: SKOS, <https://www.w3.org/2009/08/skos-reference/skos.rdf>. Licence: W3C-20150513.
  Reference only.
- `dcterms.rdf`: DCMI Metadata Terms, <http://purl.org/dc/terms/>. Licence: CC BY 4.0 (DCMI).
  Reference only.

## Local changes

Two triples are removed from the vendored copies:

- `org:hasMember owl:equivalentProperty foaf:member` in `org.ttl`
- `dcterms:creator owl:equivalentProperty foaf:maker` in `dcterms.rdf`

Both point to FOAF terms that are not in the vendored files. ROBOT reported `Input ontology contains
1 triple(s) that could not be parsed` for each. Apart from these two deletions, the files are
upstream copies.

`REUSE.toml` assigns each module its upstream file's licence. The files are distributed with this
repository under those licences.
