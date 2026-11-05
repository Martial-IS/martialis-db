# martialis:TraditionOnlyAssertion: an Assertion with supporting evidence,
# every piece of which cites a Source marked martialis:lineageTradition true.
# Evidence on the assertion's interactions counts (teacher claims keep it
# there). An inline uri citation has no Source to carry the mark, so it
# counts as independent and keeps the assertion out. The Assertion subclasses
# are listed: no rule loads the ontology, so rdfs:subClassOf is not available.
PREFIX martialis: <https://w3id.org/martialis/ontology#>
INSERT { ?a a martialis:TraditionOnlyAssertion }
WHERE  { VALUES ?class { martialis:TeacherAssertion martialis:RankAssertion
                          martialis:HonorAssertion martialis:AffiliationAssertion
                          martialis:DocumentTransmissionAssertion martialis:IdentityAssertion
                          martialis:HistoricityAssertion
                          martialis:StyleRelationAssertion martialis:Participation
                          martialis:InstructorRole martialis:OfficerRole
                          martialis:Membership }
         ?a a ?class ;
            (martialis:hasEvidence|martialis:hasInteraction/martialis:hasEvidence) ?ev .
         ?ev martialis:supports true ;
             martialis:basedOnSource/martialis:lineageTradition true .
         FILTER NOT EXISTS {
             ?a (martialis:hasEvidence|martialis:hasInteraction/martialis:hasEvidence) ?other .
             ?other martialis:supports true .
             FILTER NOT EXISTS { ?other martialis:basedOnSource/martialis:lineageTradition true }
         } }
