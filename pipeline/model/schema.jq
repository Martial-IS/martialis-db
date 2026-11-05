# Raw LinkML JSON Schema + the model ($m, slurped) -> the closed authoring schema.
$m[0] as $m |
[$m.classes | to_entries[] | select(.value.mixin) | .key] as $mixins
| .["$defs"] |= (with_entries(select(.key as $k | $mixins | index($k) | not))
    | if has("LanguageMap") then .LanguageMap = {type: "object", additionalProperties:
        {anyOf: [{type: "string"}, {type: "array", items: {type: "string"}}]}} else . end)
| .["$id"] = "https://martial.is/schemas/\($slug).schema.json"
| {"$comment": $note} + .
