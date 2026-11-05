# Document-shape preparation, run over the merged corpus before JSON-LD
# conversion: one shared @context, an @graph built from the corpus, and, for
# every nested node, its `@type` and a deterministic `@id`.
#
# JSON-LD cannot infer the @type. A property-scoped context may only hold term
# definitions, and `@type` there is a keyword redefinition (riot rejects it);
# `@type` coercion types a literal value, never a node object. But the class of a
# nested node is not something to look up in a graph: it is the `range` the model
# already gives the slot. `make model` (pipeline/model/context.jq) publishes that slot -> class map as
# the context document's top-level `nestedTypes` member, and this pass writes each
# value as the object's `@type`.
#
# The `@id` makes the nested node a named, addressable resource instead of a
# blank node. A claim (an Assertion or Participation) carries its own ULID, and
# like a record its IRI is `https://martial.is/entity/<ULID>`: one rule for
# every `id`, stable when the claims around it are added, removed or reordered.
# Any other nested node is named from its parent's IRI plus the slot and, for a
# list, the index (`<parent>/<slot>[/<index>]`), never authored and never
# random. Because no
# blank node reaches the export, Jena has nothing to relabel, so a regenerated
# export diffs on real change instead of on blank-node churn. Nodes are named
# bottom-up too, so a nested node's own nested nodes hang off its new IRI.
#
# `$types` keys are slot terms as authored; single and list-valued slots are
# handled alike, and `LanguageMap` slots are absent from the map (a language map
# is a literal, not a node).
#
# A record with no `id` is an error, not a skip: `id` expands to `@id`, so it
# would become a blank node with no entity IRI, invisible to the `sh:class` and
# reference shapes. `make schema` rejects it first; this covers `make rdf` run
# on its own.
#
# Graph-shape work - EDTF bounds, materialised edges - lives in
# pipeline/rules/*.ru instead.
#
# Input:  $ctx (the shared context), $types (slot -> class IRI) + an array of
#         entity documents.
# Output: one JSON-LD document with a shared @context and a typed @graph.

# Type and name every nested node, at any depth. `$base` is the IRI of the
# object's parent; a nested node with its own `id` (a claim) is that id, which
# @base resolves to https://martial.is/entity/<id>, else `$base` + "/" + slot
# (+ "/" + index).
def nested($base):
  . as $o
  | reduce ($o | keys_unsorted[]) as $k (.;
      $types[$k] as $t
      | if $t == null then .
        elif ($o[$k] | type) == "object" then
          ($o[$k].id // ($base + "/" + $k)) as $child
          | .[$k] = ($o[$k] + { "@type": $t, "id": $child } | nested($child))
        elif ($o[$k] | type) == "array" then
          .[$k] = [ range(0; ($o[$k] | length)) as $i
                    | $o[$k][$i]
                    | if type == "object" then
                        (.id // ($base + "/" + $k + "/" + ($i | tostring))) as $child
                        | . + { "@type": $t, "id": $child } | nested($child)
                      else . end ]
        else . end);

{ "@context": $ctx,
  "@graph": [ .[]
              | if .id == null then error("record with no id: \(.name // .title)") else . end
              | del(.["@context"])
              # `notes` are addressed to a maintainer: they stay in the YAML
              # and never reach the export.
              | walk(if type == "object" then del(.notes) else . end)
              | nested(.id) ] }
