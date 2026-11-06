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
- Copyright also protects the database's own prose, such as descriptions and
  confidence rationales. Section 3(a) applies when you share that prose, even
  from one record.
- If you include all or a substantial part in a database of your own in which
  you hold database rights, that database is Adapted Material, but its
  individual contents are not (Section 4(b)). If you share that database, the
  ShareAlike conditions in Section 3(b) apply.
- For content the maker owns, a use the licence does not permit, and no exception
  covers, needs a separate licence from the maker.

The database's ULID identifiers, confidence-assessment wording, and record
ordering identify this database's own content.

A notice only works if it reaches the person extracting the data, not just a
visitor to this repository. That is why a short notice travels with the data: it
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

## Attributing the database

Attribution is a condition of CC-BY-SA-4.0, not a courtesy. This section explains
how the maker applies Section 3(a). It adds no term to the licence.

The condition applies when you share all or a substantial part of the database,
or its own prose. For a smaller reuse, such as a single fact, no licence condition
applies, but the maker asks for the same credit.

Section 3(a) lets you meet the condition in any reasonable manner based on the
medium, means and context. This is the manner the maker requests. Keep with the
content what is supplied with it:

- the credit: Martialis, the name the maker designates for attribution
- the URI of each record you use: `https://martial.is/entity/<ULID>`
- the licence: CC BY-SA 4.0, with a link to it
- a statement that you changed the content, if you did

The requested form is:

> Kanō Jigorō, Martialis (https://martial.is/entity/01KJJAWN28MWKKSN4J02MVY1S1), CC BY-SA 4.0

Where the medium allows links, link the licence name to
https://creativecommons.org/licenses/by-sa/4.0/. A longer credit can add the title
and the maker, and still carries the URI:

> Kanō Jigorō, Martialis: Martial Arts Lineage Database, Frederico Muñoz (ORCID
> 0009-0000-9488-3542), https://martial.is/entity/01KJJAWN28MWKKSN4J02MVY1S1 - CC BY-SA 4.0

Show the credit with the content, on the same page or screen. If you redistribute
records as data, keep each record's URI in the data, with the licence notice.
Every record carries its ULID, which gives its URI, so software that displays a
record can link to it: the maker considers this reasonably practicable. If you
follow this section, the maker considers your attribution sufficient for the
maker's own rights. A link to the home page alone, or one general credit, does not
carry the URI of each record.

To refer to the database itself, without reusing its records, use
https://martial.is in place of the record's URI.

Citing a release in academic work is a separate practice: use its version DOI.
For content the maker owns, contact the maker for terms this licence does not give.

## Text and data mining

Art. 4 of [Directive (EU) 2019/790](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32019L0790)
gives a text and data mining exception, unless the rightsholder expressly reserves
the right in an appropriate manner, such as machine-readable means for content
made publicly available online. Where an exception applies, the CC-BY-SA-4.0 conditions do not (Section
2(a)(2)).

**The maker reserves its own Art. 4 right over the Database tier, in every copy:**
martial.is, this repository, the Zenodo deposits, and any other copy. martial.is
signals the reservation in machine-readable form, through the `tdm-reservation`
HTTP header and `/.well-known/tdmrep.json`
([W3C TDMRep](https://www.w3.org/community/reports/tdmrep/)).

The reservation restricts nobody who complies with CC-BY-SA-4.0: attribute the
source, share derivatives under the same terms, and mining is unaffected. It
removes only the statutory route around those conditions.

- **Research use is unaffected.** Art. 3 gives research organisations and cultural
  heritage institutions an exception that a rightsholder cannot override.
- **The Vocabulary tier is not reserved.** It is CC0-1.0.

For content the maker owns, if you mine the Database tier outside the CC-BY-SA-4.0
terms, contact the maker.

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

### Third-party quotations

Every `quotation` is a short verbatim extract from the Source it cites, given as
evidence for one claim. Its copyright stays with its author or publisher. None
of the tiers above grants a licence to it: the Database tier's CC-BY-SA-4.0
covers the claims, the citations, and the selection and arrangement of the
database, not the quoted words.

The extracts are used under the quotation exception (Directive 2001/29/EC
Art. 5(3)(d), in Portugal Arts. 75(2)(h) and 76(1)(a) of the Código do Direito
de Autor e dos Direitos Conexos). Each one is limited to what its claim needs and
names its Source. One Source can be quoted many times, because it supports claims
about many people; each quotation still stands on its own claim.

If you reuse the database, keep each quotation with its citation, and check that
the same exception covers your own use. `martialis:quotation` can be removed
from the export without affecting anything else.

A rightsholder who objects to a quotation can say so through the
[issue tracker](https://github.com/Martial-IS/martialis-db/issues) or by email
to the maker. Each request is assessed. If a quotation is removed, the claim and
its citation stay. Removal applies to the current database and every release from
that point forward. It does not alter git history already published or prior
releases already distributed.

### Text from Wikipedia

Some `description` text is copied, adapted or translated from Wikipedia, in
several language editions, under CC BY-SA. It may have been edited. The record's
evidence links the article, and its history page lists the authors. This text
stays with those authors: the maker cannot license it on other terms. If you share
this text, keep that link.

## Attribution request (not a license term)

The ontology and JSON-LD context are dedicated to the public domain under
CC0-1.0: no attribution is required to use, embed, or redistribute them. We
nonetheless ask that reusers cite the source:

> Martialis — https://martial.is

## Inbound licensing

Contributions are suggestions made in Discussions, in issues, or through the
suggestion form on martial.is; see [CONTRIBUTING.md](CONTRIBUTING.md). Code and
vocabulary changes are not accepted from outside the project.

For data (`database/**`), contributions are dedicated to the public domain
under **CC0-1.0** on the way in, covering copyright and any sui generis
database rights the contributor holds in the submission. The grant includes a
representation that the contribution is not copied from a source under
copyright or database-right protection (for example a lineage chart or table
pasted out of a book or paid database). Short quotations given as evidence are
outside the dedication; see [Third-party quotations](#third-party-quotations).
The database is published, on the way out, under **CC-BY-SA-4.0**; see
[Attributing the database](#attributing-the-database) above and the sui generis
right asserted and licensed at the top of this document.

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
solely by the project lead (Frederico Muñoz), except the quotations, media and
Wikipedia text described above. The tiers above apply to it directly, with no
relicensing of third-party contributions required.
