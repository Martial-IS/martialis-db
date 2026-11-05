# Materialize the inherited peer-review status. martialis:peerReview is
# authored once on a container Source (a refereed journal, a wiki) and holds
# for every item in it, and a dated state holds what its resource holds. This
# pass writes that value on each item and state that states none of its own,
# taking it from the nearest ancestor that carries one, so a consumer reads one
# triple instead of walking partOf/specializationOf. An item's own value (a
# book review in a refereed journal) always wins.
PREFIX martialis: <https://w3id.org/martialis/ontology#>
INSERT { ?item martialis:peerReview ?status }
WHERE  { ?item (martialis:partOf|martialis:specializationOf)+ ?anc .
         ?anc martialis:peerReview ?status .
         FILTER NOT EXISTS { ?item martialis:peerReview ?own }
         FILTER NOT EXISTS {
             ?item (martialis:partOf|martialis:specializationOf)+ ?mid .
             ?mid (martialis:partOf|martialis:specializationOf)+ ?anc .
             ?mid martialis:peerReview ?nearer } }
