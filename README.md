DEPRECATED: LWC components were half baked and violated almost all the LWC directives.
Newer version at <a href="https://github.com/MriteshAdak/Search-Files-and-Attachments" />

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
<a href="https://login.salesforce.com/packaging/installPackage.apexp?p0=04tWU000000QopBYAS">Install Package</a>

1. Click the link above.
2. Log in to your Salesforce Org.
3. Select "Install for All Users".
4. Click <strong>Install</strong>.

if prompted for installation key, use the following:
test1234

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
2. Click on "Reports on Attachments". (Navigate to 'R' section)
3. Click Manage Assignments > Add Assignment.
4. Select the users and click Assign.

Note: The Permission Set grants access to the necessary Apex classes and Lightning components required for the application to function properly. System Administrators typically have these permissions by default, but other user profiles will require this explicit assignment to use the tool.

A demo of how to assign a permission set to a user can be found in the following video.<br>
<a href="https://youtu.be/Z6XlW5OlVmc">How to Add a Permission Set to a Salesforce User</a>

<p align="right">(<a href="#table-of-contents">back to top</a>)</p>

<!-- USAGE EXAMPLES -->

## Usage

1. Navigate to the App Launcher.
2. In the search bar type "Search Files & Attachments" and open the tab.
3. Once in the app, select the Object (Attachment or Content Document).
4. Select the Fields you wish to see.
5. (Optional) Add Filters or Change Limit.
6. Click Execute Query.

<p align="right">(<a href="#table-of-contents">back to top</a>)</p>

## The Process and the Outcome (So Far..)

### Architecture

This project follows an Enterprise Layered Architecture of SF (Model-View-Controller):

- LWC: Handles UI and Event Delegation (queryBuilder, resultsDisplay).
- Apex Controllers: Entry points for business logic (QueryController).
- Service Layer: Handles Security logic (SecurityService).
- Domain Layer: Handles SOQL construction (SoqlQueryBuilder).
- Utility and DTO Layer: Shared helpers and transfer objects (Utils, QueryFilterDto, SchemaFieldOption).

<br>
The directory structure of the Application is shown below:

```
Reporting-on-Attachments-Salesforce/
├── assets/
├── config/
│   └── project-scratch-def.json
├── force-app/
│   └── main/
│       └── default/
│           ├── classes/
│           │   ├── AttachmentQueryController.cls
│           │   ├── QueryController.cls
│           │   ├── QueryFilterDto.cls
│           │   ├── SchemaFieldOption.cls
│           │   ├── SecurityService.cls
│           │   ├── SoqlQueryBuilder.cls
│           │   ├── Utils.cls
│           │   └── Tests/
│           ├── flexipages/
│           │   └── Reports_On_Files.flexipage-meta.xml
│           ├── lwc/
│           │   ├── queryBuilder/
│           │   │   ├── __tests__/
│           │   │   ├── queryBuilder.html
│           │   │   └── queryBuilder.js
│           │   ├── reportsOnFiles/
│           │   │   ├── __tests__/
│           │   │   ├── reportsOnFiles.html
│           │   │   └── reportsOnFiles.js
│           │   └── resultsDisplay/
│           │       ├── __tests__/
│           │       ├── resultsDisplay.html
│           │       └── resultsDisplay.js
│           ├── permissionsets/
│           │   └── Reporting_On_Files.permissionset-meta.xml
│           └── tabs/
│               └── Reports_On_Files.tab-meta.xml
├── manifest/
│   └── package.xml
└── scripts/
    ├── apex/
    └── soql/
```

### Known Issues and Limitations

- The applicaiton currently lacks uniform error handling and user feedback for various failure scenarios (e.g., no results, query errors, etc.).
- The SOQL query construction logic does not yet support logical operators (AND/OR) between filter conditions, which limits the complexity of queries that can be built through the UI.
- The code structure and organization are still in the early stages of development, and there is room for improvement in terms of modularity, separation of concerns, and adherence to best practices in Apex and LWC development.
- The application currently does not support pagination for query results, which could lead to performance issues when dealing with large datasets.
- The validation logic for user inputs in the filter conditions is basic and could be enhanced to provide better guidance and error prevention for users when building their queries.
- Parent object fields are not currently supported in the field selection for filter conditions, which limits the ability to create more complex queries that involve related objects.

<p align="right">(<a href="#table-of-contents">back to top</a>)</p>

## Roadmap

- [ ] Refine the application structure. (ongoing)
- [ ] Add a select menu for fields selection in where clause.
- [ ] Add support for defining logical operators for the filter conditions.
- [ ] Improve the validation logic of the user imputs in the filter conditions.

<p align="right">(<a href="#table-of-contents">back to top</a>)</p>
