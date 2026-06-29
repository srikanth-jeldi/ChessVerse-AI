# AWS Cost Safety

AWS does not charge merely because a service appears in the console. Charges
come from provisioned resources and usage.

## Keep

- Root and IAM MFA
- IAM users and roles without paid resources attached
- Enabled AWS Regions
- An SNS sandbox destination, provided no messages are sent

ChessVerse no longer contains AWS SMS runtime code or credentials.

## Check Now

1. Open **Billing and Cost Management > Bills > Charges by service**.
2. Expand every service and Region.
3. Open **Cost Explorer** and group the current month by Service and Region.
4. Create a small monthly AWS Budget with email alerts.
5. In every used Region, delete resources that are not required:
   - EC2 instances, EBS volumes and snapshots
   - Elastic IP/public IPv4 addresses
   - NAT gateways and load balancers
   - RDS databases and retained snapshots
   - EKS clusters and node groups
   - ElastiCache and OpenSearch clusters
   - Secrets Manager secrets
   - Unneeded S3 objects/buckets and CloudWatch log groups
   - Route 53 hosted zones and domains

Do not create EKS, RDS, ElastiCache, NAT Gateway, or a load balancer until the
production deployment milestone. Local Docker/H2 development does not need
those AWS resources.

If AWS will not be used at all, close the account from **Account > Close
account** after checking Bills and downloading anything that must be retained.
