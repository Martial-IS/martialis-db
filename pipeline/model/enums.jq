# enums.rq results -> the LinkML enums; fails on no scheme, a scheme with no concepts or two schemes with one enum name.
[.results.bindings[] | map_values(.value)] | if length == 0 then error("no skos:ConceptScheme found") else group_by(.ns) end
| (map({key: .[0].pfx, value: .[0].ns}) | from_entries) as $prefixes
| map((.[0].ns | rtrimstr("/") | split("/")[-1] | split("-") | map((.[:1] | ascii_upcase) + .[1:]) | join("")) as $name
  | if any(.c == null) then error("scheme \(.[0].ns) has no skos:Concept members") else . end
  | {key: $name, value: {enum_uri: .[0].ns, description: ([.[].title] | unique | join("; ")),
      permissible_values: (map(.ns as $ns | "\(.pfx):\(.c | ltrimstr($ns))") | unique | map({key: ., value: {meaning: .}}) | from_entries)}})
| if (map(.key) | length) != (map(.key) | unique | length) then error("two schemes derive one enum name") else . end
| {id: "https://martial.is/model/enums", name: "martialis_enums", title: "Martialis controlled vocabularies as LinkML enums",
   description: "Each permissible value is the scheme-prefixed concept CURIE and carries the concept IRI as its meaning.",
   license: "CC0-1.0", prefixes: ({linkml: "https://w3id.org/linkml/"} + $prefixes), default_prefix: "martialis",
   default_range: "string", imports: ["linkml:types"], enums: from_entries}
