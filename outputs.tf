output "enterprise_app_display_name" {
  description = "Name of the federated Enterprise Application"
  value       = azuread_application.enterprise_sso_app.display_name
}

output "application_client_id" {
  description = "Application (Client) ID for OIDC/SAML federation"
  value       = azuread_application.enterprise_sso_app.client_id
}

output "service_principal_object_id" {
  description = "Enterprise Application (Service Principal) Object ID"
  value       = azuread_service_principal.enterprise_sso_sp.object_id
}

output "saml_signing_cert_thumbprint" {
  description = "Thumbprint of the generated SAML 2.0 Token Signing Certificate"
  value       = azuread_service_principal_token_signing_certificate.saml_signing_cert.thumbprint
}

output "assigned_rbac_group_id" {
  description = "Object ID of the synced SG-Sales group granted SSO access"
  value       = data.azuread_group.sg_sales.object_id
}
