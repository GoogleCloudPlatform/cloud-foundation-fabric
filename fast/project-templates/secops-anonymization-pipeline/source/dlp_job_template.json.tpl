{
  "actions": [
    {
      "deidentify": {
        "file_types_to_transform": [
          "TEXT_FILE",
          "IMAGE",
          "CSV",
          "TSV"
        ],
        "transformation_details_storage_config": {},
        "transformation_config": {
            "deidentify_template": "{{ deidentify_template_id }}",
            "structured_deidentify_template": "",
            "image_redact_template": ""
        },
        "cloud_storage_output": "gs://{{output_bucket}}/"
      }
    }
  ],
  "inspect_template_name": "{{ inspect_template_id }}",
  "storage_config": {
    "cloud_storage_options": {
      "file_set": {
        "url": "gs://{{ export_bucket }}/{{export_id}}/**"
      },
      "file_types": ["TEXT_FILE", "CSV", "TSV", "EXCEL", "AVRO"],
      "files_limit_percent": 100
    }
  }
}
