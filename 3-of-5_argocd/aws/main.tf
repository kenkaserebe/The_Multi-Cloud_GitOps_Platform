# The_Multi-Cloud_GitOps_Platform/3-of-5_argocd/aws/main.tf

# Install ArgoCD using Helm
resource "helm_release" "argocd" {
  name = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart = "argo-cd"
  namespace = "argocd"
  create_namespace = true
  version = "5.51.4"

  values = [
    <<-YAML
    server:
        service:
            type: LoadBalancer
        configs:
            params:
                server.insecure: true
    YAML
  ]
  depends_on = [data.aws_eks_cluster.this, data.aws_eks_cluster_auth.this]
}


# Password retrieval
resource "null_resource" "get_argocd_password" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = <<-EOT
        echo "Waiting for ArgoCD secret to be created..."
        sleep 30 # Give Kubernetes a moment to create the secret
        kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d > argocd-password.txt
        echo "Password saved to argocd-password.txt"
    EOT
  }

  # Triggers to re-run this provisioner if the Helm release is updated
  triggers = {
    helm_release = helm_release.argocd.id
  }
}

# WHAT IF THE BELOW DOES NOT WORK.....??????
# DO THIS ON YOUR CLI
# 1. aws eks update-kubeconfig --region eu-west-2 --name ken-eks-cluster
# 2. kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
# 3. kubectl get secret -n argocd argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d