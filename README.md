# Okta Identity Lifecycle & REST API Lab

A laboratory implementation and automation toolkit for Okta Workforce Identity Cloud. Built to benchmark Okta's identity primitives, dynamic group rules, OIDC application assignment scoping, and REST API lifecycle state transitions against Microsoft Entra ID / Microsoft Graph workflows.

## Architecture & Features

- **Dynamic Group Rule Scoping:** Evaluates profile attributes via Okta Expression Language to automate security group assignments dynamically without manual directory management.
- **Inherited App Entitlements:** Configures OIDC Web Application integrations scoped directly to dynamic groups, demonstrating RBAC inheritance (`scope: GROUP`).
- **Okta Identity State Machine:** Programmatically navigates Okta user states:
  - `PROVISIONED` $\rightarrow$ User staged out-of-band without active app or group rule evaluation.
  - `ACTIVE` $\rightarrow$ Live credentials established; triggers dynamic rule evaluation and app scoping.
  - `DEPROVISIONED` $\rightarrow$ Atomic lifecycle offboarding via `POST /api/v1/users/{id}/lifecycle/deactivate`.
- **PowerShell 7 REST Automation:** Interacts directly with Okta `/api/v1` endpoints using native `Invoke-RestMethod` and administrative `SSWS` tokens without third-party module dependencies.

## Entra ID vs. Okta Operational Comparison

| Architecture Area | Microsoft Entra ID | Okta Workforce Identity |
| :--- | :--- | :--- |
| **Dynamic Scoping** | Evaluated on the group object (`user.department -eq "Eng"`) | Decoupled **Group Rules** engine using Okta Expression Language |
| **App Management** | Split between App Registrations and Enterprise Apps | Unified under **Applications** (OIDC client + assignment policies) |
| **Deprovisioning** | Multi-call Graph pipeline (revoke tokens, disable, clear licenses) | Single atomic call to `/lifecycle/deactivate` |

## Usage

```powershell
# Set token in environment
$env:OKTA_API_TOKEN = "your-okta-api-token"

# Run automated discovery and entitlement verification
.\Okta-LifecycleAutomation.ps1 -OktaDomain "[https://your-tenant.okta.com](https://your-tenant.okta.com)"