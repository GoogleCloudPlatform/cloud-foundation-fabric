module "unified_dr_plan" {
  source = "../../"

  project_id          = "your-gcp-project-id"
  location            = "us-central1"
  backup_vault_id     = "my-backup-vault"
  backup_plan_id      = "my-backup-plan"
  create_backup_vault = false

  backup_rules = [
    {
      rule_id               = "daily-backup"
      backup_retention_days = 30
      standard_schedule = {
        recurrence_type = "DAILY"
        time_zone       = "UTC"
        backup_window = {
          start_hour_of_day = 2
          end_hour_of_day   = 4
        }
      }
    }
  ]
}