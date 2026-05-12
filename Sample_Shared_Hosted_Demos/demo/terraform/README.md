# Demo Infrastructure - Shared Hosted Access

This directory contains the Terraform configuration to add users to the shared demo group and provide project access. 

---

## 1. Mandatory Variables ⚠️
**DO NOT REMOVE** these from `variables.tf`:
`project_id`, `project_name`, `project_number`, `gcp_account_name`, `deployment_service_account_name`, `org_id`, `data_location`, `secret_stored_project`.

---

## 2. Shared Access Logic:
The **`main.tf`** file in this directory:
1.  **Impersonates** a domain-wide delegation user.
2.  **Adds the user** (`gcp_account_name`) to the required Google Workspace group.
3.  **Deletes the local project** created by the Click-To-Deploy backend, as only shared group access is required for this demo.

---

## 3. Local Testing:

1.  **Initialize**: `terraform init`
2.  **Plan**: `terraform plan`
3.  **Apply**: `terraform apply`

> [!NOTE]
> Ensure prerequisites in `../org_policy/` are met before testing.
