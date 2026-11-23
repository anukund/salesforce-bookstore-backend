# Salesforce bookstore backend
Single-title checkout for an authenticated internal demo. Use a personal Developer Edition or disposable sandbox. Requires Salesforce CLI, API access, and a user authorized to deploy metadata. Run the following from the folder containing sfdx-project.json.

    sf org login web --alias bookstore
    sf project deploy start --target-org bookstore --source-dir force-app --test-level RunSpecifiedTests --tests BookstoreApiTest --wait 15
    sf org assign permset --name Bookstore_Demo_Operator --target-org bookstore
    sf apex run --file scripts/seed.apex --target-org bookstore
    sf apex run test --tests BookstoreApiTest --target-org bookstore --result-format human --code-coverage --wait 10

Seed with an administrator. The permission set is for a trusted demo operator and allows direct inventory edits. It is unsuitable for a public shopper identity. Each POST is a new order. This demo does not collect payment or deduplicate retries.

## Demonstrate the API
Use a Salesforce-authenticated REST client against your org. In Salesforce CLI, run:
    
    sf api request rest '/services/apexrest/bookstore/v1/books' --target-org bookstore

Copy the returned Salesforce book Id into a local file named order.json:
    
    {"bookId":"REPLACE_WITH_BOOK_ID","quantity":2}

Then run:
    
    sf api request rest '/services/apexrest/bookstore/v1/orders' --method POST --body @order.json --target-org bookstore
    sf api request rest '/services/apexrest/bookstore/v1/orders/REPLACE_WITH_ORDER_ID' --target-org bookstore

Starting from five copies at 12.99, expect HTTP 201 and a total of 25.98. Query the catalogue again to see three copies remaining. Request six to demonstrate HTTP 409. For a repeated demo, check the current stock first. The seed script preserves existing stock.

## Agentic development and evidence
Codex generated the Salesforce DX metadata, Apex REST class, tests, and seed script. The video is a narrated source walkthrough with expected outcomes. Record the actual deployment, HTTP requests, and Apex test results in your org to evidence a working application. In your agentic IDE ask: “Explain how this checkout prevents overselling, run BookstoreApiTest in my bookstore sandbox, and summarize the observed results.” Keep access tokens and org login details off screen.

## Scope
GET books returns the first 100 books by name. Book_Order__c stores the agreed total, quantity, and linked book. Orders default to private sharing. BookstoreApi uses explicit user-mode SOQL and DML. The lock serializes competing stock updates. The supplied tests exercise the REST handler directly with isolated test records. Real concurrency and external HTTP routing require org-level verification.
