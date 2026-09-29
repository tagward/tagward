#!/usr/bin/env bash
# M0 smoke test. Runs against a started compose stack (docker compose up -d --wait).
# Exit 0 only when every M0 check passes. Each check prints PASS or FAIL with detail.
set -u
cd "$(dirname "$0")"
# shellcheck disable=SC1091
[ -f .env ] && set -a && . ./.env && set +a
RANGER=${RANGER_URL:-http://localhost:6080}
RANGER_AUTH="admin:${RANGER_ADMIN_PASSWORD:-Ranger4dm1n!}"
OPENSEARCH=${OPENSEARCH_URL:-http://localhost:9200}
KEYCLOAK=${KEYCLOAK_URL:-http://localhost:8180}
OM=${OM_URL:-http://localhost:8585}
SERVICE=trino-demo
POLICY=tpch-tiny-customer-priya
fails=0

pass() { printf 'PASS  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*"; fails=$((fails + 1)); }
rj() { curl -sS -u "$RANGER_AUTH" -H 'Accept: application/json' -H 'Content-Type: application/json' "$@"; }
retry() { # retry <seconds> <command...>
  local deadline=$(( $(date +%s) + $1 )); shift
  until "$@"; do [ "$(date +%s)" -ge "$deadline" ] && return 1; sleep 5; done
}

echo "== M0.2 Ranger admin on PostgreSQL with OpenSearch audit source"
if rj -o /dev/null -w '%{http_code}' "$RANGER/service/public/v2/api/servicedef/name/trino" | grep -q '^200$'; then
  pass "admin login works and the trino service definition exists"
else
  fail "cannot read the trino service definition from Ranger admin"
fi
if docker compose exec -T ranger-admin grep -A1 'ranger.audit.source.type' /opt/ranger/admin/ews/webapp/WEB-INF/classes/conf/ranger-admin-site.xml 2>/dev/null | grep -q opensearch; then
  pass "ranger.audit.source.type=opensearch"
else
  fail "ranger-admin-site.xml does not select opensearch as audit source"
fi
if docker compose ps --format '{{.Service}}' | grep -qiE 'solr|zookeeper|zk'; then fail "a Solr or ZooKeeper container is running"; else pass "no Solr, no ZooKeeper"; fi

echo "== M0.3 a hand-written policy denies alice and allows priya"
if ! rj -o /dev/null -w '%{http_code}' "$RANGER/service/public/v2/api/service/name/$SERVICE" | grep -q '^200$'; then
  rj -o /dev/null -w 'create service: %{http_code}\n' -X POST "$RANGER/service/public/v2/api/service" -d @- <<JSON
{"name":"$SERVICE","type":"trino","isEnabled":true,"description":"M0 smoke",
 "configs":{"username":"admin","password":"none","jdbc.driverClassName":"io.trino.jdbc.TrinoDriver","jdbc.url":"jdbc:trino://trino:8080"}}
JSON
fi
if ! rj -o /dev/null -w '%{http_code}' "$RANGER/service/public/v2/api/service/$SERVICE/policy/$POLICY" | grep -q '^200$'; then
  rj -o /dev/null -w 'create policy: %{http_code}\n' -X POST "$RANGER/service/public/v2/api/policy" -d @- <<JSON
{"service":"$SERVICE","name":"$POLICY","isEnabled":true,"isAuditEnabled":true,
 "resources":{"catalog":{"values":["tpch"]},"schema":{"values":["tiny"]},"table":{"values":["customer"]},"column":{"values":["*"]}},
 "policyItems":[{"users":["priya"],"accesses":[{"type":"select","isAllowed":true}],"delegateAdmin":false}]}
JSON
fi
q() { docker compose exec -T trino trino --user "$1" --output-format CSV --execute "SELECT name FROM tpch.tiny.customer LIMIT 1" 2>&1; }
priya_ok() { q priya | grep -q '"Customer#'; }
if retry 240 priya_ok; then pass "priya reads a row (policy downloaded by the plugin)"; else fail "priya still denied after 240 s: $(q priya | tail -2)"; fi
alice_out=$(q alice)
if echo "$alice_out" | grep -qi 'Access Denied'; then pass "alice is denied: $(echo "$alice_out" | grep -i 'Access Denied' | head -1)"; else fail "alice was not denied: $alice_out"; fi

echo "== M0.4 audit reaches files, OpenSearch and Ranger admin"
files_present() { docker compose exec -T trino sh -c 'ls /var/log/ranger/audit/*/*/*.log' >/dev/null 2>&1; }
if retry 120 files_present; then pass "plugin wrote audit files: $(docker compose exec -T trino sh -c 'ls /var/log/ranger/audit/*/*/*.log' | tr '\n' ' ')"; else fail "no audit files under /var/log/ranger/audit in the Trino container"; fi
os_has_alice() { curl -sS "$OPENSEARCH/ranger_audits/_count?q=reqUser:alice" 2>/dev/null | grep -Eq '"count":[1-9]'; }
if retry 180 os_has_alice; then
  pass "OpenSearch has alice's audit event: $(curl -sS "$OPENSEARCH/ranger_audits/_search?q=reqUser:alice&size=1&_source=reqUser,resource,result,policy,evtTime,cluster" | tr -d '\n' | cut -c1-300)"
else
  fail "no document with reqUser:alice in ranger_audits"
fi
if curl -sS "$OPENSEARCH/ranger_audits/_mapping" | grep -q '"yyyy-MM-dd HH:mm:ss.SSS'; then pass "index carries our template mapping"; else fail "index mapping is not ours (evtTime format missing)"; fi
admin_sees() { rj "$RANGER/service/assets/accessAudit?requestUser=alice&pageSize=5" | grep -Eq '"totalCount":\s*[1-9]|"vXAccessAudits":\s*\[\s*\{'; }
if retry 60 admin_sees; then pass "Ranger admin's audit screen lists alice's event"; else fail "Ranger admin audit API returns nothing for alice: $(rj "$RANGER/service/assets/accessAudit?requestUser=alice&pageSize=5" | cut -c1-300)"; fi

echo "== M0.5 OpenMetadata on the shared PostgreSQL and OpenSearch"
if curl -sS "$OM/api/v1/system/version" | grep -q '"version"'; then pass "OpenMetadata answers: $(curl -sS "$OM/api/v1/system/version" | cut -c1-120)"; else fail "OpenMetadata version endpoint not answering"; fi

echo "== M0.6 Keycloak realm import"
token=$(curl -sS -X POST "$KEYCLOAK/realms/data/protocol/openid-connect/token" -d client_id=conformance -d client_secret=conformance-dev-secret -d grant_type=password -d username=alice -d password=alice 2>/dev/null | python3 -c 'import sys,json; print(json.load(sys.stdin).get("access_token",""))' 2>/dev/null)
if [ -n "$token" ]; then
  payload=$(echo "$token" | cut -d. -f2 | tr '_-' '/+' | awk '{ l=length($0)%4; if (l==2) print $0"=="; else if (l==3) print $0"="; else print $0 }' | base64 -d 2>/dev/null)
  if echo "$payload" | grep -q '"groups":\[[^]]*"analysts"'; then pass "alice's token carries groups claim with analysts"; else fail "token has no analysts group: $payload"; fi
else
  fail "could not obtain a token for alice through the conformance client"
fi

echo
if [ "$fails" -eq 0 ]; then echo "M0 smoke: all checks passed"; else echo "M0 smoke: $fails check(s) failed"; fi
exit "$fails"
