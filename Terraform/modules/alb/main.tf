
resource "aws_acm_certificate" "custom_ssl_cert" {
  domain_name       = "yourcustomdomain.com"
  validation_method = "EMAIL"  # Email validation

  subject_alternative_names = ["www.yourcustomdomain.com"]  # Optional

  tags = {
    Name = "custom-ssl-cert"
  }
}

resource "aws_acm_certificate_validation" "custom_ssl_cert_validation" {
  certificate_arn = aws_acm_certificate.custom_ssl_cert.arn
}

