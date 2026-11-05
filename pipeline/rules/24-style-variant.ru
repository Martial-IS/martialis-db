# Direct style-variant edges (variant_of only - derived_from/split_from/
# influenced_by/sibling_style_of are deliberately NOT materialized this
# way, since they don't carry "same practitioner pool" semantics and
# must stay invisible to variantOf/hasVariant property-path queries).
# A doubtful or refuted claim gives no edge (see 20-teacher-edges.ru).
# martialis:styleRelationType's value is a concept IRI
# (stylerel:variant_of), not a literal "variant_of" string - get this
# wrong and the pattern stops matching with no error.
PREFIX martialis: <https://w3id.org/martialis/ontology#>
PREFIX conflevel: <https://w3id.org/martialis/vocab/confidence-level/>
PREFIX stylerel: <https://w3id.org/martialis/vocab/style-relation/>
INSERT { ?style martialis:variantOf ?parent .
         ?parent martialis:hasVariant ?style }
WHERE  { ?style martialis:hasStyleRelationAssertion ?a .
         ?a martialis:relatedStyle ?parent ;
            martialis:styleRelationType stylerel:variant_of .
         FILTER NOT EXISTS { VALUES ?lvl { conflevel:doubtful conflevel:refuted }
                            ?a martialis:hasConfidence/martialis:confidenceLevel ?lvl } }
