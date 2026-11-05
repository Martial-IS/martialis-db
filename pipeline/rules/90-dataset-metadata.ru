# Dataset front matter: the counts.
#
# The static half (title, description, licence, rights, maker, ...) is
# ontology/dataset.ttl, loaded alongside the data. Only what has to be
# computed from the graph itself lives here, so the counts stay accurate
# as the database grows without being hand-maintained anywhere. No build
# date: the export is a function of the records alone, so the same records
# always give the same file. A release states dcterms:issued in
# ontology/dataset.ttl.
#
# Runs last: void:triples counts the graph as finally built.
PREFIX martialis: <https://w3id.org/martialis/ontology#>
PREFIX void:   <http://rdfs.org/ns/void#>

INSERT {
  <https://martial.is/data.ttl#dataset> void:classPartition ?partition .
  ?partition void:class ?class ; void:entities ?n .
} WHERE {
  SELECT ?class (COUNT(?e) AS ?n)
         (IRI(CONCAT("https://martial.is/data.ttl#dataset/class/",
                     STRAFTER(STR(?class), "ontology#"))) AS ?partition)
  WHERE {
    VALUES ?class { martialis:Person martialis:Style martialis:Place
                    martialis:Source martialis:Organization martialis:Event
                    martialis:RankingSystem }
    ?e a ?class .
  } GROUP BY ?class
} ;

INSERT { <https://martial.is/data.ttl#dataset> void:entities ?n }
WHERE {
  SELECT (COUNT(?e) AS ?n) WHERE {
    VALUES ?class { martialis:Person martialis:Style martialis:Place
                    martialis:Source martialis:Organization martialis:Event
                    martialis:RankingSystem }
    ?e a ?class .
  }
} ;

INSERT { <https://martial.is/data.ttl#dataset> void:triples ?n }
WHERE { SELECT (COUNT(*) AS ?n) WHERE { ?s ?p ?o } }
