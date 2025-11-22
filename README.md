# Angular 14 Node.js Project: CRUD example

In this tutorial, I will show you how to build a full-stack Angular 14 + Node.js example with a CRUD Application. The back-end server uses Node.js + Express for REST APIs, front-end side is an Angular App with HTTPClient.

We will build a full-stack Tutorial Application in that:
- Tutorial has id, title, description, published status.
- User can create, retrieve, update, delete Tutorials.
- There is a search box for finding Tutorials by title.

![angular-14-node-js-project-example](angular-14-node-js-project-example.png)

Tutorial link: [Angular 14 + Node.js Express + MySQL example](https://www.bezkoder.com/angular-14-node-js-express-mysql/)

Or:
> [Angular 14 + Node.js + Express + PostgreSQL example](https://www.bezkoder.com/angular-14-node-js-express-postgresql/)

> [Angular 14 + Node.js + Express + MongoDB example](https://www.bezkoder.com/mean-stack-crud-example-angular-14/)

For more detail, please visit:
> [Angular 14 CRUD Application example with Web API](https://www.bezkoder.com/angular-14-crud-example/)

> [Build Node.js Rest APIs with Express, Sequelize & MySQL](https://www.bezkoder.com/node-js-express-sequelize-mysql/)

> [How to integrate Angular with Node.js Restful Services](https://www.bezkoder.com/integrate-angular-12-node-js/)

More Practice:
> [Deploying/Hosting Node.js app on Heroku with MySQL database](https://www.bezkoder.com/deploy-node-js-app-heroku-cleardb-mysql/)

Pagination:
> [Server side Pagination with Node.js and Angular](https://www.bezkoder.com/server-side-pagination-node-js-angular/)

- File Upload:
> [Angular File upload example with progress bar & Bootstrap](https://www.bezkoder.com/angular-14-file-upload/)

> [Node.js Express File Upload Rest API example](https://www.bezkoder.com/node-js-express-file-upload/)

Security:
> [Angular + Node.js Express: JWT Authentication and Authorization example](https://www.bezkoder.com/node-js-angular-13-jwt-auth/)

Associations:
> [Sequelize Associations: One-to-Many Relationship example](https://www.bezkoder.com/sequelize-associate-one-to-many/)

> [Sequelize Associations: Many-to-Many Relationship example](https://www.bezkoder.com/sequelize-associate-many-to-many/)

Serverless with Firebase:
> [Angular Firebase CRUD with Realtime DataBase | AngularFireDatabase](https://www.bezkoder.com/angular-13-firebase-crud/)

> [Angular Firestore CRUD example with AngularFireStore](https://www.bezkoder.com/angular-13-firestore-crud-angularfirestore/)

> [Angular Firebase Storage: File Upload/Display/Delete example](https://www.bezkoder.com/angular-13-firebase-storage/)

## Project setup

### Prerequisites
- **Node.js 18+** is required for this project (migrated from Node.js 14)
- Install Node.js 18 or higher from [nodejs.org](https://nodejs.org/) or use nvm: `nvm install 18 && nvm use 18`
- MySQL 8.0 or higher

### Technology Stack
This project uses the following major dependencies (updated for Node.js 18 compatibility):

**Backend (node-js-server):**
- Express 4.18.2 (OpenSSL 3.0 support, security patches)
- mysql2 3.6.0 (OpenSSL 3.0 SSL/TLS compatibility - critical for Node.js 18)
- Sequelize 6.33.0 (mysql2 3.x compatibility)
- CORS 2.8.5

**Frontend (angular-14-client):**
- Angular 14.2.0 (optimized for Node.js 18)
- RxJS 7.8.1
- TypeScript 4.9.5 (improved Node.js 18 type definitions)
- Karma 6.4.2 (Node.js 18 testing support)

### Node.js Server
```
cd node-js-server
npm install
node server.js
```

### Angular Client
```
cd angular-14-client
npm install
ng serve --port 8081
```
Navigate to `http://localhost:8081/`.

### Docker Setup
This project includes Docker configuration for containerized deployment:

**Build and run all services:**
```bash
docker-compose up --build
```

**Services:**
- Frontend: http://localhost:4200
- Backend API: http://localhost:8080
- MySQL: localhost:3306

**Stop all services:**
```bash
docker-compose down
```

**Remove volumes (reset database):**
```bash
docker-compose down -v
```

### Migration Notes for Developers

**Migrating from Node.js 14 to Node.js 18:**

This project has been updated to support Node.js 18, which includes several breaking changes:

1. **OpenSSL 3.0 Compatibility**: Node.js 18 uses OpenSSL 3.0 (vs 1.1.1 in Node.js 14). This required upgrading:
   - mysql2: 2.0.2 → 3.6.0 (critical for database SSL/TLS connections)
   - express: 4.17.1 → 4.18.2 (security patches and compatibility)
   - sequelize: 6.21.0 → 6.33.0 (mysql2 3.x support)

2. **Clean Installation Required**: When switching to Node.js 18, perform a clean install:
   ```bash
   # Backend
   cd node-js-server
   rm -rf node_modules package-lock.json
   npm install

   # Frontend
   cd angular-14-client
   rm -rf node_modules package-lock.json
   npm install
   ```

3. **Development Environment**: Use `.nvmrc` files for consistent Node.js version:
   ```bash
   nvm use  # Automatically switches to Node.js 18
   ```

4. **Testing**: After migration, verify all functionality:
   - Backend: Test all CRUD API endpoints
   - Frontend: Run unit tests with `ng test`
   - Integration: Test full application workflow

5. **CI/CD**: GitHub Actions workflow configured for automated testing with Node.js 18

For detailed migration history and breaking changes, see [CHANGELOG.md](CHANGELOG.md).