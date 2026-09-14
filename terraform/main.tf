terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.id_proyecto
  region  = var.region
}

resource "google_pubsub_topic" "incidencias" {
  name = "incidencias"
}

resource "google_firestore_database" "base_de_datos" {
  name        = "(default)"
  location_id = var.region
  type        = "FIRESTORE_NATIVE"
}

resource "google_cloud_run_v2_service" "api_incidencias" {
  name     = "registro-incidencias-api"
  location = var.region

  template {
    containers {
      image = "europe-southwest1-docker.pkg.dev/${var.id_proyecto}/registro-incidencias-repo/api:v1"
      ports {
        container_port = 8080
      }
    }
  }
}

resource "google_cloud_run_v2_service_iam_member" "acceso_a_la_api" {
  location = google_cloud_run_v2_service.api_incidencias.location
  name     = google_cloud_run_v2_service.api_incidencias.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_v2_service" "procesador_de_incidencias" {
  name     = "procesador-de-las-incidencias"
  location = var.region

  template {
    containers {
      image = "europe-southwest1-docker.pkg.dev/${var.id_proyecto}/registro-incidencias-repo/procesador:v1"
      ports {
        container_port = 8080
      }
    }
  }
}

resource "google_pubsub_subscription" "suscripcion_del_procesador_de_las_incidencias" {
  name  = "suscripcion-del-procesador-de-incidencias"
  topic = google_pubsub_topic.incidencias.name

  push_config {
    push_endpoint = "${google_cloud_run_v2_service.procesador_de_incidencias.uri}/procesar"
    oidc_token {
      service_account_email = google_service_account.cuenta_pubsub.email
    }
  }
}

resource "google_service_account" "cuenta_pubsub" {
  account_id   = "pubsub-invoker"
  display_name = "Service Account para que Pub/Sub pueda llamar a Cloud Run"
}

resource "google_cloud_run_v2_service_iam_member" "acceso_pubsub_procesador" {
  location = google_cloud_run_v2_service.procesador_de_incidencias.location
  name     = google_cloud_run_v2_service.procesador_de_incidencias.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.cuenta_pubsub.email}"
}

resource "google_artifact_registry_repository" "repositorio_incidencias" {
  location      = var.region
  repository_id = "registro-incidencias-repo"
  format        = "DOCKER"
}