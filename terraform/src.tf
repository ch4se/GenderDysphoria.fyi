

# -----------------------------------------------------------------------------------------------------------
# IAM User for Uploading

resource "aws_iam_user" "s3" {
  name = "${var.site}-s3"
  path = "/${var.site}/"

  tags = {
    Site = var.site
    Category = "S3"
  }
}

resource "aws_iam_user_policy" "s3" {
  name = "test"
  user = aws_iam_user.s3.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateInvalidation",
        "cloudfront:GetInvalidation",
        "s3:PutAccountPublicAccessBlock",
        "s3:GetAccountPublicAccessBlock",
        "s3:ListAllMyBuckets",
        "s3:HeadBucket"
      ],
      "Resource": [
        "${aws_cloudfront_distribution.site.arn}"
      ]
    }
  ]
}
EOF
}

# This writes the s3 access key and secret to the terraform state file
resource "aws_iam_access_key" "s3" {
  user    = aws_iam_user.s3.name
}

# output s3_access {
#   description = "S3 Upload User AccessKey"
#   value       = "${aws_iam_access_key.s3.id}"
# }

# output s3_secret {
#   description = "S3 Upload User Secret"
#   value       = "${aws_iam_access_key.s3.secret}"
# }

# -----------------------------------------------------------------------------------------------------------
# Site Source Code

resource "aws_s3_bucket" "src" {
  bucket = var.domain
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "404.html"
  }

  tags = {
    Name = "Site Source"
    Site = var.site
  }
}

resource "aws_s3_bucket" "uat" {
  bucket = "uat.${var.domain}"
  acl    = "public-read"

  website {
    index_document = "index.html"
    error_document = "404.html"
  }

  tags = {
    Name = "Site Source UAT"
    Site = var.site
  }
}


resource "aws_s3_bucket_policy" "src" {
  bucket = aws_s3_bucket.src.bucket
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_user.s3.arn}"
      },
      "Action": "s3:ListBucket",
      "Resource": "${aws_s3_bucket.src.arn}"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_user.s3.arn}"
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:GetObject",
        "s3:GetObjectAcl",
        "s3:DeleteObject",
        "s3:ListMultipartUploadParts",
        "s3:AbortMultipartUpload"
      ],
      "Resource": "${aws_s3_bucket.src.arn}/*"
    },
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "${aws_s3_bucket.src.arn}/*"
    }
  ]
}
POLICY
}


resource "aws_s3_bucket_policy" "uat" {
  bucket = aws_s3_bucket.uat.bucket
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_user.s3.arn}"
      },
      "Action": "s3:ListBucket",
      "Resource": "${aws_s3_bucket.uat.arn}"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_user.s3.arn}"
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:GetObject",
        "s3:GetObjectAcl",
        "s3:DeleteObject",
        "s3:ListMultipartUploadParts",
        "s3:AbortMultipartUpload"
      ],
      "Resource": "${aws_s3_bucket.uat.arn}/*"
    },
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "${aws_s3_bucket.uat.arn}/*"
    }
  ]
}
POLICY
}

resource "aws_route53_record" "uat" {
  name    = "uat.${var.domain}"
  zone_id = aws_route53_zone.zone.zone_id
  type    = "A"

  alias {
    name                   = aws_s3_bucket.uat.website_domain
    zone_id                = aws_s3_bucket.uat.hosted_zone_id
    evaluate_target_health = false
  }
}

