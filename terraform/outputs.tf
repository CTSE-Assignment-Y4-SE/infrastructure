output "ec2_public_ip" {
  value = aws_instance.ctse_ec2.public_ip
}
