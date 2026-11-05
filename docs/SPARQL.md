# Querying Martialis

The database is published as RDF/Turtle. The export lives at `export/data.ttl` and is served from
https://martial.is/data.ttl. You can also query it through the SPARQL endpoint, load the file into
Fuseki or Oxigraph, or query the local file with the bundled Jena:

```
tools/jena/bin/sparql --data=export/data.ttl \
  --data=ontology/martialis.ttl --data=ontology/vocabularies.ttl \
  --query=query.rq --results=text
```

## Prefixes

These are used throughout and are published in most places (LOV, prefix.cc):
```sparql
PREFIX martialis: <https://w3id.org/martialis/ontology#>
PREFIX schema: <https://schema.org/>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX org: <http://www.w3.org/ns/org#>
```

`martialis:` and `schema:` are needed by nearly every query. A query that filters on an enum value
adds the prefix of that value's scheme: `stylerel:`
`<https://w3id.org/martialis/vocab/style-relation/>`, `affrel:`
`<https://w3id.org/martialis/vocab/affiliation-relation/>`, `conflevel:`
`<https://w3id.org/martialis/vocab/confidence-level/>`. Those IRIs are also written out in full in
`ontology/vocabularies.ttl`.

## First things to know

- A query is `SELECT ?var WHERE { ?s ?p ?o }`. `a` is short for `rdf:type`. Add `LIMIT n` while
  exploring.
- Entities are IRIs of the form `https://martial.is/entity/<ULID>`, and so is a claim (an assertion
  or a participation), whose stable IRI is its own ULID; its record is the one that holds it
  (`?record martialis:hasTeacherAssertion ?claim`). Other nested structures (birth and death events,
  interactions, confidence, evidence, officer and instructor role nodes) are named sub-resources of
  their parent, `<…/<slot>[/<index>]>`; reach them through the property that links them, or address
  one directly by its IRI.
- Names are language-tagged literals, such as `"Kanō Jigorō"@ja-Latn`. An exact lookup must match
  the stored tag; `FILTER(CONTAINS(LCASE(STR(?name)), "kanō"))` searches every language instead.
  `schema:name` on a `martialis:Source` is a plain string with no language tag.
- Compare language tags with `langMatches(LANG(?x), "ja-Latn")`. Engines differ on the case of
  `LANG()` output and `=` is case-sensitive.
- Dates on life events, ranks, honors, founding and dissolution, and a Source's
  `schema:datePublished` are EDTF strings: `"1935"`, `"1935~"`, `"193X"`, `"1938/1941"`,
  `"[1899,1900]"`. They are `xsd:string`, so `xsd:integer(STR(?date))` works only on a bare year.
  Every node with such a date also carries `martialis:earliestYear` and `martialis:latestYear` as
  `xsd:integer`, which is what sorting and chronological comparison use. The `start`/`end` years of
  a period are plain `xsd:integer` already.
- A birth or death is an event node: `?person martialis:birthEvent/schema:startDate ?date` and
  `martialis:birthEvent/schema:location ?place`. When the date is plain ISO 8601 the export also
  states `schema:birthDate` (and `deathDate`, `birthPlace`, `deathPlace`) on the person, and
  `schema:foundingDate` and `dissolutionDate` on an organization. A rank's or honor's date is
  `martialis:dateConferred`.
- `?x a martialis:Assertion` matches nothing. Assertions carry concrete types such as
  `martialis:TeacherAssertion`, and no reasoner runs. To reach any assertion, follow the containment
  property from its subject: `?subject ?assertion ?x`, or match the concrete type it carries.
- The export materializes shortcut edges such as `martialis:wasTaughtBy` and `martialis:teaches`
  (person to person), `martialis:taughtAt` (person to place), `martialis:variantOf` and
  `martialis:hasVariant` (style), and `martialis:parentOrg` (organization), `martialis:memberOf` and
  `martialis:hasMember` (person and organization); each property's definition in the ontology says
  what it is built from. These edges carry no evidence and no confidence: each is built from every
  claim not assessed `doubtful` or `refuted` (`possible`, `probable` or `confirmed`), so an edge is
  not a statement of established fact. The reified assertion behind an edge carries the style,
  period, place, confidence and evidence.
- Confidence "hangs" off an assertion as `martialis:hasConfidence` to a `martialis:Confidence` node
  carrying `martialis:confidenceLevel`, a concept from `conflevel:refuted` to `conflevel:confirmed`,
  ordered by its `martialis:gradeOrdinal` in `ontology/vocabularies.ttl`. Evidence hangs off
  `martialis:hasEvidence` to a `martialis:SourceAssertionRelation` node carrying
  `martialis:basedOnSource`, `martialis:supports`, `martialis:informationType`,
  `martialis:evidenceType` and `martialis:quotation`. A supporting Source is also reachable as
  `prov:wasDerivedFrom`. Teacher evidence hangs off the assertion's interaction node:
  `martialis:hasInteraction` then `martialis:hasEvidence`.
- Enum-valued properties hold SKOS concept IRIs from `ontology/vocabularies.ttl`, not string
  literals. A style relation is `martialis:styleRelationType stylerel:derived_from`.

## Example

The teachers of a person, with the confidence recorded for each claim.

```sparql
PREFIX martialis: <https://w3id.org/martialis/ontology#>
PREFIX schema: <https://schema.org/>

SELECT ?teacherName ?level WHERE {
  ?person schema:name "Kanō Jigorō"@ja-Latn ;
          martialis:hasTeacherAssertion ?ta .
  ?ta martialis:teacher ?teacher ;
      martialis:hasConfidence ?confidence .
  ?confidence martialis:confidenceLevel ?level .
  ?teacher schema:name ?teacherName .
  FILTER(langMatches(LANG(?teacherName), "ja-Latn"))
}
ORDER BY ?teacherName
```

Each row is a teacher's name and a confidence concept, such as
`conflevel:probable`.

## More queries

- `pipeline/reports/examples/` holds runnable queries, one construct per
  file (lineage chains, ranks, style relations, evidence and confidence, and
  more). Run any of them with the command above.
- The rest of `pipeline/reports/` holds the report queries.
- `ontology/martialis.ttl` declares every `martialis:` property.
  `ontology/vocabularies.ttl` lists the values of every enum.
