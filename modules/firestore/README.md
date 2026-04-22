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
| [database](variables.tf#L41) | Database attributes. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> | ✓ |  |
| [project_id](variables.tf#L228) | Project id. | <code>string</code> | ✓ |  |
| [backup_schedule](variables.tf#L17) | Backup schedule. | <code>object&#40;&#123;&#8230;&#125;&#41;</code> |  | <code>null</code> |
| [database_create](variables.tf#L95) | Flag indicating whether the database should be created of not. | <code>string</code> |  | <code>&#34;true&#34;</code> |
| [documents](variables.tf#L101) | Documents. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [fields](variables.tf#L112) | Fields. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |
| [indexes](variables.tf#L164) | Indexes. | <code>map&#40;object&#40;&#123;&#8230;&#125;&#41;&#41;</code> |  | <code>&#123;&#125;</code> |

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
