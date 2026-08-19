# deploying NGINX controller 
resource "helm_release" "nginx_ingress" {
    name = "ingress-nginx"
    repository = "https://kubernetes.github.io/ingress-nginx"
    chart = "ingress-nginx"
    namespace = "ingress-nginx"
    create_namespace = true
    version = "4.10.1"

    values = [
    <<-EOT
    controller:
      # using HPA to scale under load
      autoscaling:
        enabled: true
        minReplicas: 2
        maxReplicas: 3
        targetCPUUtilizationPercentage: 70
        targetMemoryUtilizationPercentage: 80
      
      # resource limits
      resources:
        requests:
            cpu: 100m
            memory: 256Mi
        limits:
            cpu: 1000m
            memory: 1024Mi

      nodeSelector:
        "karpenter.sh/nodepool": "nodepool-aws-karp"
        "karpenter.sh/capacity-type": "on-demand"
        
      # pod disruption budget
      podDisruptionBudget:
        enabled: true
        minAvailable: 1

      service:
        enableHttp: "true"
        enableHttps: "false"
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-type: "external"
          service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "ip"
          service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
          service.beta.kubernetes.io/aws-load-balancer-subnets: "${join(", ", var.public_subnet_ids)}"
    EOT
  ]
}