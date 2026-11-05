# Raw LinkML context + the model ($m, slurped) -> the authoring context.
$m[0] as $m |
(([$m.classes[] | .attributes // {}] | add) + $m.slots) as $s
| [$m.classes | to_entries[] | select(.value.mixin) | .key] as $mixins
| ($m.enums // {} | keys) as $literal
| def iri($c): ($m.classes[$c].class_uri // "martialis:\($c)" | split(":")) as [$p, $l]
    | if $m.prefixes[$p] then $m.prefixes[$p] + $l else "\($p):\($l)" end;
.["@context"] |= with_entries(select(.key as $k | $mixins | index($k) | not)
  | .key as $k | ($s[$k] // {}) as $d | .value |=
    if $k == "type" then "@type"
    elif type != "object" then .
    elif $d.range == "LanguageMap" then {"@id": (.["@id"] // $k), "@container": "@language"}
    elif $literal | index($d.range) then {"@id": (.["@id"] // $k)}
    elif .["@context"].meaning? == "@id" then {"@id": (.["@id"] // $k), "@type": "@id"}
    elif ($d.inlined or $d.inlined_as_list) and .["@type"] == "@id" then del(.["@type"])
    else . end)
| .nestedTypes = ($s | with_entries(select((.value.inlined or .value.inlined_as_list)
    and .value.range != "LanguageMap" and $m.classes[.value.range] != null)) | map_values(iri(.range)))
| .comments |= (del(.generation_date) | .description = $note)
