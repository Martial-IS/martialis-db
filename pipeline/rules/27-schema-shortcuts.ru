# schema.org shortcuts: a birth, a death, a founding and a dissolution are
# event nodes (martialis:birthEvent, ...), whose date and place are the event's
# schema:startDate/endDate and schema:location. schema.org expects them on the
# person or organization itself, so they are stated there too, the way
# wasTaughtBy restates a teacher assertion. A date is copied only when it is a
# plain ISO date (YYYY, YYYY-MM, YYYY-MM-DD): schema.org cannot express EDTF
# uncertainty ("1905~", "19XX", an interval), which stays on the event node.
PREFIX martialis: <https://w3id.org/martialis/ontology#>
PREFIX schema:    <https://schema.org/>
INSERT { ?p schema:birthDate ?d }
WHERE  { ?p martialis:birthEvent/schema:startDate ?d .
         FILTER(REGEX(STR(?d), "^[0-9]{4}(-[0-9]{2}(-[0-9]{2})?)?$")) } ;
INSERT { ?p schema:deathDate ?d }
WHERE  { ?p martialis:deathEvent/schema:startDate ?d .
         FILTER(REGEX(STR(?d), "^[0-9]{4}(-[0-9]{2}(-[0-9]{2})?)?$")) } ;
INSERT { ?p schema:birthPlace ?g }
WHERE  { ?p martialis:birthEvent/schema:location ?g } ;
INSERT { ?p schema:deathPlace ?g }
WHERE  { ?p martialis:deathEvent/schema:location ?g } ;
INSERT { ?o schema:foundingDate ?d }
WHERE  { ?o a martialis:Organization ;
            martialis:foundedEvent/schema:startDate ?d .
         FILTER(REGEX(STR(?d), "^[0-9]{4}(-[0-9]{2}(-[0-9]{2})?)?$")) } ;
INSERT { ?o schema:dissolutionDate ?d }
WHERE  { ?o a martialis:Organization ;
            martialis:dissolvedEvent/schema:endDate ?d .
         FILTER(REGEX(STR(?d), "^[0-9]{4}(-[0-9]{2}(-[0-9]{2})?)?$")) }
