# Materialize a descriptive "recorded as having taught here" edge from
# named teacher interactions, so consumers don't have to hand-duplicate
# it as an InstructorRole entry. Deliberately not a staffing claim - see
# martialis:taughtAt's ontology comment. Doubtful and refuted claims are
# excluded (see 20-teacher-edges.ru).
PREFIX martialis: <https://w3id.org/martialis/ontology#>
PREFIX conflevel: <https://w3id.org/martialis/vocab/confidence-level/>
INSERT { ?teacher martialis:taughtAt ?place }
WHERE  { ?student martialis:hasTeacherAssertion ?a .
         ?a martialis:teacher ?teacher ;
            martialis:hasInteraction ?i .
         ?i martialis:interactionPlace ?place .
         FILTER NOT EXISTS { VALUES ?lvl { conflevel:doubtful conflevel:refuted }
                            ?a martialis:hasConfidence/martialis:confidenceLevel ?lvl } }
