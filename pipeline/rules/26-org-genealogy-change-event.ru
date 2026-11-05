# Organizational genealogy: materialize org:ChangeEvent nodes (W3C
# Organization Ontology) from AffiliationAssertions carrying a
# genealogy relation (derived_from/split_from/merged_from/replaces/
# renamed_from), and attach the year where one is sourced.
#
# Grouped by (successor, relation, year) via a skolemized IRI, so that
# several merged_from entries on the SAME successor for the SAME merger
# (one per constituent) collapse onto one event with multiple
# org:originalOrganization values - the only way to represent "these
# bodies merged jointly" rather than several unrelated pairwise claims.
# A missing period buckets under "unknown" rather than being dropped:
# the event and its edges still matter even when the year isn't sourced
# yet (see the quality-tier warning for this case). A doubtful or refuted
# claim gives no event (see 20-teacher-edges.ru).
#
# martialis:affiliationRelation's value is a concept IRI, not a
# literal; `martialis:changeKind ?rel` inherits it directly, no
# separate mapping needed. The skolem IRI construction below DOES need
# care: CONCAT'ing the full concept IRI into the change-event's own IRI
# would embed a URI raw inside another URI, and would change every
# org:ChangeEvent's identity - STRAFTER extracts just the notation
# (branch_of, derived_from, ...) instead, keeping identities stable.
#
# The two INSERTs are deliberately kept as separate operations in one
# file: the second attaches martialis:changeYear only where a startYear
# is actually bound, so the "unknown" bucket never gets a malformed
# xsd:integer literal (SPARQL UPDATE cannot conditionally skip a BIND'd
# literal type inline). They recompute the same skolem IRI, so the order
# between them does not matter.
PREFIX martialis: <https://w3id.org/martialis/ontology#>
PREFIX conflevel: <https://w3id.org/martialis/vocab/confidence-level/>
PREFIX org: <http://www.w3.org/ns/org#>
PREFIX affrel: <https://w3id.org/martialis/vocab/affiliation-relation/>
INSERT { ?change a org:ChangeEvent ;
                 org:originalOrganization ?old ;
                 org:resultingOrganization ?new ;
                 martialis:changeKind ?rel .
         ?new org:resultedFrom ?change .
         ?old org:changedBy ?change }
WHERE  { ?new a martialis:Organization ;
              martialis:hasAffiliationAssertion ?a .
         ?a martialis:relatedOrganization ?old ;
            martialis:affiliationRelation ?rel .
         FILTER (?rel IN (affrel:derived_from, affrel:split_from, affrel:merged_from,
                          affrel:replaces, affrel:renamed_from))
         FILTER NOT EXISTS { VALUES ?lvl { conflevel:doubtful conflevel:refuted }
                            ?a martialis:hasConfidence/martialis:confidenceLevel ?lvl }
         OPTIONAL { ?a martialis:validDuring/martialis:startYear ?y }
         BIND(COALESCE(STR(?y), "unknown") AS ?ys)
         BIND(STRAFTER(STR(?rel), STR(affrel:)) AS ?relNotation)
         BIND(IRI(CONCAT("https://martial.is/change/",
                         STRAFTER(STR(?new), "https://martial.is/entity/"),
                         "-", ?relNotation, "-", ?ys)) AS ?change)
} ;
INSERT { ?change martialis:changeYear ?y }
WHERE  { ?new a martialis:Organization ;
              martialis:hasAffiliationAssertion ?a .
         ?a martialis:relatedOrganization ?old ;
            martialis:affiliationRelation ?rel ;
            martialis:validDuring/martialis:startYear ?y .
         FILTER NOT EXISTS { VALUES ?lvl { conflevel:doubtful conflevel:refuted }
                            ?a martialis:hasConfidence/martialis:confidenceLevel ?lvl }
         FILTER (?rel IN (affrel:derived_from, affrel:split_from, affrel:merged_from,
                          affrel:replaces, affrel:renamed_from))
         BIND(STRAFTER(STR(?rel), STR(affrel:)) AS ?relNotation)
         BIND(IRI(CONCAT("https://martial.is/change/",
                         STRAFTER(STR(?new), "https://martial.is/entity/"),
                         "-", ?relNotation, "-", STR(?y))) AS ?change)
}
