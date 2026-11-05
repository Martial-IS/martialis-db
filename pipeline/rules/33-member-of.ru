# Direct person/organization membership edges. Not time-bound, like the
# teacher edges: memberOf says the person was a member at some time, and the
# Membership carries the period. A doubtful or refuted claim gives no edge
# (see 20-teacher-edges.ru).
PREFIX martialis: <https://w3id.org/martialis/ontology#>
PREFIX conflevel: <https://w3id.org/martialis/vocab/confidence-level/>
INSERT { ?person martialis:memberOf ?org .
         ?org martialis:hasMember ?person }
WHERE  { ?org martialis:hasMembership ?m .
         ?m martialis:member ?person .
         FILTER NOT EXISTS { VALUES ?lvl { conflevel:doubtful conflevel:refuted }
                            ?m martialis:hasConfidence/martialis:confidenceLevel ?lvl } }
