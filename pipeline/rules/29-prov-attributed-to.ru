# See 28-prov-derived-from.ru's header for the PROV-O materialization
# rationale. This is the Confidence-side half: martialis:assessedBy's
# agent becomes a standard prov:wasAttributedTo edge.
PREFIX martialis: <https://w3id.org/martialis/ontology#>
PREFIX prov: <http://www.w3.org/ns/prov#>
INSERT { ?confidence prov:wasAttributedTo ?agent }
WHERE  { ?confidence martialis:assessedBy ?agent }
