## PROJECT CONTEXT — CRITICAL

This project is NOT a ride-hailing or taxi-booking application.

It is a smart food discovery application where users travel from
Point A to Point B and discover restaurants along or near their route.

Core features:
- Route-based restaurant discovery
- Take-away food/drink ordering
- Table reservation
- Cashless payment
- Real-time notifications/status

Technology may include:
- Flutter / React Native
- Node.js / NestJS / FastAPI
- PostgreSQL + PostGIS / MongoDB
- VietQR / PayOS / MoMo
- Socket.io

When interpreting user prompts, always use this project's business
domain and existing code as context.

Do NOT assume GPS, maps, routes or Socket.io mean ride-hailing,
taxi booking, driver management or vehicle dispatch.

The existing project implementation is the source of truth.

## NO SAMPLE DATA WITHOUT APPROVAL — CRITICAL

- NEVER create, insert, seed, generate or hardcode any sample, mock,
  demo, test, placeholder or dummy data unless the user has explicitly
  approved it first.

- This applies everywhere, with no exceptions:
  - database records (any table)
  - seed scripts, migrations containing data, SQL INSERT statements
  - API responses, hardcoded arrays, JSON files, fixtures
  - UI screens, providers, services and tests

- If data is missing, show the appropriate empty state. Do NOT add
  records to make a screen look populated.

- If you believe sample data is genuinely needed:
  1. STOP. Do not create it.
  2. Ask the user for approval, and state exactly what data you want
     to create, where it will be stored, how many records, and why.
  3. Wait for explicit confirmation ("yes", "approved", "duyệt").
  4. Only then create exactly what was approved, nothing more.
  5. Clearly label it as test data and tell the user how to remove it.

- Approval covers only the specific data described in the request.
  It does not give permission to create more data later.

- Silence, a vague request, or an unrelated request (for example
  "connect the data", "fix the bug", "add socket.io") is NOT approval.

- If unsure whether something counts as sample data, treat it as
  sample data and ask first.

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

- Mobile App must follow MVVM / Provider Layered Architecture:
  - Views/Screens handle UI presentation only (`lib/screens`, `lib/view`).
  - Providers (`ChangeNotifier`) handle state management and UI interaction logic (`lib/providers`).
  - Services handle API network requests and external integrations (`lib/services`).
  - Models represent data structures (`lib/models`).
  - Locator (`get_it`) manages dependency injection (`lib/common/locator.dart`).

- Backend must follow NestJS Modular & Layered Architecture:
  - Modules encapsulate related features (`src/modules/*`).
  - Controllers handle HTTP requests and response formatting (`*.controller.ts`).
  - Services contain core business logic (`*.service.ts`).
  - Entities (TypeORM) handle database schema mapping and persistence (`*.entity.ts`).
  - DTOs define and validate request/response data payloads (`dto/*`).

- Controllers handle HTTP/request-response concerns only.

- Services contain business logic.

- Repositories/Entities handle database access.

- DTOs define and validate input/output data structures.

- Models/Entities represent persistent data.

- Do not place business logic directly inside controllers or views.

- Do not place database queries directly inside controllers.

- Do not duplicate business logic across multiple controllers or providers.

- Reuse existing services, providers, utilities and components whenever possible.

- Before creating a new module or provider, check whether an existing one
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

### Mobile Loading UI Rule
- When coding in the mobile application (Flutter), ALL data loading states (menu, restaurant lists, dish items, order history, category filters, profile, etc.) MUST use Skeleton Loading (`widgets/skeleton/*`).
- EXCEPTION: The Home Screen (`lib/screens/home_screen.dart` and `lib/widgets/search_bar_widget.dart` for map/GPS route loading) MUST use standard loading indicators (`CircularProgressIndicator`), NOT skeleton loading.

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

## 15. Realtime / Socket.io (CRITICAL)

Applies to any task involving socket, realtime, live status, gateway, room, emit, or features that must stay in sync between the customer app, the restaurant side and the backend (order status, table reservation status, payment confirmation, in-app notifications).

### Purpose and boundaries
- Socket.io is used ONLY to push changes between customer app, restaurant side and backend.
- The database is the source of truth. Socket events notify about a change; they never replace stored data.
- Do NOT introduce ride-hailing concepts (driver, trip, dispatch, vehicle tracking). Location data is used only if the project already uses it, for restaurant discovery near the route.
- Do NOT redesign UI, rename endpoints or refactor unrelated code while adding realtime.

### Before writing code
- Search for an existing gateway, socket service, provider and event names (e.g. grep "socket", "gateway") and reuse/extend them.
- Do NOT create a second gateway or socket service if one exists.
- Check package.json / pubspec.yaml before adding any dependency. Typical packages: @nestjs/websockets, @nestjs/platform-socket.io, socket.io (backend); socket_io_client (Flutter).
- Read existing entities/enums (e.g. order status, reservation status) and reuse their values. Do not invent new statuses.

### Data flow
Database write (TypeORM FIRST in NestJS Service)
    ↓
Realtime emitter service (thin wrapper)
    ↓
Gateway (transport only: auth, join/leave room, emit)
    ↓
Socket.io Flutter SocketService (lib/services, registered in lib/common/locator.dart)
    ↓
Provider (lib/providers) subscribes and updates state
    ↓
Existing Screen rebuilds from provider state (UI unchanged)

- Emit events ONLY AFTER the database write has succeeded.
- If emit fails, log with the project logger; do not swallow silently and do not roll back the business change.
- Gateway contains NO business logic and NO database queries.
- Other modules call the realtime emitter service; they do not touch the socket server directly.
- Screens must not call the socket directly. Only SocketService and Providers do.

### Backend structure (src/modules/realtime/ unless one already exists)
- realtime.gateway.ts: connection auth, room join/leave only.
- realtime.service.ts: emitToUser / emitToRoom wrapper.
- events/realtime-events.ts: single file of event and room name constants.
- dto/: DTOs for client-to-server messages, validated with class-validator.
- realtime.module.ts: exports the emitter service.

### Rooms and event naming
Rooms (decided by the server, never trusted from client input):
- user:{userId}: joined automatically after auth; personal notifications and payment results.
- order:{orderId}: customer who owns the order and the receiving restaurant.
- restaurant:{restaurantId}: authenticated staff of that restaurant; new orders, new reservations.
- reservation:{reservationId}: customer and restaurant.

Event names use domain:action in snake_case and are defined once as constants. Examples: order:created, order:status_changed, reservation:status_changed, payment:confirmed, payment:failed, notification:new, and client-to-server room:join, room:leave.

Payload shape must be consistent across events: { id, status, updatedAt, data }. Send IDs and changed fields only. Do not send full entities containing sensitive data. The client refetches via the existing REST API when it needs more.

### Security
- Authenticate every connection in the gateway by verifying the JWT from handshake.auth.token. Disconnect on failure. Do not read tokens from query strings.
- Take userId and role from the verified token and store them on client.data. Never take them from client input.
- On room:join, verify ownership/membership through existing services before joining. Reject with a short safe error code otherwise.
- Validate every inbound payload with a DTO. Rate-limit chatty events.
- CORS origins, secrets and URLs come from environment variables. Never hardcode them and never overwrite existing .env files.
- Never send stack traces or database errors through socket acks or error events.
- Never log tokens, authorization headers or payment credentials.
- Payment webhooks (PayOS / MoMo / VietQR): verify the signature first, update payment and order in the database, then emit.

### Flutter rules
- Exactly ONE socket connection per app session, shared through the locator. Never one connection per screen.
- Connect after login, disconnect on logout. Base URL and token come from existing config and auth storage.
- Providers subscribe in a start/listen method and MUST remove listeners in dispose to avoid leaks and duplicate handlers.
- On socket reconnect, the provider refetches current state ONCE from the existing REST API, because events may have been missed while offline.
- Keep loading, empty and error states. Never fill missing data with fake or sample data to make a screen look live.
- Do not modify layout, styling, navigation or animations as part of a realtime task.

### Performance
- Join rooms only for what is active (for example active orders) and leave when finished.
- Do not poll where a socket event exists. Use REST only for initial load and reconnect resync.
- If the backend runs multiple instances, a Socket.io Redis adapter is needed. Ask the user before adding it, since it adds infrastructure.

### Testing (required before saying done)
- Valid token connects; missing/invalid token is rejected.
- User A cannot join or receive events of user B's order.
- Trigger the real business action (not a fake emit) and confirm the correct room receives the event exactly once.
- Client goes offline then reconnects: state resyncs from REST.
- Empty, loading and error states still render in the existing UI.
- Existing REST endpoints and response formats are unchanged.
- Report honestly what was verified and what could not be run.

### Prohibitions (Do NOT)
- Put business logic or TypeORM queries inside the gateway.
- Emit before the database write is committed.
- Broadcast with server.emit for user-specific data.
- Hardcode fake events or sample lists to simulate realtime.
- Create a new provider/service when an existing one can subscribe.
- Change UI as part of a realtime task.

## 16. Authentication, Role Permission & Ownership — CRITICAL

Any feature that belongs to one person (their orders, reservations,
payments, notifications, profile) or to one restaurant must be
reachable ONLY by its owner. This is enforced on the SERVER.

Apply three layers, in this order:
1. Authentication: a global JWT guard verifies the token and sets the
   current user.
2. Role permission: `@Roles(...)` + RolesGuard decides whether a role
   may call an endpoint. Use Guards (not plain middleware) because
   guards can read route metadata.
3. Ownership: the service checks that the specific record belongs to
   the current user (or to the user's restaurant). Passing the role
   check is NOT enough.

Rules:
- Take userId, role and restaurantId ONLY from the verified token.
  NEVER from the request body, query or URL for "my" data.
  Prefer `/me/...` routes.
- Filter queries by owner inside the query itself
  (e.g. where id AND userId), not after fetching everything.
- Return 404 (not 403) when a record exists but belongs to someone
  else, so ids cannot be probed.
- Deny by default. Anything not explicitly allowed is forbidden.
- Restaurant A must never read or modify restaurant B's orders,
  reservations, menu or data.
- Admin access must be explicit in code. Money-related or destructive
  admin actions (refund, cancel paid order, lock account) must be
  written to an audit log.
- DTOs must whitelist fields. Clients must not be able to send or
  change `role`, `userId`, `restaurantId`, `status` or `isPaid`.
- Status changes must validate the allowed transition and who is
  making it. Only the server may mark an order as paid.
- Keep one shared `canAccess` check per resource and reuse it for REST
  and Socket.io. Do not copy the check into every controller.
- Hiding buttons or pages in the UI is NOT access control. Admin web
  route protection is UX only; every admin API needs a server-side
  role guard.
- Socket.io follows the same rules: verify the JWT in the handshake,
  and check ownership before every room join.
- When adding an endpoint, state which roles may call it and how
  ownership is checked.
- Inspect and reuse the existing guards, roles and token payload.
  Do NOT replace working authentication or change the token format.
- Do not weaken authentication or authorization to make a screen or
  test work.

Required tests:
- No, invalid or expired token: rejected (401).
- User A requesting user B's order, reservation or payment: not
  returned (404).
- Customer calling a restaurant-only or admin-only endpoint: 403.
- Restaurant A staff accessing restaurant B's data: not returned or
  changed.
- Extra fields in the body (role, userId, restaurantId): ignored or
  rejected.
- Socket: user A cannot join user B's room or receive its events.
- Existing endpoints and login still work unchanged.

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

Database (PostgreSQL)
    ↓
Entity / Repository / TypeORM
    ↓
NestJS Service
    ↓
NestJS Controller / API Endpoint
    ↓
Mobile Service Layer (`lib/services`)
    ↓
Mobile Provider / State (`lib/providers`)
    ↓
Mobile Model (`lib/models`)
    ↓
Mobile View / Screen (`lib/screens`, `lib/view`)

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
SCOPING & SCOPE CONTROL
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
