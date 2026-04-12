# ~/Workspace/ops/scripts/docker-net-audit.sh
#!/bin/bash
# Auditoría completa de red Docker — uso: sudo bash docker-net-audit.sh

echo "════════════════════════════════════════"
echo "  MAPA VETH → CONTENEDOR → RED DOCKER  "
echo "════════════════════════════════════════"

for cid in $(docker ps -q); do
    name=$(docker inspect -f "{{.Name}}" "$cid" | tr -d "/")
    pid=$(docker inspect -f "{{.State.Pid}}" "$cid")
    echo "── $name ──"
    while IFS= read -r line; do
        ethname=$(grep -oP  "eth\d+"   <<< "$line")
        peer_idx=$(grep -oP "@if\K\d+" <<< "$line")
        host_veth=$(ip -o link \
                    | awk -v idx="$peer_idx" \
                      '$1 == idx":" {print $2}' \
                    | cut -d@ -f1)
        master=$(ip link show "${host_veth}" 2>/dev/null \
                 | grep -oP "master \K\S+")
        net_name=""
        if [[ -n "$master" ]]; then
            net_id="${master#br-}"
            net_name=$(docker network ls --no-trunc \
                       --format "{{.ID}} {{.Name}}" \
                       | grep "^${net_id}" | awk '{print $2}')
        fi
        echo "  ${ethname} → ${host_veth} → ${master} [${net_name}]"
    done < <(nsenter -t "$pid" -n ip link 2>/dev/null \
             | grep -E "^[0-9]+: eth")
done

echo ""
echo "════════════════════════════════════════"
echo "  REDES SIN CONTENEDORES ACTIVOS       "
echo "════════════════════════════════════════"
docker network ls --format "{{.ID}} {{.Name}}" \
  | while read id name; do
    count=$(docker network inspect "$id" \
            --format '{{len .Containers}}')
    [[ "$count" -eq 0 ]] && \
    [[ "$name" != "bridge" ]] && \
    [[ "$name" != "host" ]] && \
    [[ "$name" != "none" ]] && \
    echo "  ⚠  $name ($id) — sin contenedores"
done
