# Moves existing state to the for_each addresses instead of destroy/recreate.
# Safe to delete once every repo using this template has applied once.

moved {
  from = google_project_service.bigquery_googleapis_com
  to   = google_project_service.services["bigquery.googleapis.com"]
}

moved {
  from = google_project_service.bigquerymigration_googleapis_com
  to   = google_project_service.services["bigquerymigration.googleapis.com"]
}

moved {
  from = google_project_service.bigquerystorage_googleapis_com
  to   = google_project_service.services["bigquerystorage.googleapis.com"]
}

moved {
  from = google_project_service.cloudapis_googleapis_com
  to   = google_project_service.services["cloudapis.googleapis.com"]
}

moved {
  from = google_project_service.cloudasset_googleapis_com
  to   = google_project_service.services["cloudasset.googleapis.com"]
}

moved {
  from = google_project_service.cloudbuild_googleapis_com
  to   = google_project_service.services["cloudbuild.googleapis.com"]
}

moved {
  from = google_project_service.cloudfunctions_googleapis_com
  to   = google_project_service.services["cloudfunctions.googleapis.com"]
}

moved {
  from = google_project_service.cloudresourcemanager_googleapis_com
  to   = google_project_service.services["cloudresourcemanager.googleapis.com"]
}

moved {
  from = google_project_service.cloudscheduler_googleapis_com
  to   = google_project_service.services["cloudscheduler.googleapis.com"]
}

moved {
  from = google_project_service.cloudtrace_googleapis_com
  to   = google_project_service.services["cloudtrace.googleapis.com"]
}

moved {
  from = google_project_service.compute_googleapis_com
  to   = google_project_service.services["compute.googleapis.com"]
}

moved {
  from = google_project_service.containerregistry_googleapis_com
  to   = google_project_service.services["containerregistry.googleapis.com"]
}

moved {
  from = google_project_service.datastore_googleapis_com
  to   = google_project_service.services["datastore.googleapis.com"]
}

moved {
  from = google_project_service.eventarc_googleapis_com
  to   = google_project_service.services["eventarc.googleapis.com"]
}

moved {
  from = google_project_service.firebaserules_googleapis_com
  to   = google_project_service.services["firebaserules.googleapis.com"]
}

moved {
  from = google_project_service.firestore_googleapis_com
  to   = google_project_service.services["firestore.googleapis.com"]
}

moved {
  from = google_project_service.firestorekeyvisualizer_googleapis_com
  to   = google_project_service.services["firestorekeyvisualizer.googleapis.com"]
}

moved {
  from = google_project_service.iam_googleapis_com
  to   = google_project_service.services["iam.googleapis.com"]
}

moved {
  from = google_project_service.iamcredentials_googleapis_com
  to   = google_project_service.services["iamcredentials.googleapis.com"]
}

moved {
  from = google_project_service.project_service
  to   = google_project_service.services["iap.googleapis.com"]
}

moved {
  from = google_project_service.logging_googleapis_com
  to   = google_project_service.services["logging.googleapis.com"]
}

moved {
  from = google_project_service.monitoring_googleapis_com
  to   = google_project_service.services["monitoring.googleapis.com"]
}

moved {
  from = google_project_service.oslogin_googleapis_com
  to   = google_project_service.services["oslogin.googleapis.com"]
}

moved {
  from = google_project_service.pubsub_googleapis_com
  to   = google_project_service.services["pubsub.googleapis.com"]
}

moved {
  from = google_project_service.pubsublite_googleapis_com
  to   = google_project_service.services["pubsublite.googleapis.com"]
}

moved {
  from = google_project_service.run_googleapis_com
  to   = google_project_service.services["run.googleapis.com"]
}

moved {
  from = google_project_service.secretmanager_googleapis_com
  to   = google_project_service.services["secretmanager.googleapis.com"]
}

moved {
  from = google_project_service.servicemanagement_googleapis_com
  to   = google_project_service.services["servicemanagement.googleapis.com"]
}

moved {
  from = google_project_service.serviceusage_googleapis_com
  to   = google_project_service.services["serviceusage.googleapis.com"]
}

moved {
  from = google_project_service.sql_component_googleapis_com
  to   = google_project_service.services["sql-component.googleapis.com"]
}

moved {
  from = google_project_service.storage_api_googleapis_com
  to   = google_project_service.services["storage-api.googleapis.com"]
}

moved {
  from = google_project_service.storage_component_googleapis_com
  to   = google_project_service.services["storage-component.googleapis.com"]
}

moved {
  from = google_project_service.storage_googleapis_com
  to   = google_project_service.services["storage.googleapis.com"]
}

moved {
  from = google_project_service.vpcaccess_googleapis_com
  to   = google_project_service.services["vpcaccess.googleapis.com"]
}

moved {
  from = google_project_service.workflowexecutions_googleapis_com
  to   = google_project_service.services["workflowexecutions.googleapis.com"]
}

moved {
  from = google_project_service.workflows_googleapis_com
  to   = google_project_service.services["workflows.googleapis.com"]
}
