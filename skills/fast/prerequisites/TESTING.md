# FAST 0-org-setup Prerequisites - Testing Workflows

This document outlines the various testing workflows and combinations for the `fast-0-org-setup-prereqs` skill to ensure all branches of the skill's logic are covered.

## Core Variables & Decision Points

1. **Environment:** Standard GCP vs. Google Cloud Dedicated (GCD)
2. **GCD Universe (if applicable):** S3NS (France), Berlin (Germany), or Custom
3. **Execution Mode:** Auto (Gemini CLI runs commands) vs. Manual (Output commands for user)
4. **Authentication State:** Already authenticated vs. Needs authentication
5. **Admin Principal Approach:** Group (Approach A) vs. Single User (Approach B)
6. **Billing Account Access Level:** Billing Administrator vs. Billing User vs. No Access
7. **Bootstrap Project:** Pre-existing (with or without API check) vs. New project created by user
8. **Configuration / Dataset:** Standard GCP datasets vs. `classic-gcd` dataset
9. **Org Policy Import Check:** Pre-existing policies found vs. No policies found

## Comprehensive Test Scenarios

### Scenario 1: Standard GCP - The "Simple User" Flow

* **Environment:** Standard GCP
* **Execution Mode:** Manual
* **Authentication:** Needs authentication (Standard auth flow)
* **Admin Principal:** Single User (current authenticated user)
* **Information Gathering:** Direct input of Org ID and Billing ID
* **Billing Access:** Billing Administrator
* **Bootstrap Project:** New project (user creates, CLI outputs full API enable command)
* **Configuration:** Default local path, standard dataset, additional context added
* **Org Policies:** Some policies exist (to test tfvars update)

### Scenario 2: Standard GCP - The "Developer" Flow

* **Environment:** Standard GCP
* **Execution Mode:** Auto
* **Authentication:** Already authenticated
* **Admin Principal:** Group (`foo-owners@example.com`)
* **Information Gathering:** Uses "list" to fetch Org ID and Billing ID
* **Billing Access:** Billing User (requires disabling billing YAML)
* **Bootstrap Project:** Pre-existing project (auto-check and enable missing APIs)
* **Configuration:** Custom local path, standard dataset, no additional context
* **Org Policies:** Some policies exist (to test tfvars update)

#### Notes

### Scenario 3: GCD (S3NS) - Automated Setup

* **Environment:** Google Cloud Dedicated (GCD)
* **Universe:** S3NS (France)
* **Execution Mode:** Auto
* **Authentication:** Needs authentication (WIF login flow)
* **Admin Principal:** Group
* **Billing Access:** Billing Administrator
* **Bootstrap Project:** Pre-existing project (skip API check, enable all)
* **Configuration:** `classic-gcd` dataset (fixed), auto-mapped universe regions, providers.tf generated
* **Org Policies:** No policies exist

### Scenario 4: GCD (Custom) - Manual Setup with Restrictions

* **Environment:** Google Cloud Dedicated (GCD)
* **Universe:** Custom (manually input all 5 variables)
* **Execution Mode:** Manual
* **Authentication:** Already authenticated
* **Admin Principal:** Single User
* **Billing Access:** No Access (requires warning and manual continuation)
* **Bootstrap Project:** New project
* **Configuration:** `classic-gcd` dataset, custom local path
* **Org Policies:** Some policies exist
