# ── Analytics: Glue catalog (the "catalog card") + Athena workgroup ──────
locals {
  # Glue/Athena names: underscores, not hyphens (watt-next-dev → watt_next_dev)
  glue_database_name = replace(local.name_prefix, "-", "_")
  eco2mix_location   = "s3://${aws_s3_bucket.datalake.bucket}/raw/eco2mix/"
}

resource "aws_glue_catalog_database" "watt" {
  name        = local.glue_database_name
  description = "watt-next data lake catalog"
}

resource "aws_glue_catalog_table" "eco2mix" {
  name          = "eco2mix"
  database_name = aws_glue_catalog_database.watt.name # the database's NAME (a reference)
  table_type    = "EXTERNAL_TABLE"                    # data lives in S3, not inside Glue

  parameters = {
    "classification" = "json"

    # Partition projection: Athena COMPUTES folder names instead of us registering them
    "projection.enabled"      = "true"
    "projection.year.type"    = "integer"
    "projection.year.range"   = "2026,2035"
    "projection.month.type"   = "integer"
    "projection.month.range"  = "1,12"
    "projection.month.digits" = "2" # 11 → "11", 2 → "02" (matches our folder names)
    "projection.day.type"     = "integer"
    "projection.day.range"    = "1,31"
    "projection.day.digits"   = "2"
    # $${…} = a LITERAL ${…} for Athena, not a Terraform interpolation
    "storage.location.template" = "${local.eco2mix_location}year=$${year}/month=$${month}/day=$${day}/"
  }

  partition_keys {
    name = "year"
    type = "int"
  }
  partition_keys {
    name = "month"
    type = "int"
  }
  partition_keys {
    name = "day"
    type = "int"
  }

  storage_descriptor {
    location      = local.eco2mix_location
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe" # reads one JSON object per line
    }

    # Only the columns we query; unlisted JSON fields are simply ignored
    columns {
      name    = "date_heure"
      type    = "string" # ISO timestamp in UTC; parsed in SQL
      comment = "UTC timestamp of the 15-minute reading"
    }
    columns {
      name    = "taux_co2"
      type    = "int"
      comment = "Carbon intensity, g CO2 per kWh"
    }
    columns {
      name = "consommation"
      type = "int"
    }
    columns {
      name = "nucleaire"
      type = "int"
    }
    columns {
      name = "eolien"
      type = "int"
    }
    columns {
      name = "solaire"
      type = "int"
    }
    columns {
      name = "hydraulique"
      type = "int"
    }
    columns {
      name = "gaz"
      type = "int"
    }
    columns {
      name = "bioenergies"
      type = "int"
    }
  }
}

resource "aws_athena_workgroup" "watt" {
  name        = local.name_prefix
  description = "watt-next queries, with cost guardrails"

  configuration {
    enforce_workgroup_configuration    = true # users can't override these settings
    publish_cloudwatch_metrics_enabled = true
    bytes_scanned_cutoff_per_query     = 104857600 # 100 MB: cancel runaway queries

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena.bucket}/results/" # the Athena results bucket's NAME (inside ${ })

      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
}