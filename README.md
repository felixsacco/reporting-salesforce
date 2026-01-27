<h1>Report app for Attachments and Files in Salesforce</h1>

<!-- TABLE OF CONTENTS -->

## Table of Contents

<ul>
    <li><a href="#about-the-project">About The Project</a></li>
    <li><a href="#getting-started">Getting Started</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#the-process-and-the-outcome-so-far">The Process and the Outcome</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
</ul>

<!-- ABOUT THE PROJECT -->

## About The Project

Salesforce, as one of the leading cloud-based Customer Relationship Management (CRM) platforms, provides organizations with cloud instances of its applications for managing customer data, sales processes, and business operations. Despite its extensive data management and analytics capabilities, the built-in reporting feature does not have full support for the legacy Attachments entity, and these objects often have essential files for business compliance, especially those that still have their data in legacy components.

This project proposes the development of a tool aimed at addressing the well-documented reporting deficiencies associated with Salesforce's file-based data entities. Drawing upon one of the concerns articulated in the Salesforce Idea Exchange post titled “Reporting on Notes & Attachments,” the tool seeks to tackle the challenge of generating reports on the legacy Attachment object while also supporting all file entities (Attachment, ContentDocument), to help users be in alignment with the storage limits established for their Salesforce Cloud Platform. Given that the entities in question are legacy components—alongside newer entities—that Salesforce no longer intends to support, it is imperative to note that legacy components remain integral to numerous enterprise applications. The ability to have reports on all entities that count towards the 'File Storage' limit could facilitate individual file storage management by helping users proactively analyze files and their relevance, thereby reducing any unnecessary costs incurred from increasing storage limits.

The principal contribution of this study is the enhancement of accessibility to actionable analytical data for all stored Attachments owned by all categories of users.

<strong>TLDR</strong>: A robust, secure Lightning Web Component application that allows users to query, filter, and report on Attachment and ContentDocument (Files) records directly within Salesforce.

<img src="assets/App Screenshot.png">

<p align="right">(<a href="#table-of-contents">back to top</a>)</p>

<!-- GETTING STARTED -->

## Getting Started

### Prerequisites

Goes without saying, this requires a Salesforce instance to install and use. Anyone can get themselves a Salesforce Developer Edition Org provisioned by visiting <a href="https://www.salesforce.com/form/developer-signup/?d=pb">developer.salesforce.com</a> and signing up for one.
Once you have an Org and the credentials, please go through the installation steps below.

### Installation Options

<h4>Option 1: Install via Package Link (Recommended for Admins)</h4>

You can install this application directly into your Sandbox or Production environment using the Unlocked Package link.<br>
<a href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04tWU000000F74PYAS">Install Package</a>

1. Click the link above.
2. Log in to your Salesforce Org.
3. Select "Install for All Users".
4. Click <strong>Install</strong>.

<h4>Option 2: Deploy from Source (Recommended for Developers)</h4>
If you have the Salesforce CLI installed, you can deploy the source code directly.

1. Clone this repository:
   ```sh
   git clone https://github.com/MriteshAdak/Reporting-on-Attachments-Salesforce
   cd Reporting-on-Attachments-Salesforce
   ```
2. Authorize your target org:
   ```sh
   sf org login web --alias target-org
   ```
3. Deploy the source:
   ```sh
   sf project deploy start --target-org target-org
   ```

### Post-Installation Setup

After installing the application, you must assign the Permission Set to any user who needs access to the tool. Without this, the component will fail to execute queries.

1. Go to Setup > Users > Permission Sets.
2. Click on "Reporting On Files". (Navigate to 'R' section)
3. Click Manage Assignments > Add Assignment.
4. Select the users and click Assign.

A demo of how to assign a permission set to a user can be found in the following video.<br>
<a href="https://youtu.be/Z6XlW5OlVmc">How to Add a Permission Set to a Salesforce User</a>

<p align="right">(<a href="#table-of-contents">back to top</a>)</p>

<!-- USAGE EXAMPLES -->

## Usage

1. Navigate to the App Launcher.
2. Search for "Reports on Files."
3. Select the Object (Attachment or Content Document).
4. Select the Fields you wish to see.
5. (Optional) Add Filters or Change Limit.
6. Click Execute Query.

<p align="right">(<a href="#table-of-contents">back to top</a>)</p>

## The Process and the Outcome (So Far..)

### Architecture

This project follows an Enterprise Layered Architecture of SF (Model-View-Controller):

- LWC: Handles UI and Event Delegation (queryBuilder, resultsDisplay).
- Apex Controller: Entry point for the Business Logic (AttachmentQueryController).
- Service Layer: Handles Security logic (AccessChecker).
- Domain Layer: Handles SOQL construction (SoqlQueryBuilder).

<br>
The directory structure of the Application is shown below:

```
ReportingOnAttachments/
└── force-app/
    └── main/
        └── default/
            │
            ├── classes/  <-- BACKEND (APEX)
            │   │
            │   ├── AttachmentQueryController.cls   # The Coordinator/Broker
            │   ├── AttachmentQueryController.cls-meta.xml
            │   │
            │   ├── AccessChecker.cls               # The Security Guard
            │   ├── AccessChecker.cls-meta.xml
            │   │
            │   ├── SoqlQueryBuilder.cls            # The Query String Builder
            │   ├── SoqlQueryBuilder.cls-meta.xml
            │   │
            │   ├── QueryFilterDto.cls              # Data Structure (DTO)
            │   ├── QueryFilterDto.cls-meta.xml
            │   │
            │   └── Tests/  <-- TEST CLASSES (APEX)
            │
            └── lwc/  <-- FRONTEND (Javascript/HTML)
                │
                └── queryBuilder/       # User-Input Component
                │   ├── __tests__
                │   ├── queryBuilder.html
                │   ├── queryBuilder.js
                │   └── queryBuilder.js-meta.xml
                │
                └── resultsDisplay/     # Output Component
                │   ├── __tests__
                │   ├── resultsDisplay.html
                │   ├── resultsDisplay.js
                │   └── resultsDisplay.js-meta.xml
                │
                └── reportsOnFiles/     # Container Component
                    ├── __tests__
                    ├── queryBuilder.html
                    ├── reportsOnFiles.js
                    └── reportsOnFiles.js-meta.xml

```

### Security

This application adheres to strict Salesforce security standards:

- Enforces Object & Field Level Security: Users cannot see data they don't have access to. (Not useful on Standard Attachment and ContentDocument entities, but it has been added for future feature additions)
- SOQL Injection Protection: All user inputs are escaped and sanitized before query execution.

<p align="right">(<a href="#table-of-contents">back to top</a>)</p>

## Roadmap

- [ ] Have the list of fields display label names instead of API names
- [ ] Add an opiton to have parent object dropdown/picklist alongside the file entity
- [ ] Refine the filter condition UI element
  - [ ] Make the value field reactive to the data type of the field selected
  - [ ] Improve checks that validates the value field

<p align="right">(<a href="#table-of-contents">back to top</a>)</p>

<!--
See the [open issues](https://github.com/othneildrew/Best-README-Template/issues) for a full list of proposed features (and known issues)
## Contact
Your Name - [@your_twitter](https://twitter.com/your_username) - email@example.com
Project Link: [https://github.com/your_username/repo_name](https://github.com/your_username/repo_name)
<p align="right">(<a href="#table-of-contents">back to top</a>)</p>
-->
