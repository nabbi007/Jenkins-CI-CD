# System Architecture

## High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      GitHub Repository                       │
│                   (Source Code + Jenkinsfile)               │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                     Jenkins Server                           │
│  [Checkout] → [Build] → [Test] → [Docker] → [Push] → [Deploy]
│                   (Docker Agent)                             │
└─────────────────────────────────────────────────────────────┘
                         ↙            ↘
        ┌────────────────────┐    ┌──────────────────┐
        │  AWS ECR Registry  │    │ EC2 Instance     │
        │  (Image Storage)   │    │ (Running App)    │
        └────────────────────┘    └──────────────────┘
                                           ↓
                                 ┌──────────────────┐
                                 │  Docker Container│
                                 │  (Port 80 → 3000)
                                 │  (Health Check)  │
                                 └──────────────────┘
                                           ↓
                                 ┌──────────────────┐
                                 │  Express App     │
                                 │  (API + UI)      │
                                 └──────────────────┘
                                           ↓
                                 ┌──────────────────┐
                                 │  Public Internet │
                                 │  (54.74.21.91:80)│
                                 └──────────────────┘
```

---

## Application Layer Architecture

### Backend (Express.js)

```
Express App
├── Middleware
│   ├── Request Logging (JSON)
│   ├── Performance Timing
│   ├── Error Handling
│   └── CORS
├── Public Routes
│   ├── GET / (UI)
│   ├── GET /health
│   └── GET /metrics
└── API Routes (/api/)
    ├── GET /options
    ├── GET /deployments
    ├── POST /deployments
    ├── PATCH /deployments/:id
    └── GET /dashboard
```

### Frontend (Web UI)

```
HTML/CSS/JavaScript
├── Header (Navigation)
├── Dashboard (Statistics)
├── Controls (Forms)
│   ├── Create Deployment
│   ├── Filter
│   └── Update Status
└── Table (Deployment List)
```

---

## Data Flow

### Create Deployment

```
User Form Input
   ↓
JavaScript (public/app.js)
   ↓
POST /api/deployments
   ↓
Express Route Handler
   ↓
Validation
   ↓
In-Memory Store
   ↓
JSON Response (201 Created)
   ↓
UI Update
```

### Health Check

```
Pipeline Deploy Stage
   ↓
GET /health (10 attempts)
   ↓
Express Handler
   ↓
Return {status: 'ok', uptime: ...}
   ↓
Pipeline Verification
   ↓
Success/Failure Decision
```

---

## Data Storage

**Current:** In-memory array  
**Persistence:** Reset on restart  
**Deployments:** Array of deployment objects

```javascript
{
  id: 'dep-1001',
  serviceName: 'payments-api',
  version: '1.2.0',
  environment: 'staging',
  owner: 'platform-team',
  status: 'succeeded',
  startedAt: '2026-02-17T11:28:52Z',
  updatedAt: '2026-02-17T11:30:00Z'
}
```

---

## Security Architecture

### Credential Management

- AWS credentials stored in Jenkins only
- Credentials masked in pipeline logs
- Session tokens support temporary access
- No credentials in repository

### Network Security

- EC2 Security Group: Port 80 only
- No direct database access
- No SSH exposed public
- Health checks on standard port

---

## Scalability Considerations

### Current Architecture

- Single EC2 instance
- Single Docker container
- In-memory storage
- No load balancer

### Future Enhancements

- **Horizontal:** Auto Scaling Group + Load Balancer
- **Vertical:** Larger EC2 instance type
- **Storage:** RDS database for persistence
- **Caching:** Redis for session/data cache
- **CDN:** CloudFront for static assets

