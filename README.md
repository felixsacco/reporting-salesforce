<h1>Report app for Attachments and Files in Salesforce</h1>

<!-- TABLE OF CONTENTS -->
## Table of Contents
<ul>
    <li><a href="#about-the-project">About The Project</a></li>
    <li><a href="#getting-started">Getting Started</a></li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#the-process-and-the-outcome-so-far">The Process and the Outcome</a></li>
    <li><a href="#roadmap">Roadmap (WIP)</a></li>
</ul>

<!-- ABOUT THE PROJECT -->
## About The Project

Salesforce, as one of the leading cloud-based Customer Relationship Management (CRM) platform, provides organizations with cloud instances with their applications for managing customer data, sales processes, and business operations. Despite its extensive data management and analytics capabilities, the inbuild reporting feature does not have full suppport for the legacy Attachments entity and these objects often have essential files for business compliances especially those that still have their data in legacy components.

This project proposes the development of a tool aimed at addressing the well-documented reporting deficiencies associated with Salesforce's file-based data entities. Drawing upon one of the concerns articulated in the Salesforce Idea Exchange post titled “Reporting on Notes & Attachments,” the tool seeks to tackle the challenge of generating reports on legacy Attachment object while also supporting all file entiites (Attachment, ContentDocument), to help users be in alignment with the storage limits established for their Salesforce Cloud Platform. Given that the entities in question are legacy components—alongside newer entities—that Salesforce no longer intends to support, it is imperative to note that legacy components remain integral to numerous enterprise applications. The abitliy to have reports on all entities that counts towards the 'File Storage' limit could facilitite individual file storage management by helping users proactively analyze files and their relevance thereby reducing any unnecessary costs incurred from increasing storage limits.

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
2. Click on "Reporting On Files". (Navaigate to 'R' section)
3. Click Manage Assignments > Add Assignment.
4. Select the users and click Assign.

Demo of how to assign a permission set to a user can be found in the following video.<br>
<a href="https://youtu.be/Z6XlW5OlVmc">How to Add a Permission Set to a Salesforce User</a>

<p align="right">(<a href="#table-of-contents">back to top</a>)</p>


<!-- USAGE EXAMPLES -->
## Usage

1. Navigate to the App Launcher.
2. Search for "Reports on Files" 
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
Directory structure of the Application shown below:

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
- Enforces Object & Field Level Security: Users cannot see data they don't have access to.
- SOQL Injection Protection: All user inputs are escaped and sanitized before query execution.

<p align="right">(<a href="#table-of-contents">back to top</a>)</p>

..... Future Roadmap in the works, the goal is to eventually make it look like a first party app and add more functionality to the output table, obviously branched .....

<!-- 
## Roadmap

- [x] Add Changelog
- [x] Add back to top links
- [ ] Add Additional Templates w/ Examples
- [ ] Add "components" document to easily copy & paste sections of the readme
- [ ] Multi-language Support
    - [ ] Chinese
    - [ ] Spanish

See the [open issues](https://github.com/othneildrew/Best-README-Template/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#table-of-contents">back to top</a>)</p>

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#table-of-contents">back to top</a>)</p>




## Contact

Your Name - [@your_twitter](https://twitter.com/your_username) - email@example.com

Project Link: [https://github.com/your_username/repo_name](https://github.com/your_username/repo_name)

<p align="right">(<a href="#table-of-contents">back to top</a>)</p>
 -->