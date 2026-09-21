# Project Rules & Guidelines

## 1. Database Safety & Integrity Rule (CRITICAL)
- **NEVER** run commands, SQL scripts, migrations, or ORM configurations that drop, delete, truncate, reset, or recreate the database or existing tables.
- **NEVER** use `synchronize: true` in TypeORM or `dropSchema: true` or `prisma db push --force-reset` or similar destructive operations.
- All database modifications must strictly preserve existing data and structure created by the user.

## 2. Code File Length Limit
- **NEVER** write any source code file exceeding **1000 lines of code**.
- Maintain modular structure, splitting controllers, services, repositories, and models into concise, focused files.

## 3. Architecture & Pattern
- Mobile App must adhere to **MVC (Model-View-Controller)** pattern.
- Backend must follow clean modular architecture with clear separation of concerns (Controllers, Services, Modules/DTOs).
