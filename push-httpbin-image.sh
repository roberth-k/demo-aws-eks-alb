#!/usr/bin/env bash
set -euo pipefail

readonly source_image="kennethreitz/httpbin:latest"

readonly target_registry_url="$(terraform output -raw httpbin_registry_url)"

readonly target_repository_url="$(terraform output -raw httpbin_repository_url)"

readonly target_image="${target_repository_url}:latest"

1>&2 echo ""
1>&2 echo "publishing $source_image as $target_image..."
1>&2 echo ""

aws ecr get-login-password | docker login --username AWS --password-stdin "$target_registry_url"

docker pull "$source_image"

docker tag "$source_image" "$target_image"

docker push "$target_image"
