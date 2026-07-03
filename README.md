# home-lab-gitops

A gitops repo for my home lab. Using k3s on an old mini pc I got for free.

## Bootstrapping the Cluster

Once bootstrapped, all cluster state is managed by Argo CD from this repo. 
Only two manual steps are needed to get from a bare k3s cluster to a fully 
self-managing Argo CD instance.

### Prerequisites

- A running k3s cluster with `kubectl` access configured
- `kustomize` (or a `kubectl` version with built-in kustomize support)

### Step 1: Install Argo CD

Apply the base Argo CD manifests manually

```bash
kubectl apply -k install-manifests/argocd
```

Wait for the Argo CD pods to come up:

```bash
kubectl get pods -n argocd -w
```

### Step 2: Apply the root Application

This points Argo CD at `platform/argocd-config`, which defines all
Applications and AppProjects Argo CD will manage going forward.

```bash
kubectl apply -f bootstrap/root-app.yaml
```

### Step 3: Verify

Check that `root-app` has synced and created the child Applications:

```bash
kubectl get applications -n argocd
```

You should see `root-app`, `argocd-app`, and `helloworld`. From this point
on:

- Argo CD reconciles all cluster state from Git automatically
  (`selfHeal: true`, `prune: true`)
- Upgrading Argo CD itself is done by bumping the `ref=` in
  `install-manifests/argocd/kustomization.yaml` and committing — no more
  manual `kubectl apply` for Argo CD going forward
- New workloads are added by creating an Application manifest under
  `platform/argocd-config/applications/` and an accompanying
  directory under `apps/`

### Repo Layout

| Path                               | Purpose                                                              |
|------------------------------------|------------------------------------------------------------------------|
| `install-manifests/argocd`         | Raw Argo CD install manifests (applied manually once, then Argo-managed) |
| `bootstrap/root-app.yaml`          | The seed Application, applied manually once                          |
| `platform/argocd-config`           | Root of the Argo-managed app tree (Applications, AppProjects)        |
| `apps/`                            | Workload application manifests                                       |