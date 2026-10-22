# GKE on Terraform — modular, private, multi-environment

Standard-mode GKE clusters built from three reusable modules, wired together
per environment. Each module does one thing so it can be tested, reused, and
reasoned about on its own.

## Layout

```
modules/
  vpc/         VPC-native network: custom subnet with pod/service secondary
               ranges, Cloud NAT for private-node egress.
  gke/         The GKE cluster itself: private nodes, Workload Identity,
               VPC-native networking, a dedicated least-privilege node SA.
               No node pool is created here (the default pool is removed).
  node-pool/   One node pool per instantiation — call it once per pool you
               want (default pool, spot pool, GPU pool, etc.).

environments/
  dev/         Public-but-restricted endpoint, Spot nodes, deletion
               protection off — optimized for low cost and easy teardown.
  prod/        Fully private endpoint, on-demand default pool + a
               taint-guarded Spot pool for batch work, deletion protection
               on, STABLE release channel.
```

Each environment directory is a separate Terraform root/state — `dev` and
`prod` are isolated from each other and can be applied independently.

## Best practices baked in

- **VPC-native (alias IP) cluster** with dedicated secondary ranges for pods
  and services — required for most GKE features going forward.
- **Private nodes** (no public IPs) with **Cloud NAT** for egress; the
  control plane endpoint is IP-restricted via `master_authorized_networks`
  and can be made fully private (`enable_private_endpoint`).
- **Workload Identity** enabled on the cluster and `GKE_METADATA` mode on
  every node pool, so pods authenticate to GCP APIs via IAM bindings instead
  of broad node-level credentials.
- **Dedicated node service account** with only the roles nodes actually
  need (logging, monitoring, Artifact Registry read) — not the default
  Compute Engine SA, which is project-editor-equivalent.
- **Node pools decoupled from the cluster** so you can add/remove/resize
  pools (including Spot pools with taints) without touching the cluster
  resource.
- **Shielded VMs**, node auto-repair/auto-upgrade, cluster autoscaling
  (per-pool min/max), Managed Prometheus, VPA, and a release channel per
  environment (`REGULAR` for dev, `STABLE` for prod).
- **Remote state** (GCS backend) and pinned provider versions so applies are
  reproducible across a team/CI.
- **`deletion_protection`** on by default, disabled only in `dev`.

## Prerequisites

1. A GCP project with these APIs enabled:
   `container.googleapis.com`, `compute.googleapis.com`,
   `iam.googleapis.com`, `artifactregistry.googleapis.com`.
2. A GCS bucket for Terraform state (versioning on), created once out of
   band — see the comment in each `environments/*/versions.tf`.
3. Terraform >= 1.5, and `gcloud` authenticated
   (`gcloud auth application-default login`) or a service account key with
   permission to create the above resources.

## Usage

```bash
cd environments/dev   # or environments/prod
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: project_id, master_authorized_networks, etc.
# edit versions.tf: replace the backend bucket name

terraform init
terraform plan
terraform apply
```

Get `kubectl` access (dev — public-but-restricted endpoint):

```bash
gcloud container clusters get-credentials dev-gke --region <region> --project <project_id>
```

Prod's endpoint is fully private, so run the equivalent command with
`--internal-ip` from inside the VPC (VPN, Interconnect, or a bastion/CI
runner that lives in the VPC).

## Extending

- **Add a node pool**: add another `module "..." { source = "../../modules/node-pool" ... }`
  block in an environment's `main.tf` (see `spot_node_pool` in `prod` for an
  example with a taint).
- **Add an environment**: copy `environments/dev`, change the `prefix` in
  its `versions.tf` backend block and the CIDRs in `variables.tf` so they
  don't overlap other environments' VPCs.
- **GPU pools / Autopilot**: the `node-pool` module can take `guest_accelerator`
  blocks if you need GPUs; if you'd rather not manage node pools at all,
  the same `vpc` module can back a `google_container_cluster` with
  `enable_autopilot = true` instead of the `gke`/`node-pool` pair here.
