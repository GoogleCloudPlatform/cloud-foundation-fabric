# Firestore

This module allows to crete a firestore datatabase, fields, indexes and documents.

## Examples

### New database

```hcl
module "firestore" {
  source     = "./fabric/modules/firestore"
  project_id = "my-project"
  database = {
    name        = "my-database"
    location_id = "nam5"
    type        = "FIRESTORE_NATIVE"
  }
}
# tftest modules=1 resources=1 inventory=new-database.yaml
```

### New database with weekly backup

```hcl
module "firestore" {
  source     = "./fabric/modules/firestore"
  project_id = "my-project"
  database = {
    name        = "my-database"
    location_id = "nam5"
    type        = "FIRESTORE_NATIVE"
  }
  backup_schedule = {
    retention         = "86400s"
    weekly_recurrence = "MONDAY"
  }
}
# tftest modules=1 resources=2 inventory=new-database-with-weekly-backup.yaml
```

### New database with document

```hcl
module "firestore" {
  source     = "./fabric/modules/firestore"
  project_id = "my-project"
  database = {
    name        = "my-database"
    location_id = "nam5"
    type        = "FIRESTORE_NATIVE"
  }
  documents = {
    my-doc-1 = {
      collection  = "my-coll"
      document_id = "d3db1c14-e56d-4597-af1c-f95c2d2290c1"
      fields = {
        field1 = "value1"
        field2 = "value2"
      }
    }
  }
}
# tftest modules=1 resources=2 inventory=new-database-with-document.yaml
```

### Existing database with document

```hcl
module "firestore" {
  source     = "./fabric/modules/firestore"
  project_id = "my-project"
  database = {
    name = "my-database"
  }
  database_create = false
  documents = {
    my-doc-1 = {
      collection  = "my-coll"
      document_id = "d3db1c14-e56d-4597-af1c-f95c2d2290c1"
      fields = {
        field1 = "value1"
        field2 = "value2"
      }
    }
  }
}
# tftest modules=1 resources=1 inventory=existing-database-with-document.yaml
```

### New database with field

```hcl
module "firestore" {
  source     = "./fabric/modules/firestore"
  project_id = "my-project"
  database = {
    name        = "my-database"
    location_id = "name5"
    type        = "FIRESTORE_NATIVE"
  }
  fields = {
    my-field-in-my-coll = {
      collection = "my-coll"
      field      = "my-field"
      indexes = [
        {
          order       = "ASCENDING"
          query_scope = "COLLECTION_GROUP"
        },
        {
          array_config = "CONTAINS"
        }
      ]
    }
  }
}
# tftest modules=1 resources=2 inventory=new-database-with-field.yaml
```

### New database with index

```hcl
module "firestore" {
  source     = "./fabric/modules/firestore"
  project_id = "my-project"
  database = {
    name        = "my-database"
    location_id = "name5"
    type        = "FIRESTORE_NATIVE"
  }
  indexes = {
    my-index = {
      collection = "my-coll"
      fields = [
        {
          field_path = "name"
          order      = "ASCENDING"
        },
        {
          field_path = "description"
          order      = "DESCENDING"
        }
      ]
    }
  }
}
# tftest modules=1 resources=2 inventory=new-database-with-index.yaml
```
<!-- BEGIN TFDOC -->
## Variables

| name | description | type | required | default |
|---|---|:---:|:---:|:---:|
| [database](variables.tf#L41) | Database attributes. | <code title="object&#40;&#123;&#10;  app_engine_integration_mode       &#61; optional&#40;string&#41;&#10;  concurrency_mode                  &#61; optional&#40;string&#41;&#10;  deletion_policy                   &#61; optional&#40;string&#41;&#10;  delete_protection_state           &#61; optional&#40;string&#41;&#10;  kms_key_name                      &#61; optional&#40;string&#41;&#10;  location_id                       &#61; optional&#40;string&#41;&#10;  name                              &#61; string&#10;  point_in_time_recovery_enablement &#61; optional&#40;string&#41;&#10;  type                              &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L228) | Project id. | <code>string</code> | ✓ |  |
| [backup_schedule](variables.tf#L17) | Backup schedule. | <code title="object&#40;&#123;&#10;  retention         &#61; string&#10;  daily_recurrence  &#61; optional&#40;bool, false&#41;&#10;  weekly_recurrence &#61; optional&#40;string&#41;&#10;&#125;&#41;">object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [database_create](variables.tf#L95) | Flag indicating whether the database should be created of not. | <code>string</code> |  | <code>&#34;true&#34;</code> |
| [documents](variables.tf#L101) | Documents. | <code title="map&#40;object&#40;&#123;&#10;  collection  &#61; string&#10;  document_id &#61; string&#10;  fields      &#61; any&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [fields](variables.tf#L112) | Fields. | <code title="map&#40;object&#40;&#123;&#10;  collection &#61; string&#10;  field      &#61; string&#10;  indexes &#61; optional&#40;list&#40;object&#40;&#123;&#10;    query_scope  &#61; optional&#40;string&#41;&#10;    order        &#61; optional&#40;string&#41;&#10;    array_config &#61; optional&#40;string&#41;&#10;  &#125;&#41;&#41;&#41;&#10;  ttl_config &#61; optional&#40;bool, false&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [indexes](variables.tf#L164) | Indexes. | <code title="map&#40;object&#40;&#123;&#10;  api_scope  &#61; optional&#40;string&#41;&#10;  collection &#61; string&#10;  fields &#61; list&#40;object&#40;&#123;&#10;    field_path   &#61; optional&#40;string&#41;&#10;    order        &#61; optional&#40;string&#41;&#10;    array_config &#61; optional&#40;string&#41;&#10;    vector_config &#61; optional&#40;object&#40;&#123;&#10;      dimension &#61; optional&#40;number&#41;&#10;      flat      &#61; optional&#40;bool&#41;&#10;    &#125;&#41;&#41;&#10;  &#125;&#41;&#41;&#10;  query_scope &#61; optional&#40;string&#41;&#10;&#125;&#41;&#41;">map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

## Outputs

| name | description | sensitive |
|---|---|:---:|
| [firestore_database](outputs.tf#L17) | Firestore database. |  |
| [firestore_document_ids](outputs.tf#L22) | Firestore document ids. |  |
| [firestore_documents](outputs.tf#L26) | Firestore documents. |  |
| [firestore_field_ids](outputs.tf#L31) | Firestore field ids. |  |
| [firestore_fields](outputs.tf#L36) | Firestore fields. |  |
| [firestore_index_ids](outputs.tf#L41) | Firestore index ids. |  |
| [firestore_indexes](outputs.tf#L46) | Firestore indexes. |  |
<!-- END TFDOC -->
