# Martialis

[![Validate database](https://github.com/Martial-IS/martialis-db/actions/workflows/validate.yml/badge.svg)](https://github.com/Martial-IS/martialis-db/actions/workflows/validate.yml)
[![REUSE status](https://api.reuse.software/badge/github.com/Martial-IS/martialis-db)](https://api.reuse.software/info/github.com/Martial-IS/martialis-db)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23346621.svg)](https://doi.org/10.5281/zenodo.23346621)
[![Software Heritage](https://archive.softwareheritage.org/badge/origin/https://github.com/Martial-IS/martialis-db/)](https://archive.softwareheritage.org/browse/origin/?origin_url=https://github.com/Martial-IS/martialis-db)
![Ontology](https://img.shields.io/badge/ontology-1.0.0-informational)
![Code license](https://img.shields.io/badge/code-AGPL--3.0--or--later-blue)
![Data license](https://img.shields.io/badge/data-CC--BY--SA--4.0-lightgrey)
![Vocabulary license](https://img.shields.io/badge/vocabulary-CC0--1.0-lightgrey)

Martialis is a curated database of martial arts lineages, or better yet, of _martial knowledge
transmission_: who learned what from whom, and how styles, organizations, and places relate to those
transmission events.

One fundamental aspect of Martialis is that every claim is a sourced, confidence-graded assertion,
so the tree is transparent to scrutiny, and the published RDF is open and verifiable on its own.

The result of this work is the basis for the [Martialis interactive explorer](https://martial.is/),
which offers a rich graph-based interface on top of the martialis-db data.

## The importance of openness, transparency, durability.

> (...) called "the inherited conglomerate". The geological metaphor is apt, for religious growth is
> geological: its principle is, on the whole and with exceptions, agglomeration, not substitution.
>
> -- E. R. Dodds, The Greeks and the Irrational

This project is in some ways a reflection of my background in martial arts, IT, and archaeology,
each contributing a different set of concerns and solutions. If the idea of building something that
is well-sourced and open to criticism comes from a background in History, the concern (and
implemented solutions) for the longevity of the information is a direct result of direct involvement
in not only the free software movement, but in observing how digital content went through different
periods: from the initial openness of the Internet, the continued existence of isolated islands, and
the ongoing _digital decay_, there are very concrete challenges about creating something that
endures.

The example of JudoForum.com is particularly important (and traumatic): what had become a repository
of (sometimes unique) knowledge, disappeared without a trace, most of that knowledge lost.

**Martialis was created from scratch to avoid this**: all technical decisions were made with that
goal in mind, from the YAML format, to the extensive usage of W3C's Semantic Web approaches, and
including the sharing and archiving of the project (Zenodo, Software Heritage, etc).


## What Martialis covers: the scope and the model

Martialis models the transmission of martial knowledge: who learned from whom, where, when, in which
style, and on what evidence. _Persons_ are the core of the lineage graph, and that was how it
started, but Styles, Organizations, Places, Events, Ranking Systems and Sources were added as the
need to better express the richness of those relationships emerged.

The model is documented at the [Martialis Model documentation](https://martial.is/model) (and the
Ontology specifically at https://w3id.org/martialis/ontology), so any attempt to describe it here is
not only redundant, but would easily lag behind changes. That said, the following concepts are
important to briefly describe:

- **Teacher and student.** The central claim is that a person taught the subject a style, documented
  by its interactions: a place, a period, a course, or seminar. The kind of relationship is recorded
  (student, uchi-deshi, coach, private lessons, seminar, examination, etc).
- **Transmission from documents.** This models learning from study of a text or recording with no
  living teacher behind it (a densho, a manual, a DVD).
- **Rank is separate from teaching.** Learning from someone is different from receiving rank from
  someone: ranks, honors and titles are separate claims, tied to the style, the ranking system and
  the body (and/or person) that conferred them, which are often not the same as the ones that acted
  as teachers.
- **Styles and how they relate.** A style can be a variant of another, derived from it, split from
  it, influenced by it, or a sibling of it, or a composite system relates to each of its component
  arts on its own terms: just like we model knowledge transmission between individuals, we also
  model how martial arts disciplines relate to each other.
- **Organizations and places.** Federations and governing bodies with their own "genealogy" (splits,
  mergers, renamings...), affiliations, officers and members, plus training establishments with
  their sites over time, and who taught and learned there.
- **Events.** Tournaments, grading events, seminars, courses, demonstrations... an open-ended
  category that allows us to add another dimension (often critical) to knowledge transmission.
- **Uncertain identity and existence.** Two records that may be the same person, and whether a
  person existed as one historical individual or is legendary, a composite figure, etc: the model
  allows for this level of uncertainty.

Martialis records lineage (again, to be understood broadly as a result of some kind of knowledge
transmission) and provenance, with the scope being anything that enables us to describe that as
richly as possible. It does _not_ model pedagogy, curricula, technique taxonomies, or developmental
claims about training, and **it doesn't claim any sort of authority around martial arts grades,
ranks, quality of instructions, efficacy, or anything of the sort**.


## Evidence and confidence

Another thing that influenced the approach was the way evidence was collected and managed in
genealogical investigation, with the involvement in the [Gramps](https://gramps-project.org/)
genealogy research project informing some of the decisions made.

While not the same, there is some useful overlap in the methods used to assess the certainty and
quality of genealogical information, and the one needed for establishing knowledge transmission. One
such method is the Evidence Analysis Process Model of Elizabeth Shown Mills (*[Evidence
Explained](https://www.evidenceexplained.com/)*) and the Genealogical Proof Standard ([Board for
Certification of Genealogists, Genealogy
Standards](https://bcgcertification.org/ethics-standards#genealogical-proof-standard-gps)), an
established standard for lineage research. This method allows us to separate the source, the
information in it, and how that information bears on a claim.

We have integrated these into the model, in an adjusted form, including:

- **Sources are mandatory, not optional.** Every claim cites at least one source, and each citation
  records whether its informant knew the fact first-hand, whether it states the claim or only
  implies it, and whether it supports or contradicts it. This is fundamental to be able to trace
  claims.
- **Quotations are verbatim** and follow standard transcription practice: the source's words, order,
  case and punctuation, with every editorial intervention in square brackets, so a reader can always
  tell the source from the editor.
- **Lineage tradition is not independent corroboration.** Every account from inside one lineage
  shares one origin: a school or federation history, a founding story, a genealogy chart or a
  densho. A claim resting only on such sources is not `confirmed` - and this can be either obvious
  (for distant lineages and more exotic claims), or seem like an excessive take (for recent
  publications that come from official organizations).
- **The assessment is the curator's judgement**, recorded with a rationale on an ordered scale from
  `refuted` to `confirmed`. There are rules, but the curator has some leeway in how to apply them.
- **Contestedness is not a level.** A contested claim carries its counter-evidence in the open (and
  not simply contribute to negatively impact the other claim). A refuted, doubtful or contested
  lineage claim is presented and marked, not removed from the source (but can be removed from the
  generated RDF edge).

Confidence level and the evidence analysis are curator judgments about how well a claim is sourced,
not about a person's skill, legitimacy, or standing: this is fundamental to understand, since it's
impossible for the curator to have complete and intimate knowledge of every entry in the database
(and indeed the reason why all the work in the model and quality checks was done is to avoid making
that a requirement).

## How it works

For a user, it's simple: the database is explored in the [Martialis portal](https://martial.is/),
which provides links to the [Discussions](https://github.com/Martial-IS/martialis-db/discussions) on
each entry (if it exists), as well as an option to send updates or feedback. On top of this, users
can add their own connections to the database entries, but this is _outside_ of the curated database
itself.

Here, however, it's wehere that data is collected. YAML records under `database/` are the source of
truth: seven entity types each have a template in `database/templates/`, plus a JSON Schema in
`database/schemas/`: Person, Style, Organization, Place, Source, Event, and Ranking System. Persons
are the core of the lineage graph and where it all started, with the other types initially giving
additional context but growing into first-tier entitites as the model evolved.

The record format is defined once in `model/martialis.yaml`, using [LinkML](https://linkml.io/), and
the JSON-LD context (`schemas/context.jsonld`), the OWL ontology (`ontology/martialis.ttl`), the
structural SHACL shapes and the seven JSON Schemas are generated from it. LinkML was adopted halfway
through the development when the number of things that needed to be kept in sync grew: initially,
YAML-LD with JSON schemas was the base format. LinkML moves this into a single YAML file that is
then used to create the rest.

That creation is not without its peculiarities, and while we tried to keep things as simple as
possible (namely by making use of existing software whenever possible instead of creating something
new), the pipeline includes tools and processes to make things work as expected. `make tools`
downloads the pinned tools once (jq, jv, yq, Apache Jena, ROBOT, lychee), a Java runtime is assumed.
`make validate` is a blocking CI gate, and the quality report is separate (`make quality`). See
[docs/PIPELINE.md](docs/PIPELINE.md) for more information on this.

## W3C, Semantic Web, Vocabularies.

One of the things that was already present in the first incarnation of this project, Budo Tree, was
a concern about integrating into the _semantic web_, initially through support of JSON-LD. For
Martialis, this not only remained an important aspect but was significantly improved.

The ontology targets OWL 2 DL and reuses established vocabularies (schema.org, PROV-O, the W3C
Organization Ontology, BIBO, SKOS). The controlled vocabularies are multilingual SKOS concept
schemes, and entities link to Wikidata and other authority files.

## Data and export

The records are `database/**` (YAML); `make rdf` converts them through a JSON-LD context into
`export/data.ttl`, which carries its own `void:entities` and `void:triples` counts. The bibliography
is `export/sources.csl.json`, and every term lives in the `https://w3id.org/martialis/ontology#`
namespace.

Every release is deposited on Zenodo: the [database](https://doi.org/10.5281/zenodo.23346621) and
the [ontology](https://doi.org/10.5281/zenodo.23951127). These links always resolve to the latest
version. To cite Martialis, use the version DOI of the release you used, shown on its Zenodo page,
because the data changes between releases. [CITATION.cff](CITATION.cff) has the citation metadata.

Martialis publishes on a quarterly tagged-release cadence, not live sync: the working repository
(and `martial.is` itself) can be ahead of the most recent tag, and a release is an immutable,
citable snapshot. The database and the ontology are released separately, each with its own version:
a database release (tag `data-vX.Y.Z`) attaches `export/data.ttl`, and an ontology release (tag
`ontology-vX.Y.Z`) attaches `ontology/martialis.ttl`, `ontology/vocabularies.ttl` and
`schemas/context.jsonld`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to submit a correction and what a good contribution
looks like. The short version:

1. Contributions are done through Discussions, by commenting on existing entries or new ones.
2. Problems with the pipeline or model itself can be reported through Issues
3. Pull requests are not used

IMPORTANT: By submitting content for the database, in a Discussion or an issue, you dedicate it to
the public domain under **CC0-1.0**.

## Licence

Code (`pipeline/**`, the Makefile, `.github/**`) is AGPL-3.0-or-later, data (`database/**` and the
generated `export/**`) is CC-BY-SA-4.0, and the ontology, model and vocabulary (`ontology/**` except
the vendored files under `ontology/imports/`, `model/**`, `schemas/**`) are CC0-1.0. The vendored
upstream files keep their own licences. Quotations from sources and linked media stay with their
rightsholders and are not covered by these licences. See [LICENSING.md](LICENSING.md).

The maker asserts the EU sui generis database right (Directive 96/9/EC Art. 7, transposed in
Portugal by DL 122/2000) and licenses it under CC-BY-SA-4.0. See
[LICENSING.md](LICENSING.md#sui-generis-database-right) for the full notice, including how personal
data of the living people the database records is handled.

Attribution is a condition of the data licence: if you share database content, credit Martialis and
link to each record you use. See [Attributing the database](LICENSING.md#attributing-the-database).
The maker also reserves the text and data mining right under Art. 4 of Directive (EU) 2019/790 over
the data. See [Text and data mining](LICENSING.md#text-and-data-mining).

Maker of the database: Frederico Muñoz, Lisbon, Portugal. Martialis™ is an unregistered trademark of
Frederico Muñoz.
