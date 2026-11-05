# Turn the LinkML SHACL emitter's output into the structural shapes graph.
PREFIX sh: <http://www.w3.org/ns/shacl#>
PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX owl: <http://www.w3.org/2002/07/owl#>
PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX martialis: <https://w3id.org/martialis/ontology#>
PREFIX x: <urn:x-tmp:>

# type and id are @type/@id, not predicates.
DELETE { ?n sh:property ?s . ?s ?p ?o } WHERE { VALUES ?d { martialis:type martialis:id } ?s sh:path ?d ; ?p ?o . OPTIONAL { ?n sh:property ?s } } ;
# A language map is literals, one per language: no class, node kind or upper bound, and no shape of its own.
DELETE { ?s sh:class martialis:LanguageMap ; sh:nodeKind ?k ; sh:maxCount ?m }
WHERE  { ?s sh:class martialis:LanguageMap OPTIONAL { ?s sh:nodeKind ?k } OPTIONAL { ?s sh:maxCount ?m } } ;
DELETE { ?s ?p ?o } WHERE { ?s sh:targetClass martialis:LanguageMap ; ?p ?o } ;
# A pattern on an IRI-valued slot is written against the authored CURIE; SHACL sees the expanded IRI (patterns.jq).
DELETE { ?s sh:pattern ?c } INSERT { ?s sh:pattern ?i } WHERE { ?s sh:nodeKind sh:IRI ; sh:pattern ?c . GRAPH ?g { [] x:curie ?c ; x:iri ?i } } ;
DROP NAMED ;
# A node shape with no constraint of its own (abstract classes, alignment anchors) validates nothing.
DELETE { ?s ?p ?o }
WHERE  { ?s a sh:NodeShape ; ?p ?o FILTER isIRI(?s) FILTER NOT EXISTS { [] sh:node|sh:class ?s }
         FILTER NOT EXISTS { ?s ?q ?v FILTER (?q NOT IN (rdf:type, rdfs:comment, rdfs:label, rdfs:isDefinedBy, sh:targetClass, sh:targetNode,
             sh:targetSubjectsOf, sh:targetObjectsOf, sh:ignoredProperties, sh:severity, sh:message, sh:deactivated, sh:name,
             sh:description, sh:order, sh:group) && !(?q = sh:closed && ?v = false)) } } ;
# The emitter's detached list chains.
DELETE { ?b ?p ?o } WHERE { ?b ?p ?o FILTER isBlank(?b) FILTER NOT EXISTS { ?root (!x:none)+ ?b FILTER isIRI(?root) } } ;
# Stable names for what the emitter leaves blank: a property shape is its node shape plus its path,
# a list cell its owner plus the list's predicate and position.
DELETE { ?n sh:property ?b . ?b ?p ?o } INSERT { ?n sh:property ?i . ?i ?p ?o }
WHERE  { ?n sh:property ?b FILTER isBlank(?b) ?b sh:path ?path ; ?p ?o
         BIND (IRI(CONCAT(STR(?n), "/", REPLACE(STR(?path), "^.*[/#]", ""))) AS ?i) } ;
DELETE { ?owner ?lp ?head . ?cell ?p ?o . ?prev rdf:rest ?cell } INSERT { ?owner ?lp ?h . ?c ?p ?o2 }
WHERE  { ?owner ?lp ?head FILTER (isIRI(?owner) && isBlank(?head) && ?lp IN (sh:in, sh:ignoredProperties))
         ?head rdf:rest* ?cell . ?cell ?p ?o OPTIONAL { ?prev rdf:rest ?cell }
         { SELECT ?owner ?lp ?cell (COUNT(?mid) AS ?pos) WHERE { ?owner ?lp ?head . ?head rdf:rest* ?cell
             OPTIONAL { ?head rdf:rest* ?mid . ?mid rdf:rest+ ?cell } } GROUP BY ?owner ?lp ?cell }
         BIND (IRI(CONCAT(STR(?owner), "/", REPLACE(STR(?lp), "^.*#", ""))) AS ?h)
         BIND (IF(?pos = 0, ?h, IRI(CONCAT(STR(?h), "/", STR(?pos)))) AS ?c)
         BIND (IF(?p = rdf:rest && ?o != rdf:nil, IRI(CONCAT(STR(?h), "/", STR(?pos + 1))), ?o) AS ?o2) } ;
# The shapes graph's own description.
INSERT DATA { <https://w3id.org/martialis/ontology/shapes/structural> a owl:Ontology, sh:ShapesGraph ;
  dcterms:title "Martialis Structural Shapes"@en ;
  dcterms:description "Generated structural SHACL from model/martialis.yaml: one shape per class, sh:in from the enumerated slots, sh:class on references and the EDTF patterns on literal slots. The blocking tier of make shacl."@en ;
  dcterms:license <https://creativecommons.org/publicdomain/zero/1.0/> }
