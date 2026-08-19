# argocd
resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  create_namespace = true
  version          = "7.3.11"

  # Essential: Ensures Terraform waits for all Argo components to be healthy
  wait             = true

  values = [
    <<-EOT
    # ==========================================
    # 1. Global Scheduling
    # ==========================================
    #global:
      # Enterprise Rule: Never run ArgoCD on Spot instances. 
      # It maintains a heavy Git cache; Spot interruptions will throttle your GitHub API limits.
      #nodeSelector:
       # "karpenter.sh/capacity-type": "on-demand"

    # ==========================================
    # 2. High Availability (HA) Redis
    # ==========================================
    # Replaces the single Redis pod with a 3-node HAProxy + Redis architecture
    #redis-ha:
     # enabled: true

    # ==========================================
    # 3. Application Controller
    # ==========================================
    controller:
      replicas: 1 # Only scales if you shard across 1000+ apps
      resources:
        requests:
          cpu: 250m
          memory: 512Mi
        limits:
          cpu: 1000m
          memory: 2Gi

    # ==========================================
    # 4. ArgoCD API / UI Server
    # ==========================================
    server:
      autoscaling:
        enabled: true
        minReplicas: 2
        maxReplicas: 3
      
      # tells argocd to disable native TLS termination and serve via HTTP instead of HTTPS
      extraArgs:
        - --insecure
      
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 500m
          memory: 512Mi

      # Enterprise Ingress: Hooking it directly into your NGINX Controller
      ingress:
        enabled: true
        ingressClassName: "nginx" # or "alb" if using AWS Load Balancer Controller
        hosts:
          - argocd.yourcompany.com

    # ==========================================
    # 5. Repo Server (Heavy Workload)
    # ==========================================
    repoServer:
      autoscaling:
        enabled: true
        minReplicas: 2
        maxReplicas: 3
      
      # The most critical limits in the whole chart. Prevents Git from crashing the cluster.
      resources:
        requests:
          cpu: 250m
          memory: 512Mi
        limits:
          cpu: 1000m
          memory: 2Gi

    # ==========================================
    # 6. Enterprise Security & SSO (Dex)
    # ==========================================
    #configs:
     # cm:
      #  url: "https://argocd.yourcompany.com"
        
        # Enterprise Standard: Disable the local 'admin' account completely
       # admin.enabled: "false"

        # Example: Connecting ArgoCD to GitHub Teams for SSO login
        #dex.config: |
         # connectors:
         # - type: github
         #   id: github
         #   name: GitHub
         #   config:
         #     clientID: $dex.github.clientID
         #     clientSecret: $dex.github.clientSecret
         #     orgs:
         #     - name: your-github-org
      
      # Role Based Access Control (RBAC) based on SSO Groups
     # rbac:
     #   policy.default: "role:readonly"
     #   policy.csv: |
     #     g, your-github-org:devops-team, role:admin
     #     g, your-github-org:developers, role:readonly
    EOT
  ]
}