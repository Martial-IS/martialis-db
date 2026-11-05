# Licensing and rights

Maker of the database: Frederico Muñoz, Lisbon, Portugal. Martialis™ is an
unregistered trademark of Frederico Muñoz.

## Sui generis database right

The maker asserts the sui generis database right under
[Directive 96/9/EC](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:31996L0009)
on the legal protection of databases, transposed in Portugal by
[Decreto-Lei n.º 122/2000](https://diariodarepublica.pt/dr/detalhe/decreto-lei/122-2000-291706).
That right is licensed under CC-BY-SA-4.0, not separately from it: it is one of
the rights the licence grants.

- The right protects the substantial investment made in obtaining, verifying,
  and presenting the database's contents (Art. 7).
- Investment means the work of establishing and sourcing the contents: source
  acquisition and reading, quotation transcription, cross-checking conflicting
  accounts, confidence-level assessment, translation of non-English sources,
  and the pipeline and ontology engineering that makes verification checkable
  (schema, SHACL, the reasoner gate).
- Creating the underlying facts does not count on its own. The bare fact
  "X trained under Y" exists in the world; only the work of establishing and
  sourcing it is investment. Verification counts, creation does not
  (*BHB v William Hill*).
- It is automatic, requires no registration, and lasts 15 years from
  completion of the database. Each substantial new investment restarts the
  term; the [investment log](#investment-log) records it.

What the licence means for the database contents:

- You may extract, reuse, reproduce and share all or a substantial part of the
  contents (Section 4(a)).
- If you share all or a substantial part, the attribution conditions in Section
  3(a) apply (Section 4(c)).
- If you include all or a substantial part in a database of your own in which
  you hold database rights, that database is Adapted Material, but its
  individual contents are not (Section 4(b)). If you share that database, the
  ShareAlike conditions in Section 3(b) apply.
- A use the licence does not permit, and no exception covers, needs a separate
  licence from the maker.

The database's ULID identifiers, confidence-assessment wording, and record
ordering identify this database's own content.

A notice only works if it reaches the person extracting the data, not just a
visitor to this repository. That is why the short form travels with the data: it
is the label of the `dcterms:rights` statement in `export/data.ttl`, and it is
meant for the site footer and API response headers that serve the data outside
this repo.

### Investment log

- **2023-04-19 – 2026-02-27** (pre-repository): Work under the project's former name, *Budō Lineage Tree*, in the public [budotree](https://github.com/Judo-Documentation-Project/budotree) repository. It predates this repository's git history, so it is recorded here as a summary rather than itemised from this repo's evidence.
- **2026-02-28 – 2026-09-06** (pre-v1.0.0), 1,587 entities / 93,937 triples: 46 commits under the *Martialis* name: the person/style/place/source/org/event/ranking-system schema and ontology built from scratch, 845 source records added and verified, the confidence-assessment and SHACL validation pipeline built, and the ontology revisions leading to 1.0.0 (their record is the pre-release repository, fingerprinted at [10.5281/zenodo.23951136](https://doi.org/10.5281/zenodo.23951136)). Counts are the hand-recorded period-end values; the current `void:entities` and `void:triples` counts are in `export/data.ttl`.
- **2026-09-07 – 2026-11-05** (1.0.0), 2,911 entities / 161,460 triples: 528 commits: the source, quotation and confidence passes over the corpus, 1452 source records in total, and the model and pipeline completed for the first public release. The pre-release repository is fingerprinted at [10.5281/zenodo.23951136](https://doi.org/10.5281/zenodo.23951136).

One entry per release period. Sources for the rows: `git log` and the YAML file
count under `database/`.

### Personal data of living people

The database records identifiable living people: names, dates and places of
birth, photographs, teacher/student relationships, ranks, and training
venues.

- **Basis**: legitimate interests (GDPR Art. 6(1)(f)), for archiving in the
  public interest and historical research (Art. 89(1)); complemented in
  Portugal by [Lei n.º 58/2019](https://diariodarepublica.pt/dr/detalhe/lei/58-2019-122379073),
  Arts. 24 and 31.
- **Not collected**: contact details, current training schedules, or any
  special category of data (GDPR Art. 9).
- **Rights**: rectification (Art. 16) and objection (Art. 21). Request via
  the [issue tracker](https://github.com/Martial-IS/martialis-db/issues) or
  by email to the maker. Requests are honoured without argument.
- **Erasure**: applies to the current database and every release from that
  point forward. It does not alter git history already published or prior
  releases already distributed.

## The five tiers

Licences are assigned per tier. This document is the authoritative map;
per-file licence and copyright metadata is machine-readable via
[REUSE](https://reuse.software/) (`REUSE.toml`, `LICENSES/`). Run
`reuse lint` to verify any path's exact licence.

- **Code**, [AGPL-3.0-or-later](LICENSES/AGPL-3.0-or-later.txt): `pipeline/**`, `Makefile`, `.github/**`. The validation, conversion and reporting toolchain.
- **Database**, [CC-BY-SA-4.0](LICENSES/CC-BY-SA-4.0.txt): `database/**` (including `database/schemas/*.schema.json` and `database/templates/`), generated `export/**` (the RDF export, the CSL bibliography and the Martialis Index). Factual and database content. Share-alike keeps forks and derived datasets open; attribution keeps provenance traceable.
- **Vocabulary**, [CC0-1.0](LICENSES/CC0-1.0.txt) — public domain dedication: `ontology/**` (except the vendored upstream files and generated modules listed below), `model/**` (the LinkML model the ontology is generated from), `schemas/**`. The ontology and JSON-LD context. CC0 allows embedding in other projects, including CC0-only importers (e.g. Wikidata). See [Attribution request](#attribution-request-not-a-license-term).
- **Prose docs**, [CC-BY-SA-4.0](LICENSES/CC-BY-SA-4.0.txt): `README.md`, `CONTRIBUTING.md`, `CITATION.cff`, `llms.txt`, this file, `docs/**`. Documentation. `local-docs/` is gitignored working notes, not published, and out of scope here.
- **Vendored third-party**: the vendored files and generated import modules under `ontology/imports/**`, each under its upstream licence, shared by the module extracted from it: W3C-20150513 (PROV-O, SKOS), PDDL-1.0 (ORG), CC-BY-4.0 (DCMI Terms); BIBO states none, see [LicenseRef-BIBO-unstated](LICENSES/LicenseRef-BIBO-unstated.txt). Unmodified or near-unmodified upstream copies, and the PROV-O, ORG and BIBO import modules `make imports` extracts from them, which the ontology imports. The Martialis licences do not apply to them.

Two directories are named `schemas` and sit in different tiers:
`database/schemas/*.schema.json` are JSON Schemas for *this dataset's* YAML
shape and travel with the data (CC-BY-SA-4.0); `schemas/context.jsonld` is the
JSON-LD vocabulary mapping and travels with the ontology (CC0-1.0).

### Third-party media

Every photograph and video the database references (`image`, `photos`,
`videos`, `logo`) is a `contentUrl` pointing at an external site — Wikimedia
Commons, Internet Archive, a federation's own website — never a file stored in
this repository. None of the tiers above grants a licence to that media:
the Database tier's CC-BY-SA-4.0 covers the *fact* that a record links to a
URL, not the copyright in whatever is at that URL.

Each media item may carry `martialis:mediaRights` (YAML: `rights`), a single
value drawn from the `media-rights` controlled vocabulary
(`ontology/vocabularies.ttl`) recording its own copyright or licence status —
a specific CC licence, a Public Domain Mark, or a rightsstatements.org
statement. The field is optional and not backfilled: absence means the status
has not been evaluated, not that the item is free to use. Check the value (or
its absence), and the linked page itself, before reusing any image or video
found through this database.

## Attribution request (not a license term)

The ontology and JSON-LD context are dedicated to the public domain under
CC0-1.0: no attribution is required to use, embed, or redistribute them. We
nonetheless ask that reusers cite the source:

> Martialis — https://martial.is

## Inbound licensing

Contributions are suggestions made in issues; see
[CONTRIBUTING.md](CONTRIBUTING.md). Code and vocabulary changes are not
accepted from outside the project.

For data (`database/**`), contributions are dedicated to the public domain
under **CC0-1.0** on the way in, covering copyright and any sui generis
database rights the contributor holds in the submission. The grant includes a
representation that the contribution is not copied from a source under
copyright or database-right protection (for example a lineage chart or table
pasted out of a book or paid database). The database is published, on the way
out, under **CC-BY-SA-4.0**; see
[Attribution request](#attribution-request-not-a-license-term) above and the
sui generis right asserted and licensed at the top of this document.

An inbound CC-BY-SA-4.0 grant would bind share-alike onto the maker's own
database and remove the option to relicense it. The term usually has nothing
to grant, because almost every YAML line here is written or transcribed by a
maintainer from a cited source; it exists for a whole researched lineage, a
translation, or a transcription submitted wholesale.

This term is a license grant, not an assignment: under Portuguese law moral
rights are inalienable, so nothing here purports to transfer authorship or
waive them.

## Provenance

All database content, ontology, and code predating this document were written
solely by the project lead (Frederico Muñoz), and the tiers above apply to it
directly, with no relicensing of third-party contributions required.
