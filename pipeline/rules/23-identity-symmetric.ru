# Candidate-identity edges are materialized symmetrically, except from a
# doubtful or refuted claim (see 20-teacher-edges.ru).
PREFIX martialis: <https://w3id.org/martialis/ontology#>
PREFIX conflevel: <https://w3id.org/martialis/vocab/confidence-level/>
INSERT { ?p martialis:possiblySameAs ?candidate .
         ?candidate martialis:possiblySameAs ?p }
WHERE  { ?p martialis:hasIdentityAssertion ?a .
         ?a martialis:identityCandidate ?candidate .
         FILTER NOT EXISTS { VALUES ?lvl { conflevel:doubtful conflevel:refuted }
                            ?a martialis:hasConfidence/martialis:confidenceLevel ?lvl } }
