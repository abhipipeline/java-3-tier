# GCP Cloud Monitoring Module

# Log Sink for Application Logs
resource "google_logging_project_sink" "application_logs" {
  name            = "${var.environment}-application-logs-sink"
  destination     = "logging.googleapis.com/projects/${var.project_id}/logs/${var.environment}-application"
  filter          = "resource.type=gce_instance AND resource.labels.instance_id=*"
  unique_writer_identity = true
}

# Alert Policy - High CPU Utilization on Instances
resource "google_monitoring_alert_policy" "high_cpu" {
  display_name = "${var.environment}-high-cpu-alert"
  combiner     = "OR"

  conditions {
    display_name = "High CPU Utilization"

    condition_threshold {
      filter          = "resource.type=gce_instance AND metric.type=compute.googleapis.com/instance/cpu/utilization"
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period    = "60s"
        per_series_aligner  = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channels

  labels = {
    environment = var.environment
  }
}

# Alert Policy - High Memory Usage
resource "google_monitoring_alert_policy" "high_memory" {
  display_name = "${var.environment}-high-memory-alert"
  combiner     = "OR"

  conditions {
    display_name = "High Memory Usage"

    condition_threshold {
      filter          = "resource.type=gce_instance AND metric.type=compute.googleapis.com/instance/memory/utilization"
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85

      aggregations {
        alignment_period    = "60s"
        per_series_aligner  = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channels

  labels = {
    environment = var.environment
  }
}

# Alert Policy - Cloud SQL High CPU
resource "google_monitoring_alert_policy" "cloudsql_cpu" {
  display_name = "${var.environment}-cloudsql-high-cpu-alert"
  combiner     = "OR"

  conditions {
    display_name = "CloudSQL High CPU Utilization"

    condition_threshold {
      filter          = "resource.type=cloudsql_database AND metric.type=cloudsql.googleapis.com/database/cpu/utilization"
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period    = "60s"
        per_series_aligner  = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channels

  labels = {
    environment = var.environment
  }
}

# Alert Policy - Cloud SQL Low Memory
resource "google_monitoring_alert_policy" "cloudsql_memory" {
  display_name = "${var.environment}-cloudsql-low-memory-alert"
  combiner     = "OR"

  conditions {
    display_name = "CloudSQL Low Available Memory"

    condition_threshold {
      filter          = "resource.type=cloudsql_database AND metric.type=cloudsql.googleapis.com/database/memory/utilization"
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.9

      aggregations {
        alignment_period    = "60s"
        per_series_aligner  = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = var.notification_channels

  labels = {
    environment = var.environment
  }
}

# Monitoring Dashboard
resource "google_monitoring_dashboard" "main" {
  dashboard_json = jsonencode({
    displayName = "${var.environment}-dashboard"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "CPU Utilization - Instances"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=gce_instance AND metric.type=compute.googleapis.com/instance/cpu/utilization"
                    }
                  }
                  plotType = "LINE"
                }
              ]
            }
          }
        },
        {
          xPos   = 6
          width  = 6
          height = 4
          widget = {
            title = "Memory Utilization - Instances"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=gce_instance AND metric.type=compute.googleapis.com/instance/memory/utilization"
                    }
                  }
                  plotType = "LINE"
                }
              ]
            }
          }
        },
        {
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "CloudSQL CPU Utilization"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=cloudsql_database AND metric.type=cloudsql.googleapis.com/database/cpu/utilization"
                    }
                  }
                  plotType = "LINE"
                }
              ]
            }
          }
        },
        {
          xPos   = 6
          yPos   = 4
          width  = 6
          height = 4
          widget = {
            title = "CloudSQL Memory Utilization"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "resource.type=cloudsql_database AND metric.type=cloudsql.googleapis.com/database/memory/utilization"
                    }
                  }
                  plotType = "LINE"
                }
              ]
            }
          }
        }
      ]
    }
  })

  labels = {
    environment = var.environment
  }
}
