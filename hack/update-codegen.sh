#!/bin/bash

# Copyright 2019 The Jetstack cert-manager contributors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

# This script should be run via `bazel run //hack:update-bazel`
REPO_ROOT=${BUILD_WORKSPACE_DIRECTORY:-"$(cd "$(dirname "$0")" && pwd -P)"/..}
runfiles="$(pwd)"
export PATH="${runfiles}/third_party/k8s.io/code-generator:${runfiles}/hack:${runfiles}/hack/bin:${PATH}"
cd "${REPO_ROOT}"

export GO111MODULE=off

# Generate deepcopy functions for ACME external webhook API
generate-groups.sh "deepcopy" \
  github.com/jetstack/cert-manager/pkg/client github.com/jetstack/cert-manager/pkg/acme/webhook/apis \
  "acme:v1alpha1" \
  --output-base "${GOPATH}/src/" \
  --go-header-file "${runfiles}/hack/boilerplate/boilerplate.go.txt"

# Generate deepcopy functions for the metav1 API
generate-groups.sh "deepcopy" \
  github.com/jetstack/cert-manager/pkg/client \
  github.com/jetstack/cert-manager/pkg/apis \
  "meta:v1" \
  --output-base "${GOPATH}/src/" \
  --go-header-file "${runfiles}/hack/boilerplate/boilerplate.go.txt"

# Generate deepcopy, client, informer and listers for the external certmanager API
generate-groups.sh "deepcopy,client,informer,lister" \
  github.com/jetstack/cert-manager/pkg/client \
  github.com/jetstack/cert-manager/pkg/apis \
  "certmanager:v1alpha2 acme:v1alpha2" \
  --output-base "${GOPATH}/src/" \
  --go-header-file "${runfiles}/hack/boilerplate/boilerplate.go.txt"

# Generate deepcopy, default and conversions for the internal certmanager and meta APIs
generate-groups-internal.sh "deepcopy,defaulter,conversion" \
  github.com/jetstack/cert-manager/pkg/client \
  github.com/jetstack/cert-manager/pkg/internal/apis \
  github.com/jetstack/cert-manager/pkg/internal/apis \
  "certmanager:v1alpha2 acme:v1alpha2 meta:v1" \
  --output-base "${GOPATH}/src/" \
  --go-header-file "${runfiles}/hack/boilerplate/boilerplate.go.txt"

# Generate deepcopy, default and conversions for internal testdata APIs
generate-groups-internal.sh "deepcopy,defaulter,conversion" \
  github.com/jetstack/cert-manager/pkg/webhook/handlers/testdata/generated \
  github.com/jetstack/cert-manager/pkg/webhook/handlers/testdata/apis \
  github.com/jetstack/cert-manager/pkg/webhook/handlers/testdata/apis \
  "testgroup:v1" \
  --output-base "${GOPATH}/src/" \
  --go-header-file "${runfiles}/hack/boilerplate/boilerplate.go.txt"

update-bazel.sh
