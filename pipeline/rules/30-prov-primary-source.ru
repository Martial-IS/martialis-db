# prov:hadPrimarySource (a subproperty of prov:wasDerivedFrom) for a
# supporting citation whose information is first-hand (infotype:primary) and
# whose Source is the first record of it (srcclass:original): PROV-O's
# "produced by some agent with direct experience and knowledge about the
# topic". Same subjects as 28-prov-derived-from.ru: claim and fact nodes,
# never the entities the records describe.
PREFIX martialis: <https://w3id.org/martialis/ontology#>
PREFIX prov: <http://www.w3.org/ns/prov#>
PREFIX infotype: <https://w3id.org/martialis/vocab/information-type/>
PREFIX srcclass: <https://w3id.org/martialis/vocab/source-classification/>
INSERT { ?entity prov:hadPrimarySource ?source }
WHERE  { ?entity martialis:hasEvidence ?ev .
         ?ev martialis:basedOnSource ?source ;
             martialis:supports true ;
             martialis:informationType infotype:primary .
         ?source martialis:sourceClassification srcclass:original .
         MINUS {
             VALUES ?described { martialis:Person martialis:Organization martialis:Place
                                 martialis:Style martialis:Event martialis:RankingSystem }
             ?entity a ?described
         } }
