module "unified_dr_plan" {
  source = "../../"

  project_id      = "yashwant-argolis"
  location        = "us-central1"
  backup_vault_id = "my-backup-vault"
  backup_plan_id  = "my-backup-plan"

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
    },
    {
      rule_id               = "weekly-backup"
      backup_retention_days = 90
      standard_schedule = {
        recurrence_type = "WEEKLY"
        days_of_week    = ["SUNDAY"]
        time_zone       = "UTC"
        backup_window = {
          start_hour_of_day = 6
          end_hour_of_day   = 10 # Min of 4 hours window for weekly required
        }
      }
    },
    {
      rule_id               = "hourly-backup"
      backup_retention_days = 7
      standard_schedule = {
        recurrence_type  = "HOURLY"
        hourly_frequency = 4 # minimum 4 hours required for HOURLY
        time_zone        = "UTC"
        backup_window = {
          start_hour_of_day = 0
          end_hour_of_day   = 15
        }
      }
    }
  ]
}