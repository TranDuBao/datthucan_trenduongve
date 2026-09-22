## ABSOLUTE CHANGE SCOPE RULE — CRITICAL

NEVER make changes outside the explicit scope of the user's request.

If the user asks to:
"connect data from database"

the task means:
"connect the existing UI to real database-backed data."

It does NOT mean:
- redesign the UI
- restore old UI
- rewrite components
- change layout
- change styling
- replace navigation
- refactor the application
- recreate screens

If a change is not necessary to fulfill the requested task,
DO NOT make that change.

## 1. Database Safety & Integrity Rule (CRITICAL)

- NEVER run commands, SQL scripts, migrations, or ORM configurations
  that drop, delete, truncate, reset, or recreate the database or
  existing tables.

- NEVER use:
  - synchronize: true
  - dropSchema: true
  - prisma db push --force-reset
  - prisma migrate reset
  - DROP DATABASE
  - DROP TABLE
  - TRUNCATE TABLE
  - DELETE without an explicit WHERE condition

- NEVER modify or delete existing production/user data unless
  explicitly requested by the user.

- Database migrations must be additive and backward-compatible
  whenever possible.

- Before modifying an existing table, inspect the current schema
  and existing relationships first.

- Never assume a database schema. Read the existing models,
  migrations, entities, or schema definitions before making changes.

- Do not recreate existing tables just to fix a schema problem.

- Preserve existing primary keys, foreign keys, indexes and constraints
  unless the user explicitly requests a structural change.

- If a potentially destructive database operation is genuinely required,
  STOP and ask for explicit confirmation before executing it.

  ## 2. Code File Length Limit

- NEVER write any source code file exceeding 1000 lines.

- Prefer files below 500 lines whenever practical.

- If a file approaches 700-800 lines, consider splitting it
  into smaller focused modules.

- Do not split files artificially just to satisfy the line limit.

- Each file should have one clear responsibility.

- Controllers, services, repositories, models, DTOs and utilities
  should remain modular and focused.

  ## 3. Architecture & Separation of Concerns

- Mobile App must follow MVC (Model-View-Controller).

- Backend must follow a clean modular architecture.

- Controllers handle HTTP/request-response concerns only.

- Services contain business logic.

- Repositories handle database access.

- DTOs define and validate input/output data structures.

- Models/Entities represent persistent data.

- Routes should only define routing and connect requests
  to the appropriate controllers.

- Do not place business logic directly inside routes.

- Do not place database queries directly inside controllers.

- Do not duplicate business logic across multiple controllers.

- Reuse existing services, utilities and components whenever possible.

- Before creating a new module, check whether an existing module
  already provides the required functionality.

- Avoid unnecessary abstraction and over-engineering.

## 4. Existing Code Preservation

- NEVER rewrite or replace working code unnecessarily.

- Before modifying a feature, inspect the existing implementation
  and understand its dependencies.

- Preserve existing functionality unless the user explicitly asks
  to change it.

- Do not rename, move or delete files without a valid reason.

- Do not change public APIs, routes, database contracts or response
  formats unless required by the task.

- When modifying shared components, verify all existing usages
  before changing their interface.

- Prefer minimal, targeted changes over large-scale rewrites.

- Do not introduce a new library when the existing project already
  has a suitable solution.

  ## 5. API Contract & Compatibility

- Do not change existing API endpoints without explicit reason.

- Preserve existing HTTP methods, route paths and response structures.

- Do not rename API fields without checking all consumers.

- Backend changes must consider existing mobile clients.

- Validate request parameters and payloads at the API boundary.

- Return consistent response formats across the API.

- Handle HTTP status codes correctly.

- Do not silently change API behavior to make a single screen work.

- When an API contract must change, update all affected clients
  and related DTOs/controllers/services.

  ## 6. Error Handling & Logging

- Never silently swallow errors.

- Do not use empty catch blocks.

- Errors must be handled at the appropriate architectural layer.

- User-facing errors must be clear and understandable.

- Internal errors must not expose sensitive information.

- Do not expose stack traces, database errors, tokens,
  passwords or internal implementation details to clients.

- Use structured and meaningful logging.

- Avoid excessive console.log statements in production code.

- Remove temporary debugging logs before completing a task.

## 7. Security Rules (CRITICAL)

- NEVER hardcode passwords, API keys, JWT secrets,
  database credentials or private tokens.

- NEVER commit .env files containing secrets.

- Use environment variables for sensitive configuration.

- NEVER expose secrets in frontend/mobile source code.

- Validate and sanitize user input.

- Do not trust client-side validation alone.

- Authentication and authorization must be enforced server-side.

- Never log passwords, tokens, authorization headers,
  payment credentials or sensitive personal information.

- Do not disable authentication or authorization checks
  just to make development easier.

- Do not use insecure development credentials in production.

## 8. Dependency Management

- Prefer existing project dependencies before installing new ones.

- NEVER install a new dependency without first checking whether
  the existing project already provides equivalent functionality.

- Avoid unnecessary dependencies.

- Do not upgrade major dependency versions unless explicitly required.

- When adding a dependency, verify compatibility with the existing
  framework and runtime.

- Remove unused dependencies when they are no longer required.

## 9. Git Safety

- NEVER run destructive Git commands without explicit user approval.

- NEVER use:
  - git reset --hard
  - git clean -fd
  - git checkout -- .
  - git restore .
  - git push --force
  - git push --force-with-lease

  unless explicitly requested by the user.

- NEVER overwrite or discard the user's uncommitted changes.

- Before modifying files, inspect the current Git status.

- Preserve existing branches and commits.

- Do not rewrite Git history unnecessarily.

- Do not commit generated files, secrets, build artifacts
  or environment files unless explicitly required.

  ## 10. Testing Requirements

- Every new feature must be tested before completion.

- Bug fixes should include a verification step.

- Do not mark a task as complete based only on successful compilation.

- Test relevant:
  - happy paths
  - validation errors
  - authentication/authorization
  - edge cases
  - empty states
  - loading states
  - error states

- Do not remove existing tests just to make the test suite pass.

- Do not modify tests simply to hide a broken implementation.

- When changing shared functionality, verify existing consumers.

## 11. UI/UX Guidelines

- UI must prioritize usability, clarity and consistency.

- Follow the existing application's visual language.

- Do not redesign unrelated screens when implementing a specific feature.

- Reuse existing:
  - colors
  - typography
  - spacing
  - icons
  - buttons
  - components
  - animations

- Do not introduce excessive:
  - gradients
  - glassmorphism
  - shadows
  - blur
  - animations
  - rounded cards
  - decorative elements

- UI should look like a production application,
  not an AI-generated design concept.

- Maintain consistent spacing and alignment.

- All interactive elements must have appropriate touch targets.

- Support loading, empty, success and error states.

- Respect safe areas and different mobile screen sizes.

- Animations should improve feedback and usability,
  not distract the user.

- Prefer subtle, natural animations over exaggerated effects.

## 12. Performance

- Avoid unnecessary API requests.

- Avoid unnecessary database queries.

- Avoid unnecessary widget/component rebuilds.

- Do not perform expensive operations on the UI/main thread.

- Optimize images and large assets appropriately.

- Avoid memory leaks.

- Do not introduce polling when event-driven or cached approaches
  are already available.

- Reuse existing caching mechanisms where appropriate.

## 13. Environment & Configuration

- Never assume a specific environment configuration.

- Inspect existing environment variables and configuration
  before modifying them.

- Do not overwrite existing .env files.

- Do not change ports, database URLs, API URLs or deployment
  configuration without checking existing dependencies.

- Development, staging and production configurations must remain
  clearly separated.

- Never use production credentials for local development.

## 14. Agent Workflow

Before making changes:

1. Inspect the existing project structure.
2. Identify the relevant files and modules.
3. Understand existing dependencies and data flow.
4. Check whether the requested functionality already exists.
5. Make the smallest reasonable change.
6. Run appropriate validation/tests.
7. Review the final changes for unintended side effects.

Do not modify unrelated files.

Do not refactor unrelated code while implementing a feature.

If requirements are ambiguous and the decision could affect
architecture, database, security or existing functionality,
ask for clarification before making a risky change.

Never claim that a feature works without actually verifying it.

## DATA SOURCE & UI PRESERVATION — CRITICAL

- All dynamic application data MUST come from the actual database
  through the existing backend/API/data layer.

- NEVER hardcode fake, mock, placeholder or manually-created
  business data directly in the source code when real database data
  is available.

- NEVER create fake arrays, objects, JSON data, static lists or
  fallback business data merely to make the UI look populated.

- Examples of prohibited patterns:

  const users = [
    { id: 1, name: "John", ... }
  ];

  const products = [
    { name: "Sample Product", price: 100000 }
  ];

  const bookings = [...]
  
  when these values are supposed to come from the database.

- Static UI configuration is allowed when it is genuinely UI-related,
  such as:
  - labels
  - icons
  - colors
  - spacing
  - animation configuration
  - validation messages
  - UI state definitions

- Business data MUST NOT be confused with UI configuration.

--------------------------------------------------
DATA FLOW
--------------------------------------------------

For dynamic data, follow this flow:

Database
    ↓
Repository / ORM
    ↓
Service
    ↓
Controller / API
    ↓
Mobile API Client
    ↓
Model
    ↓
View / UI

- Reuse the existing data flow whenever it already exists.

- Do NOT bypass the backend/API and directly connect the mobile
  application to the database unless the existing architecture
  explicitly requires it.

- Before creating new data-fetching logic, inspect the existing
  API, services, repositories, models and API clients.

- If an existing API already provides the required data,
  reuse that API.

--------------------------------------------------
NO FAKE DATA FALLBACK
--------------------------------------------------

- If the database contains no data, display the appropriate
  empty state.

- If the API fails, display the appropriate error state.

- If data is loading, display the appropriate loading state.

- NEVER replace missing database data with fake data.

- NEVER silently fall back to hardcoded sample data.

- NEVER invent database records to make a screen appear complete.

--------------------------------------------------
UI PRESERVATION — CRITICAL
--------------------------------------------------

When the task is related to data integration, API integration,
database integration, bug fixing or business logic:

- DO NOT redesign the existing UI.

- DO NOT restore an older UI.

- DO NOT replace existing layouts.

- DO NOT replace existing components.

- DO NOT change colors, typography, spacing, navigation,
  animations or visual structure unless explicitly requested.

- DO NOT modify unrelated UI files.

- The existing UI is considered APPROVED and must be preserved.

- Only connect the existing UI to the real data source.

- If the UI currently contains a component designed to display
  dynamic data, modify only the minimum code necessary to bind
  that component to the real data.

--------------------------------------------------
SCOPE CONTROL
--------------------------------------------------

Before modifying files:

1. Identify exactly what the user requested.
2. Identify which files are necessary for the requested change.
3. Do not modify unrelated files.
4. Do not perform UI redesign unless the user explicitly asks
   for a UI redesign.
5. Do not refactor unrelated code.
6. Do not restore previous versions of components.
7. Do not replace working components with newly generated ones.

If the requested functionality cannot be implemented without
changing the UI architecture, STOP and explain the reason before
making the architectural change.

--------------------------------------------------
EXISTING UI IS THE SOURCE OF TRUTH
--------------------------------------------------

Unless the user explicitly says:

"redesign UI"
"change UI"
"improve UI"
"rebuild UI"
"create a new UI"

assume that the existing UI is intentional and must be preserved.

When implementing backend/database/data integration:

KEEP:
- existing layout
- existing components
- existing navigation
- existing styling
- existing animations
- existing interactions

CHANGE ONLY:
- data source
- API integration
- state management required for the data
- loading state if necessary
- error state if necessary
- empty state if necessary