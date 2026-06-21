# Digital Afterlife Manager

A full-stack database dashboard for managing and analyzing a digital estate transfer system. The project combines a SQL Server schema with a modern Next.js interface for running curated business queries, reviewing asset ownership, tracking beneficiaries, and monitoring transfer readiness.

## Overview

Digital Afterlife Manager is designed as a portfolio/demo project for a full-stack interview. It shows how a normalized relational database can power a clean client-facing analytics dashboard.

The application focuses on:

- Digital asset inventory management
- Beneficiary and access policy tracking
- Trigger event and legal authority workflows
- Financial, cloud storage, and social media asset reporting
- SQL Server-backed analytics through a Next.js API

## Features

- Modern responsive dashboard UI
- SQL query catalog with search and category filters
- Live query execution through API routes
- Result tables with formatted values
- Automatic quick charts for numeric result sets
- Copy SQL and export CSV actions
- Friendly loading and database error states
- SQL Server schema and seed data included
- Lint, TypeScript, and production build ready

## Tech Stack

| Layer | Technology |
| --- | --- |
| Frontend | Next.js, React, TypeScript |
| Styling | CSS, responsive custom dashboard design |
| Charts | Recharts |
| Icons | Lucide React |
| Backend | Next.js API Routes |
| Database | Microsoft SQL Server |
| Database Driver | `mssql` |

## Project Structure

```text
.
├── afterlife-manager-app/
│   ├── src/
│   │   ├── app/
│   │   │   ├── api/queries/route.ts
│   │   │   ├── globals.css
│   │   │   ├── layout.tsx
│   │   │   └── page.tsx
│   │   └── lib/db.ts
│   ├── package.json
│   └── tsconfig.json
├── digital_afterlife_manager.sql
├── digital_afterlife_manager_mssql.sql
└── README.md
```

## Database Design

The database includes tables for:

- Users
- Digital assets
- Financial assets
- Cloud storage assets
- Social media assets
- Beneficiaries
- Access policies
- Trigger events
- Legal authorities
- Asset transfers
- Access logs
- Memory data

The MSSQL script also includes sample data and reporting views such as pending transfers, user asset inventory, and beneficiary access.

## Getting Started

### Prerequisites

- Node.js 20 or later
- npm
- Microsoft SQL Server
- SQL Server Management Studio or Azure Data Studio

### 1. Clone the repository

```bash
git clone https://github.com/Rahim36712/AFTER_LIFE-_MANAGER-.git
cd AFTER_LIFE-_MANAGER-/afterlife-manager-app
```

### 2. Install dependencies

```bash
npm install
```

### 3. Create the database

Open SQL Server Management Studio or Azure Data Studio and run:

```text
digital_afterlife_manager_mssql.sql
```

This creates the `DigitalAfterlifeManager` database, tables, views, triggers, and sample records.

### 4. Configure environment variables

Create `afterlife-manager-app/.env.local`:

```env
DB_USER=your_sql_user
DB_PASSWORD=your_sql_password
DB_SERVER=localhost
DB_DATABASE=DigitalAfterlifeManager
```

### 5. Run the development server

```bash
npm run dev
```

Open:

```text
http://localhost:3000
```

## Available Scripts

Run these commands inside `afterlife-manager-app`.

```bash
npm run dev
npm run build
npm run start
npm run lint
```

## Demo Workflow

For a full-stack demo interview, a strong flow is:

1. Show the database schema and explain the relationships between users, digital assets, beneficiaries, trigger events, and transfers.
2. Start the Next.js app and open the dashboard.
3. Use the query catalog to run estate summary, asset distribution, pending transfers, and beneficiary reports.
4. Show the SQL preview to explain how the frontend maps to real database queries.
5. Export results as CSV to demonstrate a practical client-facing feature.
6. Briefly mention the API route and database connection layer.

## Validation

The app has been checked with:

```bash
npm run lint
npm run build
npm audit --audit-level=moderate
```

## Notes

- `.env.local`, `node_modules`, `.next`, and local logs are intentionally ignored.
- If queries fail in the UI, confirm SQL Server is running and listening on the configured server/port.
- The default local configuration expects SQL Server on `localhost` and the database name `DigitalAfterlifeManager`.

## Author

Rahim  
GitHub: [Rahim36712](https://github.com/Rahim36712)
