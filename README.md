# Laptop Outlet — GCP Infrastructure (Terraform)

Production infrastructure for **laptopoutlet.co.uk** on Google Cloud Platform.
Load balancer IP: **`8.232.30.182`** · Project: `nth-infusion-169309` · Region: `europe-west2`

---

## Architecture Overview

```
Internet
   │
   ▼
Cloud Load Balancer (8.232.30.182)
   │   HTTPS (443) — Google-managed SSL cert
   │   HTTP (80)  → redirects to HTTPS
   │
   ├── www.laptopoutlet.co.uk              → lo-frontend-prod MIG  (Next.js, port 3000)
   │     /api, /api/*                      → lo-backend-prod MIG
   ├── backend.laptopoutlet.co.uk          → lo-backend-prod MIG   (Magento/nginx, port 443)
   ├── static-media.laptopoutlet.co.uk     ┐
   ├── content.laptopoutlet.co.uk          ├─ lo-redis-opensearch-prod VM (nginx, port 80)
   ├── content-media.laptopoutlet.co.uk    ┘
   ├── connector.laptopoutlet.co.uk        → lo-connector-prod VM  (port 443)
   └── qa.laptopoutlet.co.uk               → lo-frontend-prod MIG  (QA testing only)
```

### Virtual Machines

| VM / MIG | Zone | Internal IP | Role |
|---|---|---|---|
| `lo-frontend-prod` MIG (2 instances) | europe-west2-b/c | 10.210.102.5–6 | Next.js frontend (pm2) |
| `lo-backend-prod` MIG (2 instances) | europe-west2-b/c | 10.210.102.9–10 | Magento + nginx |
| `lo-redis-opensearch-prod` | europe-west2-a | **10.210.102.20** (static) | Redis · Elasticsearch · nginx · NFS |
| `lo-connector-prod` | europe-west2-b | 10.210.102.3 | Connector app |
| `lo-cron-prod` | europe-west2-b | 10.210.102.4 | Cron jobs |

**Network:** VPC `lo-prod` · Subnet `10.210.102.0/24` · Cloud NAT egress IP: `34.142.34.46`
All VMs are private (no public IPs). SSH via IAP tunnel.

### Services on `lo-redis-opensearch-prod` (media VM)

| Service | Port | Notes |
|---|---|---|
| Redis | 6379 | Data at `/var/lib/redis` (dedicated disk) |
| Elasticsearch | 9200 | Service name: `elasticsearch` |
| nginx | 80/443 | Static media serving |
| NFS server | 2049 | Exports `/static` → backend and cron VMs |

### Data Disks (Media VM — all have `prevent_destroy = true`)

| Terraform Name | Mount Point | Size | Type |
|---|---|---|---|
| `lo-redis-elastic-prod` | `/var/lib/redis` | 100 GB | pd-standard |
| `lo-static-prod` | `/static` | 100 GB | pd-ssd |
| `lo-media-cache-prod` | `/var/temp-media` | 100 GB | pd-standard |
| `lo-redis-exclusive-prod` | `/var/lib/keydb` | 70 GB | pd-balanced |
| `lo-swap-prod` | `/mnt/disks/swap` | 20 GB | pd-ssd |

### Cloud SQL Databases

| Instance | Public IP | Purpose |
|---|---|---|
| `laptopoutletdatabase-server` | 34.142.32.18 | Main Magento DB |
| `lo-new-database-server` | 34.89.59.5 | New DB (connector etc.) |

Both have NAT egress IP `34.142.34.46` in their authorised networks.

---

## Prerequisites

### Tools Required
- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- WSL Ubuntu (on Windows) — all commands below run in WSL

### Authenticate with GCP

Two separate tokens are needed — they are **independent** and both expire after ~12 hours:

```bash
# 1. gcloud CLI (for running gcloud commands)
gcloud auth login --login-config=login.json

# 2. Application Default Credentials — used by Terraform
gcloud auth application-default login --login-config=login.json
```

`login.json` is the Workforce Identity Federation config file — ask an admin for it.

**Signs of expired tokens:**
- `terraform plan/apply` fails with `oauth2: token expired` or `invalid_grant` → re-run command 2
- `gcloud` commands fail with auth errors → re-run command 1

### Initialise Terraform

```bash
cd '/mnt/c/Retail Direct/Repositories/Laptopoulet-Infra-Terraform'
terraform init
```

---

## Deploying the Infrastructure

```bash
cd '/mnt/c/Retail Direct/Repositories/Laptopoulet-Infra-Terraform'

# Review changes first
terraform plan

# Deploy (LB backend services can take 5–15 min on first run)
terraform apply
```

### Post-Deploy Manual Steps

These items are **not managed by Terraform** and must be run once after a fresh deploy:

#### Step 1 — Internal Firewall Rule

Without this rule, VMs cannot reach Redis (port 6379), NFS (2049), or each other.

```bash
gcloud compute firewall-rules create lo-prod-allow-internal \
  --project=nth-infusion-169309 \
  --network=lo-prod \
  --direction=INGRESS \
  --priority=1000 \
  --source-ranges=10.208.0.0/14 \
  --action=allow \
  --rules='tcp:0-65535,udp:0-65535,icmp'
```

#### Step 2 — Cloud SQL Authorised Networks

Add the NAT egress IP so all VMs can reach Cloud SQL:

```bash
gcloud sql instances patch laptopoutletdatabase-server \
  --project=nth-infusion-169309 \
  --authorized-networks='35.214.58.71/32,182.191.115.28/32,182.180.165.0/24,182.176.83.170/32,34.142.34.46/32'

gcloud sql instances patch lo-new-database-server \
  --project=nth-infusion-169309 \
  --authorized-networks='35.214.58.71/32,35.207.116.159/32,182.180.165.192/32,119.153.108.65/32,182.191.115.28/32,182.176.83.170/32,34.142.34.46/32'
```

#### Step 3 — Fix Media VM fstab

The boot image has a malformed `/static` mount entry. SSH in and fix:

```bash
gcloud compute ssh lo-redis-opensearch-prod --zone=europe-west2-a \
  --project=nth-infusion-169309 --tunnel-through-iap

# On the VM — run these commands:
sudo grep -v '[[:space:]]/static[[:space:]]' /etc/fstab > /tmp/fstab.new
echo "UUID=18b9a0fd-4b85-4d1c-99b3-0643b43944bc /static ext4 discard,defaults,nofail 0 2" \
  >> /tmp/fstab.new
sudo cp /tmp/fstab.new /etc/fstab
sudo mount /static
sudo exportfs -ra
sudo systemctl start nfs-server
```

#### Step 4 — Fix Redis AOF if It Fails to Start

Check logs first: `sudo tail -20 /var/log/redis/redis-server.log`

If you see `Bad file format reading the append only file`:

```bash
# On lo-redis-opensearch-prod:
sudo /etc/init.d/redis-server stop

MANIFEST=$(ls /var/lib/redis/appendonlydir/*.manifest 2>/dev/null | head -1)
sudo grep -v 'incr.aof' "$MANIFEST" > /tmp/manifest.new
sudo cp /tmp/manifest.new "$MANIFEST"
sudo chown redis:redis "$MANIFEST"

# Rename the corrupted increment file
sudo mv /var/lib/redis/appendonlydir/*.incr.aof \
        /var/lib/redis/appendonlydir/corrupted.aof.bak 2>/dev/null || true

sudo /etc/init.d/redis-server start
redis-cli PING   # should return PONG
```

#### Step 5 — Update NFS Exports

```bash
# On lo-redis-opensearch-prod:
sudo tee /etc/exports > /dev/null << 'EOF'
/static 10.154.0.0/16(rw,sync,no_subtree_check,all_squash,anonuid=65534,anongid=65534,insecure) 10.208.0.0/14(rw,sync,no_subtree_check,all_squash,anonuid=65534,anongid=65534,insecure)
EOF
sudo exportfs -ra
```

#### Step 6 — Restore QA SSL Certificate

```bash
gcloud compute ssl-certificates create lo-prod-lb2-cert-qa \
  --domains=qa.laptopoutlet.co.uk \
  --global --project=nth-infusion-169309

gcloud compute target-https-proxies update lo-prod-lb2-https-proxy \
  --global --project=nth-infusion-169309 \
  --ssl-certificates=lo-prod-lb2-cert,lo-prod-lb2-cert-qa
```

---

## Checking Application Health

### Quick Health Check (All Backends)

```bash
for bes in lo-prod-lb2-lo-frontend-prod-bes lo-prod-lb2-lo-backend-prod-bes \
           lo-prod-lb2-media-bes lo-prod-lb2-connector-bes; do
  echo -n "$bes: "
  gcloud compute backend-services get-health $bes --global \
    --project=nth-infusion-169309 \
    --format="value(status.healthStatus[].healthState)" | tr '\n' ' '
  echo
done
```

Expected output when everything is healthy:
```
lo-prod-lb2-lo-frontend-prod-bes: HEALTHY HEALTHY
lo-prod-lb2-lo-backend-prod-bes: HEALTHY HEALTHY
lo-prod-lb2-media-bes: HEALTHY
lo-prod-lb2-connector-bes: HEALTHY
```

### Test LB is Responding

```bash
# Should return 301 (HTTP → HTTPS redirect)
curl -s -o /dev/null -w '%{http_code}' http://8.232.30.182/

# Should return 200 (Next.js homepage)
curl -s -o /dev/null -w '%{http_code}' \
  http://8.232.30.182/ -H 'Host: www.laptopoutlet.co.uk'
```

### Check Services on Media VM

```bash
gcloud compute ssh lo-redis-opensearch-prod --zone=europe-west2-a \
  --project=nth-infusion-169309 --tunnel-through-iap

# On the VM:
for svc in nginx redis-server nfs-server elasticsearch; do
  echo "$svc: $(sudo systemctl is-active $svc 2>/dev/null)"
done

sudo redis-cli PING          # should print: PONG
sudo mountpoint /static      # should print: /static is a mountpoint
sudo exportfs -v             # shows active NFS exports
```

### SSL Certificate Status

```bash
# Main production cert (6 domains)
gcloud compute ssl-certificates describe lo-prod-lb2-cert \
  --global --project=nth-infusion-169309 \
  --format="yaml(managed.status, managed.domainStatus)"

# QA cert
gcloud compute ssl-certificates describe lo-prod-lb2-cert-qa \
  --global --project=nth-infusion-169309 \
  --format="yaml(managed.status, managed.domainStatus)"
```

Status is `PROVISIONING` until DNS points to `8.232.30.182`.
After DNS cutover: cert becomes `ACTIVE` within 5–15 minutes.

---

## Testing on a QA Subdomain (Before DNS Cutover)

A separate SSL cert (`lo-prod-lb2-cert-qa`) covers `qa.laptopoutlet.co.uk`.
It routes to the same frontend and backend as production.

### Why `qa.laptopoutlet.co.uk` instead of editing hosts file?

The production domains (`www.laptopoutlet.co.uk` etc.) have **HSTS** enabled — browsers permanently force HTTPS on them. HTTPS requires a valid SSL cert, but the cert won't provision until real DNS points to the LB. A fresh `qa.` subdomain has no HSTS history, so it works cleanly.

### Steps

**1. Add this DNS record** (in your DNS provider):
```
qa.laptopoutlet.co.uk    A    8.232.30.182    TTL: 60
```

**2. Wait for the cert to provision** (~5–15 min after DNS propagates):
```bash
watch -n 30 'gcloud compute ssl-certificates describe lo-prod-lb2-cert-qa \
  --global --project=nth-infusion-169309 \
  --format="value(managed.status)"'
# Wait until it prints: ACTIVE
```

**3. Open in browser:**
```
https://qa.laptopoutlet.co.uk          → frontend (Next.js)
https://qa.laptopoutlet.co.uk/api/*    → backend (Magento API)
```

---

## Production DNS Cutover

After QA testing passes, update DNS for all production domains:

```
www.laptopoutlet.co.uk              A    8.232.30.182
backend.laptopoutlet.co.uk          A    8.232.30.182
static-media.laptopoutlet.co.uk     A    8.232.30.182
content.laptopoutlet.co.uk          A    8.232.30.182
content-media.laptopoutlet.co.uk    A    8.232.30.182
connector.laptopoutlet.co.uk        A    8.232.30.182
```

The Google-managed cert (`lo-prod-lb2-cert`) will provision automatically within 15 minutes of DNS propagation. No other action needed.

---

## `terraform destroy` + `terraform apply` — What Survives?

> **Do not run `terraform destroy` without reading this section.**

### What Terraform recreates correctly

- VPC, subnets, all Terraform-managed firewall rules
- Cloud NAT and the static egress IP (`34.142.34.46`)
- Instance templates and MIGs (frontend, backend) with startup scripts
- Standalone VMs (media, cron, connector) booted from cloned images
- Load balancer (backend services, URL map, SSL cert, forwarding rules)
- Data disk resources (but `prevent_destroy = true` means `destroy` will **fail** unless you manually override)

### What does NOT survive (requires manual steps after re-apply)

| What is lost | Reason | Recovery |
|---|---|---|
| `lo-prod-allow-internal` firewall rule | Created with `gcloud`, not Terraform | Post-deploy Step 1 |
| Cloud SQL authorised networks | Set with `gcloud`, not Terraform | Post-deploy Step 2 |
| Media VM `/static` fstab fix | Applied to running disk; image still has old malformed entry | Post-deploy Step 3 |
| Redis AOF fix | Applied to running disk | Post-deploy Step 4 (if Redis fails) |
| NFS exports update (`10.208.0.0/14`) | Applied to running `/etc/exports` | Post-deploy Step 5 |
| QA SSL cert `lo-prod-lb2-cert-qa` | Created with `gcloud`, not Terraform | Post-deploy Step 6 |

### Data disks are protected from accidental deletion

The 5 media VM data disks all have `prevent_destroy = true`:
```
lo-redis-elastic-prod, lo-static-prod, lo-media-cache-prod,
lo-redis-exclusive-prod, lo-swap-prod
```
`terraform destroy` will **error out** when it reaches these disks.
This is intentional — they hold Redis persistence data and static media files.
To destroy them you must first remove the `lifecycle` block or run `terraform state rm`.

---

## SSH Access

All VMs are private — no public IPs. Use IAP tunnelling:

```bash
gcloud compute ssh <instance-name> \
  --zone=<zone> \
  --project=nth-infusion-169309 \
  --tunnel-through-iap
```

| Instance | Zone |
|---|---|
| `lo-redis-opensearch-prod` | europe-west2-a |
| `lo-frontend-prod-*` (list with `gcloud compute instances list`) | europe-west2-b or europe-west2-c |
| `lo-backend-prod-*` | europe-west2-b or europe-west2-c |
| `lo-connector-prod` | europe-west2-b |
| `lo-cron-prod` | europe-west2-b |
