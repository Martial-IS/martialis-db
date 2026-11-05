# Materialize direct teacher/student edges so consumers of data.ttl
# get them without a reasoner. A claim assessed doubtful (its evidence
# does not substantiate it) or refuted gives no edge: a shortcut
# carries no confidence, so it would restate the claim as fact.
PREFIX martialis: <https://w3id.org/martialis/ontology#>
PREFIX conflevel: <https://w3id.org/martialis/vocab/confidence-level/>
INSERT { ?student martialis:wasTaughtBy ?teacher .
         ?teacher martialis:teaches ?student }
WHERE  { ?student martialis:hasTeacherAssertion ?a .
         ?a martialis:teacher ?teacher .
         FILTER NOT EXISTS { VALUES ?lvl { conflevel:doubtful conflevel:refuted }
                            ?a martialis:hasConfidence/martialis:confidenceLevel ?lvl } }
