#!/usr/bin/env bash
# Regenerates the Dart client from packages/contracts/openapi.json (S7 §4.3). Needs Docker and Flutter (fvm or PATH).
# CI runs it and fails on any diff in packages/api-client-dart.
set -euo pipefail
cd "$(dirname "$0")/../.."

# openapi-generator v7.27.0 (latest, 2026-11-02), pinned by digest.
IMAGE=openapitools/openapi-generator-cli:v7.27.0@sha256:949efd0d5cf3c093ef169887b2ebe0879ee2e8074b6476264232ce4fd8ef46d0
OUT=packages/api-client-dart
DART=$(command -v fvm >/dev/null && echo "fvm dart" || echo dart)

# The generator can't read Zod's nullable reference (`allOf: [$ref, {type: [object, null]}]`) and makes the
# field required; a copy rewrites it as `anyOf: [$ref, {type: null}]` (S7 §4.3, PLANNING change log).
SPEC="$OUT/.openapi.json"
bun -e '
const spec = await Bun.file("packages/contracts/openapi.json").json();
const fix = (o) => {
  if (Array.isArray(o)) return o.map(fix);
  if (!o || typeof o !== "object") return o;
  const a = o.allOf;
  if (Array.isArray(a) && a.length === 2 && a[0].$ref && JSON.stringify(a[1].type) === "[\"object\",\"null\"]") {
    const { allOf, ...rest } = o;
    return { ...rest, anyOf: [a[0], { type: "null" }] };
  }
  return Object.fromEntries(Object.entries(o).map(([k, v]) => [k, fix(v)]));
};
await Bun.write(process.argv[1], JSON.stringify(fix(spec), null, 2));
' "$SPEC"

rm -rf "$OUT/lib"
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD:/local" "$IMAGE" generate \
  -i "/local/$SPEC" -g dart-dio -o "/local/$OUT" \
  --additional-properties=pubName=velio_api,pubLibrary=velio_api,serializationLibrary=json_serializable,dateLibrary=core \
  >/dev/null
rm -rf "$SPEC" "$OUT/.openapi-generator" "$OUT/test" "$OUT/doc" "$OUT/.travis.yml" "$OUT/git_push.sh"
(cd "$OUT" && $DART pub get >/dev/null && $DART run build_runner build --delete-conflicting-outputs >/dev/null)
