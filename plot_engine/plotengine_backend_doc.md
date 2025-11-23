# PlotEngine – Backend (Node.js) Technical Overview

## 1. Overview

PlotEngine backend provides REST APIs and WebSocket services for AI-driven story analysis. It handles real-time character extraction, plot consistency checks, foreshadowing suggestions, and knowledge base management.

## 2. Core Features

- **Real-Time Analysis**: Processes text diffs from frontend and returns AI comments.
- **Knowledge Base**: Maintains characters, locations, objects, events.
- **Project Management APIs**: CRUD for projects and chapters.
- **WebSocket Streaming**: Push AI comments to frontend in real-time.
- **Embedding Store**: Vector DB for context search and consistency analysis.

## 3. Technology Stack

- **Backend Framework**: Node.js with Fastify (or Express)
- **Database**: PostgreSQL for user/project data
- **Vector Store**: Qdrant for embeddings of characters, events, chapters
- **AI Integration**: OpenAI GPT-5.1 / Claude 3.5 via SDKs
- **WebSocket**: `ws` or Fastify WebSocket plugin
- **Authentication**: JWT / Supabase Auth
- **Deployment**: Dockerized, can be deployed on cloud VPS or container platforms

## 4. Architecture Diagram

```
Frontend Flutter App
        |
        v
Node.js Backend (Fastify)
 ├── REST APIs (project, chapter, CRUD)
 ├── WebSocket Server (real-time comments)
 ├── AI Orchestration Module
 │     ├── Character Extractor
 │     ├── Plot Consistency Checker
 │     ├── Foreshadowing Engine
 │     └── Style Advisor
 ├── Database Layer
 │     ├── PostgreSQL (metadata)
 │     └── Qdrant (embeddings)
 └── File Storage / Blob Store (optional)
```

## 5. API Endpoints (MVP)

```
POST /projects       -> Create new project
GET /projects/:id    -> Fetch project details
POST /projects/:id/chapters  -> Add chapter
GET /projects/:id/chapters/:cid -> Get chapter content
WebSocket /analysis/stream -> Real-time AI comments
```

## 6. Folder Structure (Suggested)

```
src/
 ├── server.js
 ├── routes/
 │    ├── projectRoutes.js
 │    ├── chapterRoutes.js
 │    └── analysisRoutes.js
 ├── services/
 │    ├── aiService.js
 │    ├── dbService.js
 │    └── websocketService.js
 ├── models/
 └── utils/
package.json
Dockerfile
```

## 7. Development Notes

- Use async/await extensively for handling AI requests and database operations.
- WebSocket connection should handle reconnects and partial updates.
- Implement vector-based similarity search using Qdrant for context-aware suggestions.
- Ensure modularity: AI orchestration modules should be isolated for testing and future expansion.
- Dockerize backend for easy deployment and scaling.

---

# End of Document
