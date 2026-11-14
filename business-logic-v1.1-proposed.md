# Business Logic Proposal (v1.1)

## 1) Product Positioning

Iron Anchor is a local-first marketplace for land listings in Baybay City. It turns fragmented and unreliable land opportunities into a single trusted directory where buyers, renters, and landowners can discover, evaluate, and transact with greater confidence.

The product is not a generic real-estate platform. It is deliberately narrow and local:

- Focus: land and property listings in Baybay City
- Primary users: local landowners, buyers, renters, and Baybay-based families/OFWs seeking trusted land opportunities
- Core promise: faster discovery, clearer property details, and safer transactions through local verification and moderation

This positioning gives the MVP a clear reason to exist: reduce the friction and fraud risk of scattered listings while keeping the launch lean and easy to validate.

## 2) Problem Statement and Opportunity

Today, land transactions in Baybay City happen through informal channels:

- social media posts
- word-of-mouth referrals
- roadside signage
- unverified listings with incomplete or inconsistent details

This creates three major pain points:

1. Buyers cannot quickly compare reliable options.
2. Landowners struggle to reach interested buyers or renters.
3. Trust is weak because listings are not consistently verified or moderated.

Iron Anchor solves this by consolidating land listings into one searchable, map-based platform with verification and reporting built in.

## 3) MVP Goal

The MVP must prove that a local user can:

- discover land opportunities quickly,
- understand the property before contacting the owner,
- trust the listing enough to inquire,
- and help moderators remove misleading or fraudulent content.

The MVP is successful when it helps users discover and evaluate land listings without relying on scattered informal channels.

## 4) Target Users

### A. Landowner
- Wants to advertise a parcel quickly
- Needs a simple way to post, update, and manage listings
- Wants visibility with minimal manual effort

### B. Buyer / Renter
- Wants to search land options by area, price, and size
- Needs clear, trustworthy listing details
- Wants to contact the owner or ask questions without a long process

### C. Baybay native / OFW relative
- Often evaluates land from outside the city
- Needs a trusted source with map context and clear listing data
- Prefers strong local trust signals and moderation

### D. Moderator
- Reviews suspicious listings and reported content
- Confirms listing accuracy and document status
- Removes fraudulent posts and keeps trust intact

### E. Administrator
- Maintains local listing categories, barangay references, and system settings
- Reviews analytics and supports local operations

## 5) Core Value Proposition

Iron Anchor helps people transact land locally with confidence by combining:

- a searchable map and list interface,
- transparent listing details,
- trust signals through moderation and verification,
- and direct inquiry tools without exposing personal contact data too early.

This is the product’s strongest differentiator: it is local, map-based, and trust-first.

## 6) MVP Scope: Must-Have Features

The MVP should stay intentionally limited to the set of features that validate the business model and user behavior.

### 6.1 Browse and search land listings
- Browse listings on a map and in a list
- Search by barangay, land type, sale/rent status, price range, and acreage/size
- Filter results quickly without needing a full account
- View limited public listing details before login

### 6.2 Post and manage listings
- Landowners can create a listing with:
  - title
  - exact or approximate map pin
  - barangay
  - size (hectares or square meters)
  - price
  - sale or rent status
  - property photos
  - land type
  - supporting details (road access, water, electricity, terrain, crops/trees)
  - document status indicator
- Owners can edit or remove their own listings
- Listings can be marked draft or active

### 6.3 Listing trust and moderation
- Users can report suspicious or misleading listings
- Moderators review submissions and reports
- Moderators can verify document status and award a verified badge
- Moderators can hide, reject, or remove fraudulent listings

### 6.4 Save and follow opportunities
- Logged-in users can save favorite listings
- Users can receive new-listing alerts for selected barangays
- Users can compare saved listings in a simple side-by-side view

### 6.5 Direct inquiry flow
- Users can send inquiry messages to listing owners within the app
- Contact details are not exposed publicly by default
- Inquiry history is visible to the involved parties

### 6.6 Admin and operational controls
- Admin can manage a local list of barangays and land types
- Admin can configure site rules and moderation policies
- Admin can review reporting and basic analytics

## 7) Gaps in the Existing v1.0 Document

The current business logic is directionally strong, but it does not fully define the MVP needed for launch. The main gaps are:

1. No clear product positioning beyond a generic city listing directory.
2. No explicit MVP goal or success criteria.
3. No detailed user journeys for the main actions: search, post, inquire, report, and verify.
4. No clear distinction between what is required for launch and what is deferred.
5. No trust model for property verification and fraud reduction.
6. No operational workflow for moderators and admins.
7. No release-ready rules for privacy, document handling, and content moderation.
8. No statement of what the app is not, which helps prevent scope creep.

These gaps matter because they affect both product design and engineering prioritization.

## 8) Recommended MVP Business Rules

The following business rules should be explicit in the final MVP definition:

- Any listing must include a valid title, location, price, size, and status.
- A listing without a valid property photo or incomplete core info may remain draft until approved or completed.
- Reports should be reviewed by moderators within a defined service window.
- A verified badge is only awarded after moderator review and supporting document validation.
- Guests can browse listings but cannot access full contact or property detail screens without logging in.
- The platform should not claim legal guarantees or act as a licensed real-estate broker.
- The system should support local privacy expectations and avoid exposing exact personal information publicly.

## 9) Out-of-Scope for the MVP

To preserve time-to-market, the following should be intentionally deferred:

- online booking or deposit payments
- full legal document processing or notarization
- AI-powered listing recommendations
- advanced social networking features
- multi-city expansion beyond Baybay City
- real-time video calls or live property tours
- full marketplace wallet or escrow flow
- advanced analytics dashboards beyond essential admin reporting

These are valuable later, but they are not required to prove the core business model.

## 10) MVP Launch Criteria

The MVP should be considered ready when all of the following are true:

- Users can browse listings on map and list views
- Users can filter by core criteria without confusion
- Landowners can post and manage listings successfully
- Moderators can review reports and verify suspicious listings
- Guests are limited appropriately before sign-in
- Messaging and inquiry workflow works end-to-end
- Admins can update local configuration and review basic analytics
- Privacy and moderation expectations are documented and enforced

## 11) Success Metrics for Initial Validation

Track a small set of metrics to validate the MVP quickly:

- number of active listings
- number of new property posts per week
- number of saved favorites per user
- number of inquiries sent per listing
- number of reports and moderation turnaround time
- percentage of listings with verified status
- repeat usage from buyers and owners

These metrics are enough to prove adoption without adding unnecessary analytics infrastructure.

## 12) Recommended Final MVP Positioning Statement

Iron Anchor is the trusted local marketplace for land in Baybay City, designed to help landowners list properties, buyers discover reliable opportunities, and moderators protect the community from fraud.

It is simple, local, and operationally focused: discover land faster, verify it more easily, and move from interest to inquiry with less friction.

## 13) Final Recommendation

The v1.0 document provides the foundation, but it should be updated to emphasize the following before implementation:

- clear local value proposition
- strict MVP feature boundaries
- user flows that map to real business actions
- moderation and verification as a trust cornerstone
- simple launch metrics and no-scope for nice-to-haves

This keeps the product focused on the fastest path to real user value and market validation.
