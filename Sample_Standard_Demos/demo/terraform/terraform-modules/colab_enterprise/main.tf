data "google_client_config" "current" {}

resource "google_dataform_repository" "notebook_repo" {
  project      = var.project_id
  region       = var.region
  name         = "demo-notebook-repo"
  display_name = "Demo Notebook Repository"
  
  labels = {
    "single-file-asset-type" = "notebook"
  }
}

resource "local_file" "notebook_payload" {
  filename = "${path.module}/notebook_commit.json"
  content  = jsonencode({
    commitMetadata = {
      author = {
        name         = "Demo User"
        emailAddress = var.gcp_account_name
      }
      commitMessage = "Initial commit of demo notebook"
    }
    fileOperations = {
      "sample_notebook.ipynb" = {
        writeFile = {
          contents = base64encode(file("${path.module}/../scripts/sample_notebook.ipynb"))
        }
      }
    }
  })
}

resource "null_resource" "commit_notebook" {
  triggers = {
    notebook_hash = md5(file("${path.module}/../scripts/sample_notebook.ipynb"))
  }

  provisioner "local-exec" {
    command = <<EOF
curl -X POST \
  https://dataform.googleapis.com/v1beta1/projects/${var.project_id}/locations/${var.region}/repositories/${google_dataform_repository.notebook_repo.name}:commit \
  --header "Authorization: Bearer ${data.google_client_config.current.access_token}" \
  --header "Content-Type: application/json" \
  --data-binary @${local_file.notebook_payload.filename}
EOF
  }

  depends_on = [
    google_dataform_repository.notebook_repo,
    local_file.notebook_payload
  ]
}

resource "null_resource" "assign_runtime" {
  provisioner "local-exec" {
    when    = create
    command = <<EOF
curl -X POST \
  https://${var.region}-aiplatform.googleapis.com/v1beta1/projects/${var.project_id}/locations/${var.region}/notebookRuntimes:assign \
  --header "Authorization: Bearer ${data.google_client_config.current.access_token}" \
  --header "Content-Type: application/json" \
  --data '{
      "notebookRuntimeTemplate": "projects/${var.project_id}/locations/${var.region}/notebookRuntimeTemplates/${var.colab_template_name}",
      "notebookRuntime": {
        "displayName": "demo-runtime", 
        "runtimeUser": "${var.gcp_account_name}"
      }
  }'
EOF
  }
}
