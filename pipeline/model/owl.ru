# The LinkML OWL emitter output (default graph), the vocabulary, the overlay and the import modules (named graphs)
# -> the Martialis ontology.
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX linkml: <https://w3id.org/linkml/>
PREFIX martialis: <https://w3id.org/martialis/ontology#>
PREFIX x: <urn:x-tmp:>

# The scheme of every concept-valued property, from its enum's values.
INSERT { ?prop martialis:conceptScheme ?scheme }
WHERE  { { ?prop rdfs:range ?e } UNION { ?r owl:onProperty ?prop ; owl:allValuesFrom ?e }
         ?e linkml:permissible_values ?pv .
         GRAPH ?vg { ?pv skos:inScheme ?scheme } } ;

# A slot pattern is a shape constraint: keep the base datatype.
DELETE { ?s ?p ?b } INSERT { ?s ?p ?base }
WHERE  { ?s ?p ?b . ?b owl:intersectionOf ?l .
         ?l rdf:rest*/rdf:first ?base FILTER isIRI(?base)
         FILTER NOT EXISTS { ?l rdf:rest*/rdf:first ?m FILTER (isBlank(?m) && NOT EXISTS { ?m owl:onDatatype [] }) } } ;
DELETE { ?s ?p ?o } INSERT { ?s ?p ?base }
WHERE  { VALUES ?p { rdfs:range owl:allValuesFrom owl:someValuesFrom } ?s ?p ?o . ?o owl:onDatatype ?base FILTER isBlank(?o) } ;

# An IRI-valued slot is an object property with a datatype filler: remember it.
INSERT { x:iri x:p ?p }
WHERE  { ?p a owl:ObjectProperty . ?r owl:onProperty ?p ; owl:allValuesFrom ?d FILTER STRSTARTS(STR(?d), STR(xsd:))
         FILTER NOT EXISTS { [] owl:onProperty ?p ; owl:allValuesFrom martialis:LanguageMap } } ;

# Enums: a literal enum (martialis: namespace) is a string, a concept enum skos:Concept.
DELETE { ?prop a owl:ObjectProperty } INSERT { ?prop a owl:DatatypeProperty }
WHERE  { { ?prop rdfs:range ?e } UNION { ?r owl:onProperty ?prop ; owl:allValuesFrom|owl:someValuesFrom ?e }
         ?e linkml:permissible_values [] FILTER STRSTARTS(STR(?e), STR(martialis:)) } ;
DELETE { ?s ?p ?e } INSERT { ?s ?p ?t }
WHERE  { VALUES ?p { rdfs:range owl:allValuesFrom owl:someValuesFrom } ?s ?p ?e . ?e linkml:permissible_values []
         BIND (IF(STRSTARTS(STR(?e), STR(martialis:)), xsd:string, skos:Concept) AS ?t) } ;
DELETE { ?n ?p ?o } WHERE { { ?n linkml:permissible_values [] } UNION { [] linkml:permissible_values ?n } ?n ?p ?o } ;

# Bookkeeping: self matches, the model's scheme, designators, LinkML terms.
DELETE WHERE { ?s skos:exactMatch ?s } ;
DELETE WHERE { ?s skos:inScheme ?o } ;
DELETE { ?c ?q ?r . ?r ?p ?o } WHERE { VALUES ?d { martialis:type martialis:id } ?r owl:onProperty ?d ; ?p ?o . OPTIONAL { ?c ?q ?r } } ;
DELETE { ?d ?p ?o } WHERE { VALUES ?d { martialis:type martialis:id } ?d ?p ?o } ;

# A language map is one literal per language: "exactly n" becomes "at least n",
# "at most one" goes, and so does the restriction to the map itself.
INSERT { x:langmap x:p ?p } WHERE { ?r owl:allValuesFrom martialis:LanguageMap ; owl:onProperty ?p } ;
DELETE { ?x owl:cardinality ?n } INSERT { ?x owl:minCardinality ?n }
WHERE  { ?c rdfs:subClassOf [ owl:onProperty ?p ; owl:allValuesFrom martialis:LanguageMap ], ?x .
         ?x owl:onProperty ?p ; owl:cardinality ?n } ;
DELETE { ?c rdfs:subClassOf ?x . ?x ?q ?v }
WHERE  { ?c rdfs:subClassOf [ owl:onProperty ?p ; owl:allValuesFrom martialis:LanguageMap ], ?x .
         ?x owl:onProperty ?p ; owl:maxCardinality [] ; ?q ?v } ;
DELETE { ?c ?q ?r . ?r ?p ?o } WHERE { ?r owl:allValuesFrom martialis:LanguageMap ; ?p ?o . OPTIONAL { ?c ?q ?r } } ;
DELETE WHERE { ?s ?p martialis:LanguageMap } ;
DELETE WHERE { martialis:LanguageMap ?p ?o } ;

# An IRI-valued property's datatype filler puns it; the declaration says it all.
DELETE { ?c ?q ?r . ?r ?p ?o }
WHERE  { ?r owl:onProperty ?prop ; owl:allValuesFrom ?d ; ?p ?o . x:iri x:p ?prop
         FILTER (STRSTARTS(STR(?d), STR(xsd:)) || EXISTS { ?d a rdfs:Datatype }) OPTIONAL { ?c ?q ?r } } ;

# Assert nothing about terms the ontology does not own, nor the emitter's header.
DELETE { ?s ?p ?o }
WHERE  { ?s ?p ?o FILTER (isIRI(?s) && REGEX(STR(?s), "^(http://www.w3.org/ns/prov#|https?://schema.org/|http://www.w3.org/ns/org#|http://purl.org/ontology/bibo/|http://purl.org/spar/(fabio|cito)/|http://purl.org/dc/terms/|http://xmlns.com/foaf/0.1/|http://www.w3.org/2004/02/skos/core#|http://purl.org/vocab/vann/)")) } ;
DELETE { ?s ?p ?o } WHERE { ?s a owl:Ontology ; ?p ?o } ;
DELETE { ?s ?p ?o } WHERE { ?s ?p ?o FILTER STRSTARTS(STR(?p), STR(linkml:)) } ;

# Declare every restricted property with the one role its use implies
# (owl-check.rq fails on a property that would need two).
INSERT { ?p a owl:ObjectProperty }
WHERE  { x:iri x:p ?p FILTER NOT EXISTS { ?p a owl:ObjectProperty } FILTER NOT EXISTS { ?p a owl:DatatypeProperty } } ;
INSERT { ?p a ?role }
WHERE  { SELECT ?p (IF(MIN(?dt), owl:DatatypeProperty, owl:ObjectProperty) AS ?role)
         WHERE { ?r owl:onProperty ?p ; owl:allValuesFrom|owl:someValuesFrom|owl:onClass|owl:onDataRange ?f
                 FILTER NOT EXISTS { ?p a owl:ObjectProperty } FILTER NOT EXISTS { ?p a owl:DatatypeProperty }
                 BIND (STRSTARTS(STR(?f), STR(xsd:)) || EXISTS { ?f a rdfs:Datatype } AS ?dt) } GROUP BY ?p } ;
INSERT { ?p a ?role }
WHERE  { SELECT ?p (IF(MIN(?dt), owl:DatatypeProperty, owl:ObjectProperty) AS ?role)
         WHERE { [] owl:onProperty ?p . ?p rdfs:range ?f
                 FILTER NOT EXISTS { ?p a owl:ObjectProperty } FILTER NOT EXISTS { ?p a owl:DatatypeProperty }
                 BIND (STRSTARTS(STR(?f), STR(xsd:)) || EXISTS { ?f a rdfs:Datatype } AS ?dt) } GROUP BY ?p } ;
INSERT { ?p a ?role }
WHERE  { SELECT DISTINCT ?p ?role WHERE { [] owl:onProperty ?p
         FILTER NOT EXISTS { ?p a owl:ObjectProperty } FILTER NOT EXISTS { ?p a owl:DatatypeProperty }
         BIND (IF(EXISTS { [] ?p ?v FILTER (!isLiteral(?v)) }, owl:ObjectProperty, owl:DatatypeProperty) AS ?role) } } ;
INSERT { ?p a owl:DatatypeProperty }
WHERE  { x:langmap x:p ?p FILTER NOT EXISTS { ?p a owl:ObjectProperty } FILTER NOT EXISTS { ?p a owl:DatatypeProperty } } ;

# The emitter's detached list chains and every structure the steps above cut loose.
DELETE { ?b ?p ?o } WHERE { ?b ?p ?o FILTER isBlank(?b) FILTER NOT EXISTS { ?root (!x:none)+ ?b FILTER isIRI(?root) } } ;
DELETE WHERE { x:iri ?p ?o } ;
DELETE WHERE { x:langmap ?p ?o } ;

# The hand-authored overlay, after the pruning above: its disjointness axioms are root blank nodes.
INSERT { ?s ?p ?o } WHERE { GRAPH ?g { ?s ?p ?o } FILTER STRENDS(STR(?g), "ontology-overlay.ttl") } ;

# Declare every imported term the ontology mentions, with the role its import module gives it,
# so the file parses the same with or without its imports.
INSERT { ?t a ?role }
WHERE  { GRAPH ?m { ?t a ?role FILTER (?role IN (owl:Class, owl:ObjectProperty, owl:DatatypeProperty, owl:AnnotationProperty)) }
         FILTER STRENDS(STR(?m), "-module.ttl") FILTER EXISTS { { ?s ?p ?t } UNION { ?t ?p ?o } UNION { ?s ?t ?o } }
         FILTER (!REGEX(STR(?t), "^http://www.w3.org/(1999/02/22-rdf-syntax-ns|2000/01/rdf-schema|2002/07/owl|2001/XMLSchema)#")) } ;
DROP NAMED ;

# One label per language, the model description as the English definition.
DELETE { ?s rdfs:label ?l } WHERE { ?s rdfs:label ?l FILTER (lang(?l) = "") FILTER EXISTS { ?s rdfs:label ?t FILTER (lang(?t) != "") } } ;
DELETE { ?s rdfs:comment ?c } INSERT { ?s rdfs:comment ?en }
WHERE  { ?s rdfs:comment ?c FILTER (isLiteral(?c) && lang(?c) = "" && datatype(?c) = xsd:string) BIND (STRLANG(STR(?c), "en") AS ?en) }
