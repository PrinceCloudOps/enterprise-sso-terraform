data "azuread_client_config" "current" {}

# Reference existing synced AD group from Lab 5 (SG-Sales)
data "azuread_group" "sg_sales" {
  display_name     = var.sales_group_name
  security_enabled = true
}

# Generate deterministic UUIDs for custom App Roles
resource "random_uuid" "sales_exec_role_id" {}
resource "random_uuid" "crm_auditor_role_id" {}

# 1. Application Registration (Global Blueprint, App Roles & SAML/OIDC Claims)
resource "azuread_application" "enterprise_sso_app" {
  display_name     = var.app_display_name
  sign_in_audience = "AzureADMyOrg"
  owners           = [data.azuread_client_config.current.object_id]

  # SAML 2.0 Identifier (Entity ID)
  identifier_uris = ["https://blakecloudsolutions.onmicrosoft.com/Salesforce-Enterprise-CRM-SSO"]

  # SAML Assertion Consumer Service (ACS) & OIDC Redirect URIs
  web {
    redirect_uris = ["https://samltoolkit.azurewebsites.net/SAML/Consume"]
    logout_url    = "https://samltoolkit.azurewebsites.net/SAML/Logout"

    implicit_grant {
      id_token_issuance_enabled     = true
      access_token_issuance_enabled = false
    }
  }

  # Emit Security Group claims in SAML/OIDC tokens
  group_membership_claims = ["SecurityGroup"]

  # Custom RBAC App Roles passed inside the SAML/OIDC Role Claim
  app_role {
    allowed_member_types = ["User", "Application"]
    description          = "Full Account Executive access to Salesforce CRM pipelines"
    display_name         = "Sales Account Executive"
    enabled              = true
    id                   = random_uuid.sales_exec_role_id.result
    value                = "Sales.AccountExecutive"
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "Read-only auditing access for compliance review"
    display_name         = "CRM Compliance Auditor"
    enabled              = true
    id                   = random_uuid.crm_auditor_role_id.result
    value                = "CRM.Auditor"
  }

  # Configure SAML 2.0 and OIDC Token Claims
  optional_claims {
    saml2_token {
      name      = "upn"
      essential = true
    }
    saml2_token {
      name      = "email"
      essential = false
    }
    saml2_token {
      name      = "given_name"
      essential = false
    }
    saml2_token {
      name      = "family_name"
      essential = false
    }
    id_token {
      name      = "upn"
      essential = true
    }
    id_token {
      name      = "email"
      essential = false
    }
  }
}

# 2. Enterprise Application / Service Principal (Tenant Enforcement & SAML Mode)
resource "azuread_service_principal" "enterprise_sso_sp" {
  client_id                    = azuread_application.enterprise_sso_app.client_id
  app_role_assignment_required = true # Zero-Trust: Block anyone not explicitly assigned via RBAC group
  preferred_single_sign_on_mode = "saml"
  owners                       = [data.azuread_client_config.current.object_id]

  feature_tags {
    enterprise            = true
    custom_single_sign_on = true
  }

  saml_single_sign_on {
    relay_state = "/dashboard/sales"
  }
}

# 3. SAML Token Signing Certificate (3-Year Validity)
resource "time_offset" "cert_expiry" {
  offset_years = 3
}

resource "azuread_service_principal_token_signing_certificate" "saml_signing_cert" {
  service_principal_id = azuread_service_principal.enterprise_sso_sp.id
  display_name         = "CN=BlakeCloudSolutions-SAML-Signing"
  end_date             = time_offset.cert_expiry.rfc3339
}

# 4. RBAC Group Mapping: Assign synced 'SG-Sales' AD Group to 'Sales.AccountExecutive' Role
resource "azuread_app_role_assignment" "assign_sg_sales_to_crm" {
  app_role_id         = random_uuid.sales_exec_role_id.result
  principal_object_id = data.azuread_group.sg_sales.object_id
  resource_object_id  = azuread_service_principal.enterprise_sso_sp.object_id
}
