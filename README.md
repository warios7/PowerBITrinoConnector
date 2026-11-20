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

This experimental Windows Desktop build uses Trino's external authentication challenge. The coordinator handles the identity provider, its registered callback and scopes. The connector retrieves the resulting token from the gateway. The Basic gateway credential option is still present. The native Aad implementation remains on `feature/entra-id-oauth`.

## Instructions

1. In a Windows checkout, select `codex/trino-managed-oauth-test`. Keep the installed Aad package outside the custom connectors directory as a rollback copy.
2. Use the existing ignored `Trino/entra.local.json` if its `GatewayOrigin` matches your gateway. This branch reads only that field. For a fresh build, copy `entra.example.json` to `Trino/entra.local.json` and enter the HTTPS origin. Both the browser initiation URL and token server in Trino's challenge must use that origin.
3. From the repository root start the test page with Windows PowerShell. Leave this terminal open through sign-in. The command serves only the included static sign-in page on IPv4 loopback. If the port is occupied, stop here and resolve the conflict before testing.

   ```powershell
   .\desktop-login\Start-TrinoLogin.ps1
   ```

4. Open the **Trino** subfolder in VS Code and run **Build connector project using MakePQX**. Close Desktop and install the rebuilt `Trino/bin/AnyCPU/Debug/Trino.mez` in the user's Desktop custom connectors directory. Keep one Trino connector in that directory.
5. Open a blank report. Clear the previous credential for the test gateway in **Data source settings**. Select **Get Data → Trino**, enter the same gateway host and HTTPS port as in DBeaver, leave User empty, and enter `SELECT current_user`. Choose **Trino browser sign-in (test)** (some versions may display **Organizational account**).
6. In the Power BI sign-in window select **Open Trino sign-in**. If the link does not open a second window, copy its target into your own browser. After Trino confirms success, return to the first window and choose **Finish in Power BI**. The connector checks the returned state and polls the token URL from the same challenge.
7. Confirm the query returns your expected individual username. Close the local page server with Ctrl+C. For this prototype restart interactive sign-in on token expiry. Windows callback handling, credential storage, token expiry, live queries and gateway refresh require deployment testing.

If the local page never opens, check the server terminal and whether the embedded browser permits HTTP loopback. A working page in a normal browser only verifies the local listener. If the gateway lacks a challenge URL or advertises another origin, the connector stops. If the browser shows Trino success but Power BI remains in the sign-in window after **Finish in Power BI**, record which step failed. Keep complete challenge URLs, callback URLs and tokens out of reports.

## Power BI Service
Install the same configured package in the custom connector directory on every gateway cluster member. Give the gateway service account read access, reload the gateway service during an approved window, and enable custom connectors for the cluster. Create a **Trino** gateway connection with the identical host and port and select **Basic**. Enter the dedicated least-privilege Trino account in the gateway credential dialog. Bind the semantic model to that connection, run a refresh, then verify a scheduled refresh and the service-account identity in Trino's query history. For rollback, restore the previous package on each host and reload the affected applications. [Gateway setup](https://learn.microsoft.com/en-us/power-bi/connect-data/service-gateway-custom-connectors)

## Power BI Report Server
Custom connectors are currently not supported in Power BI Report Server environments. You can find a list of all supported data sources [here](https://docs.microsoft.com/en-us/power-bi/report-server/data-sources).

## Support
In case you encounter any issues while installing or loading data, just open an issue or feel free to reach out to info@creativedata.io.

## Releases

**Trino-managed OAuth test branch** — Experimental two-window Desktop sign-in with a loopback completion page. Windows integration tests are pending.

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
