# Direct org-hierarchy edge (branch_of only). Only current branch_of affiliations materialize: the
# endYear guard means a lapsed hierarchy (the branch left, or the
# parent body dissolved) never surfaces as a present-tense parentOrg.
# The two dissolvedEvent guards cover what the endYear guard cannot see:
# either body is defunct (a committee constituted for a term and dissolved,
# a parent federation wound up) while the affiliation period was never
# given an end, so an unguarded rule would emit a present-tense parentOrg
# involving a body that no longer exists. Either side ending means "not
# current". A doubtful or refuted claim gives no edge (see 20-teacher-edges.ru).
# Guarded to Organization subjects only: a Place with a branch_of
# affiliation (e.g. a venue that IS an org's own headquarters) must
# NOT get a parentOrg triple - that property's declared domain is
# martialis:Organization, and a stray Place-subject triple would
# violate it silently (no existing SHACL shape catches it, since
# OrganizationShape only targets Organizations and PlaceShape has no
# parentOrg shape at all).
# Same concept-IRI caution as the variant_of pass above:
# martialis:affiliationRelation's value is affrel:branch_of, a
# concept IRI, not a literal.
PREFIX martialis: <https://w3id.org/martialis/ontology#>
PREFIX conflevel: <https://w3id.org/martialis/vocab/confidence-level/>
PREFIX affrel: <https://w3id.org/martialis/vocab/affiliation-relation/>
INSERT { ?org martialis:parentOrg ?parent }
WHERE  { ?org a martialis:Organization ;
              martialis:hasAffiliationAssertion ?a .
         ?a martialis:relatedOrganization ?parent ;
            martialis:affiliationRelation affrel:branch_of .
         FILTER NOT EXISTS { ?a martialis:validDuring/martialis:endYear ?e }
         FILTER NOT EXISTS { ?org martialis:dissolvedEvent ?d }
         FILTER NOT EXISTS { ?parent martialis:dissolvedEvent ?pd }
         FILTER NOT EXISTS { VALUES ?lvl { conflevel:doubtful conflevel:refuted }
                            ?a martialis:hasConfidence/martialis:confidenceLevel ?lvl }
}
