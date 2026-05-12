# Demo Infrastructure - Terraform Deployment

This directory contains the core Terraform configuration for the demo resources. It is organized into a modular structure under `terraform-modules/` for clarity and reusability.

---

## 1. Variable Management Strategy 📋

The `variables.tf` file is divided into two sections. Understanding the difference is critical for a successful deployment.

### ⚠️ MANDATORY: DO NOT REMOVE
These variables are populated automatically by the **Click-To-Deploy (CTD)** infrastructure or are essential for identity and access management. **Removing these will cause deployment failures.**

*   `project_id` / `project_name` / `project_number`: Core project identifiers.
*   `gcp_account_name`: Used to assign permissions to the user performing the demo.
*   `deployment_service_account_name`: The identity used by the runner.
*   `org_id`: Required for organizational-level resource mapping.
*   `data_location`: Location of source data file.
*   `secret_stored_project`: Project for secret access.

### 💡 OPTIONAL: RESOURCE SPECIFIC
These variables define the naming and configuration of the demo's specific resources (VPC, BQ, GCS, etc.). You can safely modify these values to fit your naming conventions or add/remove them if you are adding/removing specific resource modules in `main.tf`.

---

## 2. Customizing the Demo:

The **`main.tf`** file is your orchestration layer.
*   **To Remove a Component**: Simply comment out the `module` block in `main.tf`.
*   **To Add a Component**: Create a new folder in `terraform-modules/` for your logic, then add a corresponding `module` call in `main.tf`.

---

## 3. Local Testing Deployment Guide:

1.  **Initialize**: `terraform init`
2.  **Plan**: `terraform plan`
3.  **Apply**: `terraform apply`

> [!NOTE]
> Ensure prerequisites in `../org_policy/` are met before testing.

---

## 4. Finalizing: Push to GOB Branch

Once you have verified your changes locally, move your code to a **GOB branch** for centralized testing and final review.

1.  **Commit your changes**:
    ```bash
    git add .
    git commit -m "feat: updated demo resources"
    ```
2.  **Push to a GOB branch**:
    (Replace `your-feature-name` with a descriptive name for your demo)
    ```bash
    git push origin your-branch-name:gob-your-feature-name
    ```
---

### 💡 PRO TIP
Always run `terraform validate` after modifying the modular structure to ensure all variables are correctly passed between the root and the sub-modules.
