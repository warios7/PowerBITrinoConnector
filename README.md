# Power BI Trino
A Microsoft Power BI Custom Connector for importing Trino data into Power BI to interactively transform, visualize and analyze data. 
- [Trino Client REST API](#trino-client-rest-api)
- [Authentication](#authentication)
- [Instructions](#instructions)
- [Power BI Service](#power-bi-service)
- [Power BI Report Server](#power-bi-report-server)
- [Support](#support)
- [Releases](#releases)

## Trino client REST API
The connector communicates directly with the [Trino client REST API](https://trino.io/docs/current/develop/client-protocol.html) to retrieve data and provides some pararmeters to configure. Client timeout errors (ABANDONED_QUERY) can be fixed by changing the value of query.client.timeout in the coordinators config.properties file (the default is 5 minutes).

## Authentication
Use **Organizational account** in Desktop and **Basic** on the on-premises gateway. Both send credentials over HTTPS. Trino selects the session user from its authenticated identity. The optional User parameter applies only to anonymous connections.

## Instructions

1. On your Windows development machine, check out `feature/entra-id-oauth`. From the repository root, copy the example to the ignored local build input with PowerShell.

   ```powershell
   Copy-Item entra.example.json Trino/entra.local.json
   notepad Trino/entra.local.json
   ```

2. Fill in only these four non-secret settings. Every recipient of the built connector can read them.

   | Field | Where to find the value |
   | --- | --- |
   | AuthorizationUri | In Microsoft Entra ID, open the resource application's Overview. Use its **Directory (tenant) ID** in the URL pattern in the example. The pattern follows Microsoft's native Power Query Aad configuration for the public cloud. |
   | Resource | Open **App registrations → the Trino resource application → Expose an API → Application ID URI**. Copy the exact registered value. Its application (client) ID is often part of the URI. |
   | Scope | Under **Expose an API**, use the short name of an enabled delegated permission for this API. Alternatively use `.default` when the intended permissions have been preauthorized. |
   | GatewayOrigin | Enter the HTTPS scheme, hostname and port users enter for the Trino gateway, e.g. `https://trino.example.invalid:8443`. Omit paths, queries and credentials. |

   Use the coordinator's OAuth client ID to identify the trusted audience. Confirm that the resource application's access token has an accepted audience and issuer. Check the configured principal claim (email in this deployment) and whether the coordinator validates tokens locally or through UserInfo. The Web UI can request tokens for a different resource. Microsoft Graph scopes belong to Graph. For the Desktop flow, the Trino API must expose a delegated permission and authorize the Microsoft Power Query Desktop client for it. The native Aad flow handles the client identifier, token endpoint and renewal. [Microsoft Entra setup](https://learn.microsoft.com/en-us/power-query/configure-microsoft-entra-for-connector) · [Trino OAuth settings](https://trino.io/docs/current/security/oauth2.html)

3. Install the Microsoft Power Query SDK in VS Code on Windows. Open the **Trino** subfolder, run **Tasks: Run Build Task**, and choose **Build connector project using MakePQX**. The SDK runs MakePQX.exe. The new package should appear at `Trino/bin/AnyCPU/Debug/Trino.mez`. [SDK guide](https://learn.microsoft.com/en-us/power-query/install-sdk)

4. From the repository root, verify the package contains the exact local settings and source without displaying either. Save the verified build under the commit ID.

   ```powershell
   Add-Type -AssemblyName System.IO.Compression.FileSystem
   $package = 'Trino/bin/AnyCPU/Debug/Trino.mez'
   $zip = [IO.Compression.ZipFile]::OpenRead((Resolve-Path $package))
   try {
       foreach ($name in 'entra.local.json', 'Trino.pq') {
           $entry = $zip.GetEntry($name)
           if (!$entry) { throw "Missing package entry $name" }
           $stream = $entry.Open()
           try {
               if ((Get-FileHash -InputStream $stream).Hash -ne (Get-FileHash "Trino/$name").Hash) {
                   throw "Package differs from build input $name"
               }
           } finally { $stream.Dispose() }
       }
   } finally { $zip.Dispose() }
   $version = git rev-parse --short HEAD
   Copy-Item $package "Trino/bin/Trino-$version.mez"
   ```

5. Back up the installed connector outside the Desktop and gateway connector folders. The original fork package is also preserved at `rollback/Trino.mez`. Install one new copy as `Trino.mez` in the Windows user's `Documents\Power BI Desktop\Custom Connectors` folder. Use your organization's connector trust settings and restart Desktop.

6. Select **Get Data → Trino**. If Desktop reuses an older credential, clear the saved permission for the test host and port under **Data source settings**. Choose **Organizational account**, sign in with MFA, and leave User empty. Run `SELECT current_user`, browse catalogs and schemas, and load a known multi-page result. Repeat after token expiry. Compare the session user and row count with a trusted Trino client.

7. Populate the required and optional fields to communicate with your Trino environment and hit OK to either scan your objects or to execute a specific SQL query if provided:

    ![Power BI Trino Connector Parameters](Trino/img/ParaConnector.PNG)

8. Choose the desired authentication mechanism:

    ![UsernamePassword](Trino/img/Basic.png)

9. Choose the desired objects you want to import and click "Load" if you want to import data directly. Clicking "Transform Data" allows you to transform data before actually importing it into the analytical storage engine:

    ![Power BI Trino Connector Scanner](Trino/img/ScanConnector.JPG)

## Power BI Service
Install the same configured package in the custom connector directory on every gateway cluster member. Give the gateway service account read access, reload the gateway service during an approved window, and enable custom connectors for the cluster. Create a **Trino** gateway connection with the identical host and port and select **Basic**. Enter the dedicated least-privilege Trino account in the gateway credential dialog. Bind the semantic model to that connection, run a refresh, then verify a scheduled refresh and the service-account identity in Trino's query history. For rollback, restore the previous package on each host and reload the affected applications. [Gateway setup](https://learn.microsoft.com/en-us/power-bi/connect-data/service-gateway-custom-connectors)

## Power BI Report Server
Custom connectors are currently not supported in Power BI Report Server environments. You can find a list of all supported data sources [here](https://docs.microsoft.com/en-us/power-bi/report-server/data-sources).

## Support
In case you encounter any issues while installing or loading data, just open an issue or feel free to reach out to info@creativedata.io.

## Releases

**Entra development branch** — Native organizational sign-in for Desktop, independently stored gateway Basic credentials, and authenticated same-origin pagination. Windows and live deployment acceptance tests are pending.

**January 2025**
- 2025-01-08: Adding [targetResultSize](https://trino.io/docs/current/release/release-0.213.html) as optional parameter to control response data size

**July 2024**
- 2024-07-21: Supporting structural data types including ARRAY, MAP, ROW, and JSON

**April 2024**
- 2024-04-04: Optimizing data type conversion for date and time

**February 2024**
- 2024-02-07: Native SQL Query parameter added

**April 2023**
- 2023-04-26: OAuth added

**October 2021**
- 2021-10-15: First Release
