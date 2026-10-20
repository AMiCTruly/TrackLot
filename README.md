\# Serverless Vehicle Auction Monitor \& Ingestion Pipeline



An event-driven serverless alerting system built with \*\*Terraform\*\*, \*\*AWS Lambda (Python 3.11)\*\*, \*\*Amazon DynamoDB\*\*, and \*\*Amazon EventBridge\*\*. The service automates the ingestion, filtering, and deduplication of salvage auction listings, dispatching real-time notifications via Discord webhooks.



\---



\## Architecture Overview

\[ Amazon EventBridge ]

│ (15-min cron)

▼

\[ AWS Lambda (Python 3.11) ] ───► \[ Upstream Scraping / API ]

│                                     │

│ (Filtered Matches)                  │ (Fallback Data on Block/Timeout)

▼                                     ▼

\[ Amazon DynamoDB ] ◄────────────────────────┘



&#x20;   Partition Key: lot\_id



&#x20;   14-Day Automated TTL

&#x20;   │

&#x20;   │ (If New Listing)

&#x20;   ▼

&#x20;   \[ Discord Webhook Channel ]



\### Core Components

1\. \*\*Compute \& Scheduling:\*\* AWS Lambda triggered every 15 minutes by an EventBridge cron rule (`cron(\*/15 \* \* \* ? \*)`), eliminating persistent compute overhead.

2\. \*\*Resilient Ingestion Engine:\*\* Tiered ingestion pattern supporting explicit invocation payloads for automated testing, live auction API queries, and graceful fallback feeds to maintain pipeline uptime.

3\. \*\*Idempotency \& Deduplication:\*\* DynamoDB table (`AuctionAlerts`) tracks processed lot IDs with a native 14-day Time-to-Live (TTL) attribute to prevent duplicate alerts and maintain Free Tier compliance.

4\. \*\*Least-Privilege Security:\*\* Scoped IAM execution role granting strict `dynamodb:GetItem` and `dynamodb:PutItem` permissions alongside CloudWatch logging.



\---



\## Project Structure



```text

├── main.py            # Lambda handler, ingestion tiers, filter rules \& Discord integration

├── main.tf            # Terraform infrastructure definitions (Lambda, DynamoDB, EventBridge, IAM)

├── test\_local.py      # Local test harness for schema validation

├── .gitignore         # Build artifact and secret exclusion rules

└── README.md          # Project documentation

## Deployment \& Verification

Prerequisites



&#x20;   AWS CLI configured with administrator permissions



&#x20;   Terraform >= 1.5.0



&#x20;   Python 3.11



1\. Configure Secrets



Create a terraform.tfvars file:

Terraform



discord\_webhook\_url = "\[https://discord.com/api/webhooks/YOUR\_KEY\_HERE](https://discord.com/api/webhooks/YOUR\_KEY\_HERE)"



2\. Package \& Deploy

DOS



copy /y main.py package\\main.py

python -c "import shutil; shutil.make\_archive('lambda\_function', 'zip', 'package')"

terraform init

terraform apply -auto-approve



3\. Verify Lambda Execution

DOS



aws lambda invoke --function-name auction-monitor-service --cli-binary-format raw-in-base64-out --payload "{}" response.json

type response.json





Save and exit (`Ctrl + S`, then close Notepad).



\---



\### Step 2: Push the Documentation to GitHub



Stage, commit, and push the documentation:



```cmd

git add README.md

git commit -m "docs: add architecture overview, system design, and deployment instructions"

git push origin main



Step 3: Resource Cleanup (Optional)



If you do not want the EventBridge cron running continuously in your AWS account in the background, tear down the deployed infrastructure with a single command:

DOS



terraform destroy -auto-approve



(Because your code and configuration are saved in Git, you can recreate the entire system at any time by running terraform apply -auto-approve.)

