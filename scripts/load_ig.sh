#!/bin/bash

# Load the NCPI FHIR IG into a FHIR server
# usage:
# load_ig.sh [BASE_URL] [IG package URL]
# If no base url is provided, it will assume you are loading to
# http://localhost:8080/fhir
#
# By default, the package will be the standard NCPI IG V2 package

#IG=https://deploy-preview-162--ncpi-fhir-ig-v2.netlify.app/package.tgz
IG=${2:-"https://nih-ncpi.github.io/ncpi-fhir-ig-2/package.tgz"}
FHIR_SERVER=${1:-"http://localhost:8080/fhir"}
# For netlify, we have to use --insecure, but the regular IG is fine without
# that option: i.e.
#            curl -L --insecure -o /tmp/ig.tgz $IG
if [[ "$IG" =~ ^[a-zA-Z]+://  && "$IG" == *.tgz  ]]; then
    curl -L -o /tmp/ig.tgz $IG
elif [[ -e "$IG" && "$IG" == *.tgz ]]; then
    cp $IG /tmp/ig.tgz
else
    echo "IG URL must be a tgz file or a URL that points to a tgz file."
    exit 1
fi

BASE64_CONTENT=$(base64 -w 0 /tmp/ig.tgz)
curl -s -X POST "$FHIR_SERVER/ImplementationGuide/\$install" \
  -H "Content-Type: application/json" \
  --data-binary @- <<EOF
{
  "resourceType": "Parameters",
  "parameter": [
    {
      "name": "npmContent",
      "valueBase64Binary": "$BASE64_CONTENT"
    }
  ]
}
EOF
