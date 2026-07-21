# TAGGING.md — release tagging guide for AI agents

Deterministic instructions for tagging this repository. Follow the steps in
order. Do not invent versions — every number is derived from the sources listed
below.

## What a tag represents

A git tag in this repo pins one reproducible build: a specific **Strimzi** base
image, the **Kafka** version it ships, and the **Inkless** release patched into
it. The CI workflow (`.github/workflows/build-push.yml`) builds and pushes the
matching image to GHCR.

## Version coordinates

Every release is fully described by four numbers. Resolve them from these
authoritative sources — never from memory:

| Coordinate | Example | Source of truth |
|------------|---------|-----------------|
| `STRIMZI` | `1.1.0` | <https://strimzi.io/downloads/> |
| `KAFKA` | `4.2.1` | The Kafka version the chosen Strimzi release ships (same page) |
| `INKLESS` | `0.44` | <https://github.com/aiven/inkless/releases> |
| Upstream Inkless tag | `inkless-4.2.1-0.44` | <https://github.com/aiven/inkless/tags> — form `inkless-<KAFKA>-<INKLESS>` |

Two values are **derived**, do not choose them freely:

- Inkless distribution version = `<KAFKA>-inkless` (e.g. `4.2.1-inkless`).
  Confirm against `gradle.properties` (`version=`) at the upstream Inkless tag.
- Strimzi base image = `quay.io/strimzi/kafka:<STRIMZI>-kafka-<KAFKA>`.
  Confirm the tag exists on quay.io before tagging.

## Repo tag scheme

Annotated, signed git tags of the form:

```
v<STRIMZI>-kafka-<KAFKA>-inkless-<INKLESS>
```

Example: `v1.1.0-kafka-4.2.1-inkless-0.44`.

This maps 1:1 to the published image tag (the `v` prefix is dropped for images):

```
ghcr.io/digitalis-io/inkless-strimzi:<STRIMZI>-kafka-<KAFKA>-inkless-<INKLESS>
```

Example image: `ghcr.io/digitalis-io/inkless-strimzi:1.1.0-kafka-4.2.1-inkless-0.44`.

## Preconditions — verify before tagging

Tag only a commit on `main` (or the release branch) that already contains the
correct state. Check all of the following:

1. The `inkless` submodule pointer is on the upstream tag for this release:

   ```sh
   git -C inkless describe --tags
   # must print: inkless-<KAFKA>-<INKLESS>   e.g. inkless-4.2.1-0.44
   ```

2. `Dockerfile` build-arg defaults match this release (`STRIMZI_VERSION`,
   `KAFKA_VERSION`, `INKLESS_DIST_VERSION`).
3. `.github/workflows/build-push.yml` matrix contains an entry for this
   `strimzi` / `kafka` / `inkless` combination.
4. Working tree is clean: `git status --porcelain` prints nothing.

If any precondition fails, fix it in a normal PR and merge first. **Do not tag a
dirty or inconsistent tree.**

## Create the tag

Tags are **annotated and GPG-signed** under the Digitalis identity (this repo is
under the `digitalis-io` org). Resolve the signing key dynamically — never
hardcode a key id.

```sh
EMAIL="<you>@digitalis.io"
KEY=$(gpg --list-secret-keys --with-colons "$EMAIL" | awk -F: '/^fpr:/ {print $10; exit}')
[ -n "$KEY" ] || { echo "No GPG key for $EMAIL — stop, do not sign with the wrong key"; exit 1; }

TAG="v1.1.0-kafka-4.2.1-inkless-0.44"   # v<STRIMZI>-kafka-<KAFKA>-inkless-<INKLESS>

git -c user.email="$EMAIL" -c user.signingkey="$KEY" \
    tag -s "$TAG" -m "Strimzi 1.1.0 (Kafka 4.2.1) + Inkless 0.44"

git verify-tag "$TAG"   # must succeed (good signature)
```

## Push the tag

Push to the `digitalis-io` fork remote (named `fork` in local clones; may be
`origin` elsewhere — check `git remote -v`).

```sh
git push fork "$TAG"
```

Pushing the tag does **not** trigger the image build — the workflow runs on
`push` to `main` and `workflow_dispatch`. After pushing the tag, trigger the
build explicitly:

```sh
gh workflow run build-push.yml --repo digitalis-io/inkless-strimzi
```

Then confirm the image was published:

```sh
gh api /orgs/digitalis-io/packages/container/inkless-strimzi/versions \
  --jq '.[].metadata.container.tags[]' | grep '1.1.0-kafka-4.2.1-inkless-0.44'
```

## Adding a new version (do this before tagging it)

When a new Strimzi release lands on <https://strimzi.io/downloads/>:

1. Find the Kafka version it ships and the matching Inkless tag
   `inkless-<KAFKA>-<INKLESS>` at <https://github.com/aiven/inkless/tags>.
2. Repoint the submodule and stage it:

   ```sh
   git -C inkless fetch --tags origin
   git -C inkless checkout inkless-<KAFKA>-<INKLESS>
   git add inkless
   ```

3. Update `Dockerfile` build-arg defaults and add a matrix entry to
   `.github/workflows/build-push.yml`:

   ```yaml
   - strimzi: "<STRIMZI>"
     kafka: "<KAFKA>"
     inkless: "<INKLESS>"
   ```

4. Open a PR, get CI green (it builds without pushing on PRs), merge, then tag
   per the steps above.

Keep older matrix entries in place — the matrix accumulates supported versions;
it is not replaced.
