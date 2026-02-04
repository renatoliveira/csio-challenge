# Salesforce Application Intake - Design & Implementation Exercise

## Context

You are working on a Salesforce product that allows external partners to submit applications into the system.

Applications may come from:

- a public Salesforce Experience Cloud site with an Application Form, or
- an external system via a webhook.

The product is expected to evolve over time. The system will be used by multiple customers and may receive support requests.

## Business Requirements

When an application is submitted:

- The system must attempt to match an existing Account.
- If a match is found, an Opportunity is created.
- If no match is found, a Lead is created.

### Matching rules:

- Prefer matching by Federal Tax ID when available.
- Fall back to Company Name if no Tax ID is provided.
- Each created record must indicate where it came from (Community, Webhook)

## Functional Requirements

### Public submission

- Implement a public-facing submission UI (LWC)

#### Required fields:

- Company Name
- Email
- Phone
- Contact First Name
- Contact Last Name

#### Optional fields:

- Federal Tax ID
- Annual Revenue

### External webhook

- Implement a public REST endpoint that accepts JSON input.
- Payload shape is flexible
- Assume this endpoint may receive invalid or malicious requests.

## Deliverables

1. Working Apex / LWC / REST code
2. Focus on clarity and correctness over volume.
3. Tests

## Minimum coverage:

- Successful Lead creation
- Successful Opportunity creation
- At least one failure scenario that demonstrates how the system behaves when something goes wrong

## README

In your README, explain:

your overall design

key tradeoffs you made

one thing you intentionally did not implement yet, and why

Design Freedom

There is no required architecture!

---

