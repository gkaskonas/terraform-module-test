variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the RDS cluster will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the RDS cluster"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "engine_name" {
  description = "Database engine type (aurora-postgresql/aurora-mysql)"
  type        = string
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
}

variable "master_username" {
  description = "Master username for the RDS cluster"
  type        = string
  default     = "admin"
}

variable "readonly_username" {
  description = "Username for the read-only user"
  type        = string
  default     = "readonly"
}

variable "readwrite_username" {
  description = "Username for the read-write user"
  type        = string
  default     = "readwrite"
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "Preferred backup window"
  type        = string
  default     = "02:00-03:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot before destroying the cluster"
  type        = bool
  default     = false
}

variable "auto_pause" {
  description = "Whether to enable auto pause"
  type        = bool
  default     = true
}

variable "max_capacity" {
  description = "Maximum capacity in Aurora capacity units (ACUs)"
  type        = number
  default     = 16
}

variable "min_capacity" {
  description = "Minimum capacity in Aurora capacity units (ACUs)"
  type        = number
  default     = 1
}

variable "seconds_until_auto_pause" {
  description = "Seconds of inactivity before pausing"
  type        = number
  default     = 300
}

variable "timeout_action" {
  description = "Action to take when timeout is reached"
  type        = string
  default     = "ForceApplyCapacityChange"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "storage_encrypted" {
  description = "Specifies whether the DB cluster is encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. When specifying kms_key_id, storage_encrypted needs to be set to true"
  type        = string
  default     = null
}

variable "serverless_version" {
  description = "Aurora Serverless version (v1 or v2)"
  type        = string
  default     = "v2"
  validation {
    condition     = contains(["v1", "v2"], var.serverless_version)
    error_message = "Valid values: v1, v2"
  }
}

variable "engine_version" {
  description = "Database engine version"
  type        = string
  default     = null # Let AWS choose compatible version
} 