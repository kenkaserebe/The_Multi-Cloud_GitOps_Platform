# The_Multi-Cloud_GitOps_Platform/3-of-5_argocd/azure/outputs.tf

# Output the ArgoCD server URL (if LoadBalancer is used)
output "argocd_server_command" {
  description = "Run this command to get the ArgoCD server LoadBalancer URL"
  value       = "kubectl get svc argocd-server -n argocd -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'"
  depends_on  = [helm_release.argocd]
}


#Output the initial admin password created by the null_resource
output "argocd_initial_secret" {
  description = "Initial ArgoCD admin password (saved locally to argocd-password.txt)"
  value       = fileexists("${path.module}/argocd-password.txt") ? file("${path.module}/argocd-password.txt") : "Password not yet available. Run 'cat argocd-password.txt' after apply finishes."
  depends_on  = [null_resource.get_argocd_password]
}