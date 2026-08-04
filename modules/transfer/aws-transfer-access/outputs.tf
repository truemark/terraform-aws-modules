output "access_id" {
  description = "Unique identifier of the Transfer access configuration, in the form server-id/external-id."
  value       = join("", aws_transfer_access.this[*].id)
}

output "external_id" {
  description = "AD group SID this access configuration applies to."
  value       = join("", aws_transfer_access.this[*].external_id)
}
