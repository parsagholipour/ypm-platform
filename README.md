# ypm-platform

Everything that runs in the YPM k3s cluster, applied by Argo CD from `main`.
Manual changes in the cluster are reverted; change things here, through a pull request.

- `bootstrap/root.yaml`: the only object applied by hand; it renders `platform/applications`.
- `platform/`: cluster add-ons (one directory each) and the edge (Caddy).
- `charts/service/`: the chart every YPM app is deployed with.
- `apps/<name>/values.yaml`: per-app settings. Release images live on each app
  repository's `release` branch (`image.yaml`), written by its Deploy workflow.

The runbook (architecture, operations, recovery) is `docs/k3s/README.md` in the
ypm-export folder; the AWS side is Terraform in `ypm-export-backend/infra` (`k3s.tf`).
