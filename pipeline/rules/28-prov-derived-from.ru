# Materialize standard PROV-O edges alongside the native evidence
# model, so a generic PROV consumer gets something without having to
# understand martialis:hasEvidence/basedOnSource/assessedBy. This is
# documentation-grade, not a replacement: prov:wasDerivedFrom only
# covers the boolean "supports" direction (a claim is not sensibly
# "derived from" a source that contradicts it - that source is still
# recorded via hasEvidence, just not restated here), and neither triple
# carries the evidence-type/locator/quotation detail that
# SourceAssertionRelation does.
#
# Only claim and fact nodes get the edge: assertions, interactions, life
# events, roles, participations and sites, which the ontology makes
# prov:Entity. A Person, Organization, Place, Style, Event or RankingSystem
# IRI names the thing itself, not a record of it, and PROV's domain for
# wasDerivedFrom (prov:Entity) would otherwise say that the person, the place
# or the art was derived from a book. Their own top-level evidence stays in
# martialis:hasEvidence.
PREFIX martialis: <https://w3id.org/martialis/ontology#>
PREFIX prov: <http://www.w3.org/ns/prov#>
INSERT { ?entity prov:wasDerivedFrom ?source }
WHERE  { ?entity martialis:hasEvidence ?ev .
         ?ev martialis:basedOnSource ?source ;
             martialis:supports true .
         MINUS {
             VALUES ?described { martialis:Person martialis:Organization martialis:Place
                                 martialis:Style martialis:Event martialis:RankingSystem }
             ?entity a ?described
         } }
