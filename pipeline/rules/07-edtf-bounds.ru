PREFIX martialis: <https://w3id.org/martialis/ontology#>
PREFIX schema:    <https://schema.org/>
PREFIX xsd:       <http://www.w3.org/2001/XMLSchema#>

# EDTF -> earliestYear / latestYear.
#
# Handles Level 0 (YYYY, YYYY-MM, YYYY-MM-DD, intervals), Level 1
# (qualifiers ? ~ %, unspecified digits X, open/unknown interval ends,
# negative years) and Level 2 discrete sets [a,b].
#
# Unspecified digits are actually EASIER here than in code: the lower
# bound replaces X with 0, the upper bound replaces X with 9.
INSERT { ?s martialis:earliestYear ?lo ; martialis:latestYear ?hi }
WHERE {
  # Event dates (births and deaths too, as schema:startDate on the event node),
  # dissolution dates, source publication dates and rank/honor conferral dates.
  VALUES ?p { schema:startDate schema:endDate schema:datePublished
              martialis:dateConferred }
  ?s ?p ?raw .

  # 0. strip qualifiers and any set braces
  BIND(REPLACE(STR(?raw), "[?~%]", "")                        AS ?q)
  BIND(REPLACE(REPLACE(?q, "^[\\[{]", ""), "[\\]}]$", "")     AS ?clean)

  # 1. split into a low-side and high-side token.
  #    interval "a/b" -> a , b
  #    set "a,b,c"    -> a , c   (EDTF sets are written in order)
  #    single "a"     -> a , a
  BIND(IF(CONTAINS(?clean, "/"), STRBEFORE(?clean, "/"),
       IF(CONTAINS(?clean, ","), STRBEFORE(?clean, ","), ?clean))  AS ?loTok)
  BIND(IF(CONTAINS(?clean, "/"), STRAFTER(?clean, "/"),
       IF(CONTAINS(?clean, ","), REPLACE(?clean, "^.*,", ""), ?clean)) AS ?hiTok)

  # 2. an open/unknown endpoint ("..", "", "unknown") contributes no bound
  BIND(IF(?loTok = ".." || ?loTok = "" || ?loTok = "unknown", "", ?loTok) AS ?loT)
  BIND(IF(?hiTok = ".." || ?hiTok = "" || ?hiTok = "unknown", "", ?hiTok) AS ?hiT)

  # 3. year part, sign-aware ("-0500" -> negative)
  BIND(STRSTARTS(?loT, "-") AS ?loNeg)
  BIND(STRSTARTS(?hiT, "-") AS ?hiNeg)
  BIND(REPLACE(?loT, "^-", "") AS ?loA)
  BIND(REPLACE(?hiT, "^-", "") AS ?hiA)
  BIND(SUBSTR(?loA, 1, 4) AS ?loY)
  BIND(SUBSTR(?hiA, 1, 4) AS ?hiY)

  # 4. unspecified digits: X -> 0 for the lower bound, 9 for the upper.
  #    A negative year inverts which substitution is the smaller number.
  BIND(REPLACE(?loY, "X", IF(?loNeg, "9", "0")) AS ?loDigits)
  BIND(REPLACE(?hiY, "X", IF(?hiNeg, "0", "9")) AS ?hiDigits)

  FILTER(REGEX(?loDigits, "^[0-9]{4}$") || REGEX(?hiDigits, "^[0-9]{4}$"))
  BIND(IF(REGEX(?loDigits, "^[0-9]{4}$"),
          IF(?loNeg, -xsd:integer(?loDigits), xsd:integer(?loDigits)), ?unbound) AS ?lo)
  BIND(IF(REGEX(?hiDigits, "^[0-9]{4}$"),
          IF(?hiNeg, -xsd:integer(?hiDigits), xsd:integer(?hiDigits)), ?unbound) AS ?hi)
}
