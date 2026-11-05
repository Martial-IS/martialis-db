# The model -> Turtle pairing each CURIE pattern with its prefix-expanded form, for shacl.ru.
.prefixes as $p | .slots[] | .pattern // empty
| [., reduce ($p | to_entries[]) as $e (.; gsub("(?<a>[(|^])\($e.key):"; "\(.a)\($e.value | gsub("(?<c>[.?*+()|\\[\\]{}^$\\\\])"; "\\\(.c)"))"))]
| select(.[0] != .[1]) | "[] <urn:x-tmp:curie> \(.[0] | tojson) ; <urn:x-tmp:iri> \(.[1] | tojson) ."
