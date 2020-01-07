# module-iam-key-audit

This module will add a Lambda function that scans for unused IAM keys.
Status of unused keys will be changed to `Inactive`

## Usage

```
module "iam-key-audit" {
  source = "github.com/wschiffels/module-iam-key-audit"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| iam\_key\_audit\_schedule | how often we run the lambda | string | `"cron(00 11 ? * MON-FRI *)"` | no |
