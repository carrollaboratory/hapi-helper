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
    echo "***********************************"
    echo "Downloading IG from $IG into /tmp"
    echo -e "***********************************\n"
    curl -L -o /tmp/ig.tgz $IG
elif [[ -e "$IG" && "$IG" == *.tgz ]]; then
    echo "***********************************"
    echo "Copying $IG to /tmp"
    echo -e "***********************************\n"
    cp $IG /tmp/ig.tgz
else
    echo "***********************************"
    echo "IG URL must be a tgz file or a URL that points to a tgz file."
    echo -e "***********************************\n"
    exit 1
fi

echo "POSTing the IG to the FHIR server, $FHIR_SERVER"
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
echo ""
# Extract the actual IG
echo "***********************************"
echo "Extracting the Implementation Guide JSON to /tmp"
echo -e "***********************************\n"

tar -xOzf /tmp/ig.tgz --wildcards --no-anchored 'ImplementationGuide*.json' > /tmp/ImplementationGuide.json
ls -l /tmp/ImplementationGuide.json
# I'm getting some errors about mcode's dependencies not matching the current
# FHIR naming, so, I'm removing it as a depency in the JSON for now.
echo "***********************************"
echo "Removing some dependency notes to enable loading without turning off \
strict validation in our test servers. This probably isn't appropriate for \
a production server. However, those probably won't have stringent validation \
activated. "
echo -e "***********************************\n"

jq 'del(.dependsOn, .extension, .definition)' /tmp/ImplementationGuide.json > /tmp/ImplementationGuide_clean.json

ls -l /tmp/ImplementationGuide_clean.json

IG_ID=$(jq -r '.id' /tmp/ImplementationGuide_clean.json)

echo "***********************************"
echo "PUTting to $FHIR_SERVER/ImplementationGuide/$IG_ID"
echo -e "***********************************\n"

# And POST it to the FHIR server
curl -X PUT "$FHIR_SERVER/ImplementationGuide/$IG_ID" \
     -H "Content-Type: application/fhir+json" \
     -d @/tmp/ImplementationGuide_clean.json
