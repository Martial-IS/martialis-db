# The student-side mirror of taughtAt: this person is recorded as having
# trained at this place, from any teacher interaction, whether or not the
# teacher is identified. Doubtful and refuted claims are excluded
# (see 20-teacher-edges.ru).
PREFIX martialis: <https://w3id.org/martialis/ontology#>
PREFIX conflevel: <https://w3id.org/martialis/vocab/confidence-level/>
INSERT { ?student martialis:trainedAt ?place }
WHERE  { ?student martialis:hasTeacherAssertion ?a .
         ?a martialis:hasInteraction ?i .
         ?i martialis:interactionPlace ?place .
         FILTER NOT EXISTS { VALUES ?lvl { conflevel:doubtful conflevel:refuted }
                            ?a martialis:hasConfidence/martialis:confidenceLevel ?lvl } }
