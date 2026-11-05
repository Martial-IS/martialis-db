# Source entities -> CSL-JSON.
#
# Mostly a field rename table. The one piece of real logic is the EDTF ->
# CSL date-variable conversion: CSL has no partial-precision flag beyond
# the length of the date-parts array itself, and no way to say "one of
# these, unresolved", so EDTF's ?/~/% qualifiers all collapse to CSL's
# circa: true and a Level 2 set exports as a circa interval spanning it.
#
# 'website' has no CSL equivalent (CSL never instantiates containers) and
# exports as the nearest real CSL type, 'periodical' - the one documented,
# one-way deviation from CSL's own vocabulary.
#
# The record shape is the migrated, ontology-keyed one: sourceType already
# carries the CSL item type, contributors are hasContributor entries keyed by
# contributorRole, publisher is a node with publisherName, and dates/partOf
# use the *Date / camelCase slot names. The identifier slots are top-level
# rather than nested. Only the five CSL identifier variables are emitted;
# oclc/ndl/cinii/handle/archiveOrgId/wikidata have no CSL-JSON equivalent.

def edtf_parts:
  # "1938-04-01~" -> [1938,4,1]; drops qualifiers, keeps precision.
  sub("[?~%]+$"; "")
  | select(length > 0)
  | (if startswith("-") then -1 else 1 end) as $sign
  | sub("^-"; "")
  | split("-")
  | map(select(test("^[0-9X]+$")) | gsub("X"; "0") | tonumber)
  | select(length > 0)
  | .[0] |= (. * $sign);

def edtf_to_csl:
  if . == null or . == "" then null
  elif type == "number" then {"date-parts": [[.]]}
  else . as $raw
    | ($raw | test("[?~%]")) as $circa
    | ($raw | sub("^[\\[{]"; "") | sub("[\\]}]$"; "")) as $body
    | (if ($body | test("/")) then ($body | split("/"))
       elif ($body | test(",")) then [($body | split(",") | first), ($body | split(",") | last)]
       else [$body] end) as $tokens
    | ($tokens | map(select(. != ".." and . != "" and . != "unknown") | edtf_parts)) as $parts
    | if ($parts | length) == 0 then null
      else {"date-parts": $parts}
           + (if $circa or ($raw | test("^[\\[{]")) then {"circa": true} else {} end)
      end
  end;

def contributor:
  { family: .family, given: .given, literal: .literal,
    "dropping-particle": .droppingParticle,
    "non-dropping-particle": .nonDroppingParticle,
    suffix: .suffix }
  | with_entries(select(.value != null));

# CSL variable names that differ from ours. archive_collection and
# archive_location really do keep the underscore in csl-data.json, unlike
# chapter-number/call-number - verified upstream, not a copy-paste slip.
def locators:
  { volume: .volume, issue: .issue, page: .page, edition: .edition,
    "chapter-number": .chapterNumber, part: .part, section: .section,
    archive: .archive, archive_collection: .archiveCollection,
    archive_location: .archiveLocation, "call-number": .callNumber }
  | with_entries(select(.value != null));

def identifiers:
  { ISBN: .isbn, ISSN: .issn, DOI: .doi, PMID: .pmid, PMCID: .pmcid }
  | with_entries(select(.value != null));

[ .[] | select(.id != null and .type == "Source") ] as $sources
# A dated state (specializationOf) inherits every field of its resource it
# does not state itself: url, publisher, contributors, container.
| ($sources | map({key: .id, value: .}) | from_entries) as $byId
| [ $sources[]
    | if .specializationOf != null and $byId[.specializationOf] != null
      then $byId[.specializationOf] + with_entries(select(.value != null))
      else . end ] as $all
# a container is whatever some other Source's partOf points at - not
# anything keyed on a filename prefix, which is a naming habit nothing
# enforces and two real containers do not follow.
| ([ $all[].partOf | select(. != null) ] | unique) as $referenced
| ([ $all[] | select(.id as $i | $referenced | index($i)) | {key: .id, value: .title} ] | from_entries) as $containers
| [ $all[]
    | { id: .id,
        type: (if .sourceType == "website" then "periodical" else .sourceType end) }
      + (if .title then {title: .title} else {} end)
      + ( [ (.hasContributor // [])[] | select(.contributorRole != null) ]
          | group_by(.contributorRole) | map({ (.[0].contributorRole): map(contributor) }) | add // {} )
      + (if (.publisher.publisherName // null) then {publisher: .publisher.publisherName} else {} end)
      + (if (.partOf != null and $containers[.partOf] != null)
         then {"container-title": $containers[.partOf]} else {} end)
      + (if (.issuedDate   | edtf_to_csl) then {issued:   (.issuedDate   | edtf_to_csl)} else {} end)
      + (if (.accessedDate | edtf_to_csl) then {accessed: (.accessedDate | edtf_to_csl)} else {} end)
      + locators
      + identifiers
      + (if .url      then {URL: .url}           else {} end)
      + (if .language then {language: .language} else {} end)
  ]
| sort_by(.id)
