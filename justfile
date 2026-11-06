default:
	@echo "\"just release X.Y.Z\"?"

# Only from a clean, pushed main whose test workflow passed for this commit:
# an immutable vX.Y.Z tag with a GitHub release, and the moving major tag vX
# pointed at it.
#
# Tag vX.Y.Z with a GitHub release, and move vX to it
release version:
	#!/usr/bin/env bash
	set -euo pipefail
	version="{{version}}"
	if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
		echo "error: version must be X.Y.Z (no leading v), got '$version'" >&2
		exit 1
	fi
	tag="v$version"
	major="v${version%%.*}"

	if [ "$(git rev-parse --abbrev-ref HEAD)" != "main" ]; then
		echo "error: not on main" >&2
		exit 1
	fi
	if [ -n "$(git status --porcelain)" ]; then
		echo "error: the working tree isn't clean" >&2
		exit 1
	fi
	git fetch --quiet --tags origin main
	head="$(git rev-parse HEAD)"
	if [ "$head" != "$(git rev-parse origin/main)" ]; then
		echo "error: main and origin/main differ; push (or pull) first" >&2
		exit 1
	fi
	if git rev-parse --quiet --verify "refs/tags/$tag" > /dev/null; then
		echo "error: $tag already exists" >&2
		exit 1
	fi
	conclusion="$(gh run list --workflow test.yml --commit "$head" --status completed \
		--limit 1 --json conclusion --jq '.[0].conclusion // ""')"
	if [ "$conclusion" != "success" ]; then
		echo "error: the test workflow hasn't passed for $head (${conclusion:-no completed run})" >&2
		exit 1
	fi

	git tag -a "$tag" -m "$tag"
	git push origin "$tag"
	gh release create "$tag" --verify-tag --generate-notes --title "$tag"
	# The major tag moves with each release (no GitHub release of its own, so
	# immutable releases don't pin it).
	git tag -f -a "$major" -m "$major -> $tag" "$tag^{commit}"
	git push -f origin "refs/tags/$major"
	echo "Released $tag; $major now points at it."
