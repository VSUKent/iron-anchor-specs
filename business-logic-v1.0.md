# Business Logic

## Project Details
- Company/Team Name: Landsome
- Project Code Name: Iron Anchor
- Project Short Code: IA
- Short Description: Centralizes local real estate and land listings in one searchable platform.
- Long Description:
  Landsome is a mobile and web application that brings every piece of land for sale or rent in Baybay City into one map-based, searchable platform. Today, buying or renting land in Baybay depends on word of mouth, scattered social media posts, and roadside "For Sale" signs, which are slow, inconsistent, and often missing key details. Landsome lets landowners post their property with its exact location, size in hectares, price, and full details, while buyers, renters, and Baybay natives or OFWs living abroad can browse, filter, save, and contact owners directly. The platform is exclusive to Baybay City, supports barangay-based search, and includes a verification and reporting system to reduce fraud and build trust in local land transactions.

## User Levels

> Note: Modify/rename the list of users based on the actual users that you expect to use the system.

| User Level              | Description |
| ----------------------- | ----------- |
| A. System Administrator | Maintains/overrides system/server configurations and performs regular backups. |
| B. Administrator        | Manages the general settings of the system and generates periodic system analytics and reports. |
| C. Moderator            | Reviews new and reported listings, verifies submitted land documents, awards the verified badge, and removes fraudulent or misleading posts. |
| D. Contributor          | Registered users (landowners, buyers, and renters) who post and manage land listings, save favorites, receive alerts, and message owners. |
| E. Guest                | Users who do not log in, but view limited contents on the app/web. |

## System Requirements

1. The app shall allow the users to authenticate using Google Sign-In integration.
2. The app shall allow the users to post a land listing with its title, pinned map location, size (hectares or square meters), price, sale or rent status, photos, and full details (land type, road access, water source, electricity, terrain, crops or trees, and document status to avoid scams).
3. The app shall allow the users to search and filter listings by barangay, price range, size, land type, and sale or rent, on either a map or a list view.
4. The app shall allow guests to view limited listing information (such as photos, price, size, and approximate location) without logging in, and prompt them to sign in to see full details and contact the owner.
5. The app shall allow the users to save favorite listings, compare them side by side, and receive alerts when new land is posted in selected barangays.
6. The app shall allow the users to message or send inquiries to a landowner directly within the app.
7. The app shall allow the users to report suspicious or misleading listings, and allow moderators to review reports, verify submitted documents, and remove fraudulent listings.
8. The app shall allow administrators to manage general settings (such as barangay list, land types, and listing rules) and generate periodic analytics and reports.
9. The app shall allow the system administrator to configure the server and perform regular backups of the system and its data.
10. The app shall ensure users that the documents contains privacy is secure and safe.

## Required Solution Layers

1. Security and privacy by design. Data Privacy Act compliance, location protection, retention limits, no per-user trails, aggregation thresholds, and consent for any data resale.

## MVP Features and Access

> See the User Levels table for reference.

| Feature                                              | Access      |
| ---------------------------------------------------- | ----------- |
| 1. Browse and search land listings (map, filters)    | A,B,C,D,E   |
| 2. Post and manage land listings                     | A,B,C,D     |
| 3. Save favorites and receive new-listing alerts     | A,B,C,D     |
| 5. Listing verification and report moderation        | A,B,C       |
| 6. Analytics, reports, and general system settings   | A,B         |
| 7. Server configuration and regular backups          | A           |

