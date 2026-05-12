# Project Configuration - Shared Hosted Demos

This repository uses a structured approach to configure Google Cloud project resources (Organization Policies and enabled APIs) **before** the user is added to the shared group.

---

## 1. CRITICAL INSTRUCTIONS ⚠️

### 🛑 DO NOT EDIT `project_config.json`
For shared hosted demos, editing this file is generally not required. We strongly suggest you **do not modify it**. 

### 🛑 DO NOT EDIT `project_resource.tf`
This file contains the core mechanism to apply your settings. Modifying it may break the dynamic policy application.

---

## 2. Structure of `project_config.json`

The file is a standard JSON object containing two key arrays: `constraints` for policies and `apis_to_enable` for services.

### `project_config.json` Example

```json
{
  "constraints": [
    {
      "constraint": "iam.allowedPolicyMemberDomains",
      "policy_type": "list",
      "allow_all": true,
      "deny_all": false,
      "allowed_values": [],
      "denied_values": [],
      "restore_post_deployment": true
    }
  ],
  "apis_to_enable": [
    "cloudresourcemanager.googleapis.com"
  ]
}
```
