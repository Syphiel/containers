#!/usr/bin/env bash

set -o pipefail

make_jwt() {
  now=$(date +%s)
  iat=$((${now} - 60))
  exp=$((${now} + 600))
  b64enc() { openssl base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n'; }
  header_json='{
    "typ":"JWT",
    "alg":"RS256"
  }'
  header=$(echo -n "${header_json}" | b64enc)
  payload_json="{
      \"iat\":${iat},
      \"exp\":${exp},
      \"iss\":\"${GITHUB_APP_CLIENT_ID}\"
  }"
  payload=$(echo -n "${payload_json}" | b64enc)
  header_payload="${header}"."${payload}"
  signature=$(openssl dgst -sha256 -sign <(echo -n "${GITHUB_APP_PRIVATE_KEY}") <(echo -n "${header_payload}") | b64enc)

  JWT="${header_payload}"."${signature}"
}

get_installation_id() {
  INSTALLATION_ID=$(curl -s -L \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $JWT" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    https://api.github.com/app/installations | jq '.[].id')
}

get_access_token() {
  ACCESS_TOKEN=$(curl -s --request POST \
    --url "https://api.github.com/app/installations/${INSTALLATION_ID}/access_tokens" \
    --header "Accept: application/vnd.github+json" \
    --header "Authorization: Bearer ${JWT}" \
    --header "X-GitHub-Api-Version: 2022-11-28" | jq -r '.token')
}

[[ ! -n "${GITHUB_APP_PRIVATE_KEY}" ]] || [[ ! -n "${GITHUB_APP_CLIENT_ID}" ]] && >&2 echo Missing GITHUB_APP_PRIVATE_KEY or GITHUB_APP_CLIENT_ID && exit 1

make_jwt
get_installation_id
get_access_token

export RENOVATE_PLATFORM=github
export RENOVATE_TOKEN=${ACCESS_TOKEN}

[[ -n "${GITHUB_APP_REPOSITORIES}" ]] && export RENOVATE_REPOSITORIES=${GITHUB_APP_REPOSITORIES} || export RENOVATE_AUTODISCOVER=true

/usr/local/sbin/renovate-entrypoint.sh "$@"
