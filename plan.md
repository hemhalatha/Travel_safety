# Travel Safety App — Full Implementation Plan

## 1. Project Overview

### Project Title
**Passive Travel Safety and Destination Alert System**

### Core Idea
A mobile application where a user sets a destination once, starts a trip, and puts the phone away. The application monitors the journey in the background, detects sustained suspicious travel behavior, alerts the user near the destination, and can escalate unresolved high-risk events to trusted contacts.

### Core Principle
**The app watches the journey so the user does not have to continuously watch the map.**

This is not a replacement for navigation. Navigation helps find a route; this project adds a passive monitoring layer that interprets journey behavior.

---

# 2. Problem Statement

Travelers may be unable or unwilling to constantly check maps because they are:

- Traveling alone.
- Tired or distracted.
- Sleeping on a bus or train.
- Unfamiliar with the route.
- Traveling late at night.

Typical concerns are:

- Am I still going in the right direction?
- Is this route change normal or suspicious?
- Why is my arrival time increasing?
- Am I moving away from my destination?
- Will I miss my stop if I sleep?
- Will someone know if something goes wrong?

Existing solution categories solve only part of the problem:

- Navigation apps require active attention.
- SOS apps generally require the user to first identify danger.
- Live location sharing shows location but does not necessarily interpret trip behavior.
- Destination alarms can prevent missed stops but do not monitor route risk.

The project combines **passive journey monitoring** and **destination arrival alerts**.

---

# 3. Project Objectives

The system must:

1. Allow users to enter a destination and start a monitored trip.
2. Retrieve an expected route and valid alternative routes.
3. Track live location during an active trip.
4. Clean and validate noisy GPS data.
5. Measure whether the traveler is making reasonable progress toward the destination.
6. Detect sustained suspicious behavior using multiple signals.
7. Avoid alerts caused by temporary GPS errors or valid detours.
8. Use staged alerts instead of treating every deviation as an emergency.
9. Allow the user to acknowledge that they are safe.
10. Escalate unresolved high-risk alerts to trusted contacts.
11. Alert the user when approaching the destination.
12. Handle offline and degraded states explicitly.
13. Maintain trip and alert history with privacy controls.

---

# 4. Target Users and Travel Modes

Primary users:

- Women traveling alone.
- Students.
- Office and late-night commuters.
- Elderly travelers.
- Bus and train passengers.
- General solo travelers.

Supported travel modes:

- Cab / taxi.
- Auto / three-wheeler.
- Private vehicle.
- Bus.
- Train.
- General travel.

Travel mode is part of the monitoring context because expected speed, stops, route length, and acceptable deviations differ by mode.

---

# 5. Product Flow

1. User logs in.
2. User adds trusted contacts.
3. User searches for a destination.
4. User selects travel mode.
5. App retrieves a primary route and alternatives.
6. User starts the trip.
7. Background monitoring starts.
8. Location samples are validated and processed.
9. Route, ETA, direction, progress, stops, and deviation are analyzed.
10. Risk is calculated continuously.
11. Normal trips remain silent.
12. Sustained medium risk triggers a soft warning.
13. Sustained high risk triggers a stronger alert.
14. If configured conditions are met and the user does not respond, trusted contacts are notified.
15. When near the destination, an arrival alarm is triggered.
16. Trip ends after arrival, manual completion, cancellation, or another valid terminal condition.

Suggested trip states:

```text
DRAFT
ROUTE_READY
ACTIVE
OBSERVE
WARNING
HIGH_RISK
ESCALATED
ARRIVED
COMPLETED
CANCELLED
FAILED
```

---

# 6. Why Simple Distance Logic Is Not Enough

Do not implement:

```text
IF distance from planned route > 5 km
THEN alert
```

A fixed distance has different meanings in different contexts:

- 5 km during a 6 km city trip is highly significant.
- 5 km during a 250 km highway trip may be a normal diversion.
- GPS may be inaccurate near flyovers, tall buildings, tunnels, and parallel roads.
- A valid alternate route can be geometrically far from the original route.

The system should answer:

> **Is the traveler still making reasonable and contextually valid progress toward the destination?**

Distance is therefore one signal, not the complete decision.

---

# 7. Safety Intelligence Architecture

```text
Raw GPS
→ Quality Validation
→ GPS Smoothing
→ Map Matching / Road Context
→ Journey Feature Extraction
    ├── ETA Analysis
    ├── Destination Progress
    ├── Direction Mismatch
    ├── Route Deviation
    ├── Valid Detour Check
    ├── Stop Detection
    └── Persistence
→ Deterministic Risk Rules
→ ML Risk / Anomaly Prediction
→ Final Safety Decision
→ Alert / Escalation
```

The final decision should be **hybrid**:

- Deterministic logic provides reliability and explainability.
- ML improves pattern recognition and risk estimation.
- ML alone must not be the sole authority for emergency escalation.

---

# 8. Location Processing

## 8.1 Location Input

Each sample should contain where available:

```text
latitude
longitude
timestamp
horizontal_accuracy
speed
bearing
altitude
provider metadata
```

Example:

```json
{
  "latitude": 13.0827,
  "longitude": 80.2707,
  "timestamp": "2026-08-15T12:00:00Z",
  "accuracyMeters": 12,
  "speedMps": 8.2,
  "bearingDegrees": 125
}
```

## 8.2 Quality Gate

Before a location affects safety logic:

- Reject stale points.
- Reject impossible jumps.
- Validate timestamp order.
- Detect impossible speed.
- Detect duplicates.
- Down-weight poor horizontal accuracy.

All thresholds must be configurable.

## 8.3 GPS Smoothing

Use a **Kalman Filter** as the primary smoothing mechanism.

Purpose:

```text
Raw noisy GPS
→ quality validation
→ Kalman smoothing
→ motion consistency checks
→ cleaned GPS
```

The filter reduces noise but must not fabricate certainty.

## 8.4 Map Matching

Raw GPS should be associated with likely roads or paths.

Use:

- A provider map-matching capability where available.
- An abstraction layer so the map provider can be changed.
- Match confidence as an input to the risk engine.

Conceptually, an HMM-style sequence approach is suitable because nearby GPS observations and movement continuity help resolve road ambiguity.

---

# 9. Journey Analysis Algorithms

## 9.1 ETA Inflation

Definitions:

- `expectedRemainingETA`: expected remaining journey time at the current trip stage.
- `currentRemainingETA`: latest route estimate from current location to destination.

Formula:

```text
etaInflation =
(currentRemainingETA - expectedRemainingETA)
/
expectedRemainingETA
```

Example:

```text
Expected remaining ETA = 20 min
Current remaining ETA = 38 min

ETA inflation = 0.90
```

ETA is a major signal, but traffic, closures, weather, and normal delays can increase it. Never use ETA alone as proof of danger.

## 9.2 Destination Progress

Track whether the traveler is progressing through:

- Reduction in remaining route distance.
- Reduction in remaining ETA.
- Increase in route progress percentage.
- Progress over rolling windows.

Example:

```text
progressRate =
(previousRemainingDistance - currentRemainingDistance)
/
elapsedTime
```

Moving while making little or negative progress increases risk.

## 9.3 Direction Mismatch

Compare:

- Current movement bearing.
- Bearing toward destination.
- Expected local route bearing.

Use angular difference:

```text
difference = min(
abs(currentBearing - expectedBearing),
360 - abs(currentBearing - expectedBearing)
)
```

Do not react to a single turn. Aggregate mismatch over a rolling window.

## 9.4 Route Deviation

Calculate context such as:

- Distance from primary route.
- Distance from nearest valid alternative.
- Relative deviation based on trip size.
- Map-match confidence.
- Fresh route cost from current location.

Useful features:

```text
distanceFromNearestValidRoute
relativeDeviation
routeMatchConfidence
newRoutePenalty
```

## 9.5 Valid Detour Check

When deviation is significant:

1. Compute a fresh route from current location to destination.
2. Compare its ETA and distance with reasonable alternatives.
3. Check whether current movement is consistent with that route.
4. Reduce risk if the new route is plausible.

This is essential for reducing false positives.

## 9.6 Stop Detection

A stop may be detected when:

- Speed remains near zero.
- Position stays within a small radius.
- The condition continues beyond a duration threshold.

Context:

- Travel mode.
- Time of day.
- Distance from destination.
- Stop frequency.
- Traffic context where available.
- Whether the location is a common stop.
- User response.

Features:

```text
stopDuration
stopCount
stopFrequency
unusualStopScore
```

---

# 10. Risk Engine

## 10.1 Feature Set

Generate normalized features:

```text
etaInflationScore
etaChangeRate
progressScore
directionMismatchScore
routeDeviationScore
unusualStopScore
gpsUncertaintyScore
routeMatchConfidence
validDetourConfidence
persistenceScore
travelModeContext
```

## 10.2 Rule Layer

Examples:

```text
IF GPS quality is poor
THEN reduce confidence and avoid immediate escalation.

IF route deviation is high
AND ETA inflation is high
AND direction mismatch persists
THEN increase risk.

IF a fresh route is valid
AND journey impact is reasonable
THEN reduce risk.

IF elevated risk persists
THEN transition to warning.

IF high risk persists
AND the user does not acknowledge
THEN follow escalation policy.
```

## 10.3 Weighted Risk Score

Concept:

```text
riskScore =
w1 * etaInflationScore
+ w2 * negativeProgressScore
+ w3 * directionMismatchScore
+ w4 * routeDeviationScore
+ w5 * unusualStopScore
+ w6 * persistenceScore
- w7 * validDetourConfidence
```

Weights must be tuned using evidence and evaluation, not chosen arbitrarily.

## 10.4 Temporal Persistence and Hysteresis

Never escalate from one bad sample.

Use:

- Rolling windows.
- Consecutive anomaly counts.
- Smoothed risk values.
- Hysteresis for state transitions.

Suggested states:

```text
SAFE
→ OBSERVE
→ SOFT_WARNING
→ HIGH_RISK
→ ESCALATED
```

Recovery should also require stable normal behavior to prevent rapid alert oscillation.

---

# 11. Machine Learning Plan

## 11.1 Supervised Risk Classifier

Recommended first production model:

**LightGBM or XGBoost**

Potential features:

- ETA inflation.
- ETA change rate.
- Remaining distance trend.
- Route deviation ratio.
- Direction mismatch statistics.
- Stop duration and frequency.
- Speed statistics.
- GPS accuracy.
- Map-match confidence.
- Travel mode.
- Trip-length category.
- Time context.
- Persistence features.

Output:

```text
P(normal)
P(valid_detour)
P(suspicious)
P(high_risk)
```

## 11.2 Unsupervised Anomaly Detection

Use **Isolation Forest** as a secondary signal for behavior that is unusual relative to normal trips.

Output:

```text
anomalyScore
```

It must not independently trigger emergency escalation.

## 11.3 Clustering

Use **HDBSCAN or DBSCAN** where useful for:

- Common stop clusters.
- Frequent route behavior.
- Dense normal movement regions.
- Unusual geographic behavior.

## 11.4 Probability Calibration

Evaluate whether model probabilities are trustworthy.

Possible calibration:

- Isotonic Regression.
- Platt Scaling.

Do not assume a model output of `0.80` means an actual 80% probability without calibration testing.

## 11.5 Model Service

Use a Python FastAPI service.

Example:

```text
POST /v1/risk/predict
```

Input:

```json
{
  "tripId": "trip_123",
  "features": {
    "etaInflation": 0.72,
    "routeDeviationRatio": 0.31,
    "directionMismatchMean": 0.67
  }
}
```

Output:

```json
{
  "riskProbability": 0.81,
  "anomalyScore": 0.74,
  "modelVersion": "risk-v1"
}
```

The main backend combines this result with deterministic safety logic.

---

# 12. Alert and Escalation System

## Level 0 — Normal
No visible alert.

## Level 1 — Observe
Internal elevated risk; continue collecting evidence.

## Level 2 — Soft Warning

Example:

> Your journey appears unusual. Are you safe?

Actions:

- I'm Safe.
- Continue monitoring.
- End trip.
- Emergency action.

## Level 3 — High Risk

Prominent visible and audible alert.

## Level 4 — Escalation

If high-risk conditions persist and the configured response policy is unmet:

- Notify trusted contacts.
- Include trip status and last known relevant location.
- Continue updates only according to user consent and product policy.
- Log delivery attempts.

Notifications must not falsely claim that danger has been verified. For example:

> A travel safety alert was triggered and the user did not respond.

## Acknowledgement

When `I'm Safe` is pressed:

- Record acknowledgement time.
- Record current risk state.
- Update escalation timer/policy.
- Continue monitoring.
- Do not permanently disable future detection unless explicitly configured.

---

# 13. Destination Arrival Alert

This module is independent of route-risk detection.

Use:

- Distance to destination.
- Arrival/geofence radius.
- GPS accuracy.
- Movement trend.
- Travel mode.

Example:

```text
IF distanceToDestination <= arrivalRadius
AND locationAccuracy is acceptable
THEN trigger arrival alert
```

States:

```text
NOT_TRIGGERED
TRIGGERED
ARRIVAL_CONFIRMED
```

Outputs:

- Sound.
- Vibration.
- Local notification.
- Audio routing where supported by platform permissions.

Prevent repeated alerts.

---

# 14. Frontend Plan

## Recommended Stack

- Flutter.
- Riverpod or BLoC; choose one consistently.
- Secure local storage.
- Drift/SQLite for offline queues and active trip recovery.
- Maps SDK selected through provider abstraction.
- Firebase Cloud Messaging for push notifications.

## Architecture

```text
Presentation
├── Screens
├── Widgets
├── State Notifiers / Blocs

Application
├── Use Cases
├── Services

Domain
├── Entities
├── Repository Interfaces
├── Business Rules

Data
├── API Client
├── Local Database
├── Location Provider
├── Maps Provider
├── Notification Provider
└── Repository Implementations
```

## Screens

### 1. Splash / Session Restore
- Restore session.
- Recover active trip.
- Check required permissions.

### 2. Onboarding
Explain:
- What the system monitors.
- Background location requirements.
- Privacy.
- Trusted contacts.
- Product limitations.

### 3. Authentication
- Login.
- Registration.
- Password reset.

### 4. Home
- Set destination.
- Start trip.
- Recent trips.
- Trusted contacts.

### 5. Destination Search
- Search.
- Select destination.
- Map preview.

### 6. Trip Setup
- Travel mode.
- Route options.
- ETA/distance.
- Trusted contacts.
- Arrival radius.
- Start monitoring.

### 7. Active Trip
Show:
- Destination.
- Current ETA.
- Progress.
- Monitoring state.
- Safety state.
- End trip.
- Emergency shortcut.

The user must not need to keep this screen open.

### 8. Soft Warning
- Clear explanation of unusual journey behavior.
- I'm Safe.
- Continue monitoring.
- Emergency action.

### 9. High-Risk Alert
- Prominent acknowledgement.
- Escalation countdown where applicable.
- Current monitoring state.

### 10. Arrival Alert
- Near destination.
- Stop alarm.
- Confirm arrival.

### 11. Trusted Contacts
Full CRUD and preferences.

### 12. Trip History
- Start/end.
- Destination.
- Duration.
- Alerts.
- Final status.

### 13. Settings and Privacy
- Permissions.
- Notification preferences.
- Data retention.
- Account deletion.

---

# 15. Mobile Background Monitoring

Create a dedicated service abstraction:

```text
TripMonitoringService
├── startMonitoring()
├── receiveLocation()
├── persistActiveTrip()
├── queueOfflineEvents()
├── triggerLocalAlert()
└── stopMonitoring()
```

Responsibilities:

- Maintain monitoring according to OS capabilities.
- Recover active-trip state after restart where feasible.
- Adapt location frequency to trip state.
- Queue unsent events.
- Continue local arrival checks where possible.
- Explicitly indicate degraded monitoring.

Conceptual sampling:

```text
Stable travel       → lower frequency
Near destination    → higher frequency
Elevated risk       → higher frequency
Stationary          → reduce after confirmation
Poor GPS            → quality-aware behavior
```

Exact implementation must follow Android and iOS background execution and permission rules.

Monitoring states:

```text
FULL_MONITORING
LIMITED_OFFLINE_MONITORING
GPS_DEGRADED
NETWORK_DEGRADED
MONITORING_INTERRUPTED
```

---

# 16. Backend Architecture

Recommended production architecture:

```text
Flutter App
   │
   ▼
Load Balancer / API Gateway
   │
   ▼
Main Backend API
├── Auth
├── Users
├── Contacts
├── Trips
├── Routes
├── Location Ingestion
├── Risk Orchestrator
├── Alerts
├── Notifications
└── Audit
   │
   ├── PostgreSQL + PostGIS
   ├── Redis
   ├── Message Queue
   └── ML Risk Service
```

## Recommended Technology

Option A:

```text
NestJS + TypeScript → Main backend
FastAPI + Python → ML service
PostgreSQL + PostGIS → Primary data store
Redis → Cache / short-lived state
RabbitMQ or managed queue → Event processing
```

Option B:

```text
FastAPI → Main backend + ML integration
```

The project should select one primary backend architecture and avoid unnecessary duplication.

---

# 17. Backend Modules and APIs

## Auth

```text
POST /auth/register
POST /auth/login
POST /auth/refresh
POST /auth/logout
POST /auth/password/reset
DELETE /auth/account
```

## User

```text
GET /users/me
PATCH /users/me
GET /users/me/settings
PATCH /users/me/settings
```

## Trusted Contacts

```text
GET /contacts
POST /contacts
PATCH /contacts/{id}
DELETE /contacts/{id}
POST /contacts/{id}/verify
```

## Trips

```text
POST /trips
GET /trips/{id}
PATCH /trips/{id}
POST /trips/{id}/start
POST /trips/{id}/end
POST /trips/{id}/cancel
GET /trips
```

## Routes

```text
POST /routes/compute
GET /trips/{id}/routes
POST /trips/{id}/reroute
```

## Locations

```text
POST /trips/{id}/locations
POST /trips/{id}/locations/batch
```

Validate:

- Authentication.
- Trip ownership.
- Active trip status.
- Location schema.
- Timestamp ordering.

## Risk

```text
GET /trips/{id}/risk
```

Evaluation should normally be event-driven rather than controlled by the mobile client.

## Alerts

```text
GET /trips/{id}/alerts
POST /alerts/{id}/acknowledge
POST /alerts/{id}/resolve
```

---

# 18. Event-Driven Processing

Location processing should be decoupled from request handling:

```text
Mobile Location
→ API Validation
→ Store / Queue Event
→ Location Processor
→ Feature Extraction
→ ML Inference
→ Safety Decision
→ Alert Event
→ Notification Service
```

For moderate initial production scale:

- RabbitMQ or a managed queue is a practical choice.
- Avoid introducing Kafka unless scale and operational requirements justify it.

Use idempotency keys and event IDs to prevent duplicate processing.

---

# 19. Database Design

Recommended database:

**PostgreSQL + PostGIS**

## users

```text
id
email
phone
display_name
created_at
updated_at
deleted_at
```

## trusted_contacts

```text
id
user_id
name
phone
email
relationship
verified_at
created_at
```

## trips

```text
id
user_id
status
travel_mode
origin
destination
started_at
ended_at
arrival_radius_meters
created_at
```

## routes

```text
id
trip_id
route_type
provider
distance_meters
duration_seconds
geometry
created_at
```

## location_samples

```text
id
trip_id
timestamp
raw_location
clean_location
accuracy_meters
speed_mps
bearing
quality_score
map_match_confidence
```

This can become high-volume. Plan spatial indexes, partitioning, and retention.

## risk_assessments

```text
id
trip_id
timestamp
risk_score
risk_level
eta_inflation
progress_score
direction_score
deviation_score
stop_score
ml_probability
model_version
```

## alerts

```text
id
trip_id
risk_assessment_id
alert_level
status
created_at
acknowledged_at
resolved_at
```

## notifications

```text
id
alert_id
recipient_type
recipient_id
channel
status
sent_at
delivered_at
```

## audit_logs

Store security-sensitive and important actions.

---

# 20. ML Data and Training Pipeline

## Data Labels

Do not assume every alert represents real danger.

Possible labels:

```text
NORMAL
VALID_DETOUR
GPS_ERROR
TRAFFIC_DELAY
SUSPICIOUS
CONFIRMED_HIGH_RISK
UNKNOWN
```

Potential label sources:

- User acknowledgement.
- Post-trip feedback.
- Controlled tests.
- Support review.
- Carefully designed data-review workflows.

## Training Pipeline

```text
Raw Trip Data
→ Validation
→ Privacy Processing
→ Feature Engineering
→ Train/Validation/Test Split
→ Model Training
→ Calibration
→ Error Analysis
→ Offline Evaluation
→ Shadow Deployment
→ Production Rollout
```

Avoid random row-level splitting that leaks portions of the same trip into training and test data.

## Model Monitoring

Track:

- Precision.
- Recall.
- False-positive rate.
- Miss rate.
- Calibration.
- Feature drift.
- Model drift.
- Latency.
- Performance by travel mode and trip-length category.

---

# 21. Offline and Degraded Operation

The app must not assume constant network access.

When offline:

- Continue location capture when supported.
- Continue local arrival checks.
- Persist data locally.
- Queue samples for upload.
- Apply local rules where enough information exists.
- Sync in order when network returns.

Server-side rerouting and ML inference may be unavailable.

The app must visibly and internally model degraded operation rather than pretending that full monitoring is active.

---

# 22. Security and Privacy

Location is sensitive data.

## Security

- TLS for all communication.
- Secure token storage.
- Refresh-token/session controls.
- Authorization checks on every resource.
- Input validation.
- Rate limiting.
- Audit logs.
- Secrets manager.
- Separate production and development environments.
- Dependency and security scanning.

## Privacy

- Explicit location consent.
- Explain background monitoring.
- User controls trip start/end.
- User controls trusted contacts.
- Clear escalation policy.
- Data minimization.
- Defined retention periods.
- Account deletion.
- Avoid unnecessary raw location logging.

---

# 23. Observability

## Logs

Structured logs should include:

```text
requestId
eventId
tripId where permitted
service
eventType
errorCode
```

Do not log sensitive raw data unnecessarily.

## Metrics

Track:

- Active trips.
- Location ingestion rate.
- Risk evaluations/sec.
- Alert rate.
- Acknowledgement rate.
- Escalation rate.
- False-positive feedback.
- ML latency.
- API latency.
- Notification failures.
- Monitoring interruptions.

## Tracing

Trace:

```text
Location
→ Queue
→ Processor
→ ML
→ Decision
→ Alert
→ Notification
```

---

# 24. Testing Strategy

## Unit Tests

Test:

- ETA calculations.
- Progress calculations.
- Direction calculations.
- GPS quality handling.
- Risk score normalization.
- State transitions.
- Acknowledgement.
- Escalation.

## Integration Tests

Test:

- Maps provider.
- Database.
- Queue.
- ML service.
- Notification provider.

## Trip Simulator

Build a simulator for:

- Normal trip.
- Valid detour.
- Wrong-direction travel.
- Long delay.
- GPS jump.
- Parallel road.
- Flyover/service-road behavior.
- Unusual stop.
- Network loss.
- App restart.

This is a critical development tool.

## Field Tests

Test across:

- Dense city roads.
- Highways.
- Flyovers.
- Different devices.
- Public transport.
- Poor network zones.
- Different speeds and trip lengths.

## Load Tests

Test:

- Concurrent trips.
- Location batches.
- Risk throughput.
- Notification bursts.

---

# 25. Repository Structure

```text
travel-safety-app/
├── mobile/
│   ├── lib/
│   │   ├── core/
│   │   ├── features/
│   │   │   ├── auth/
│   │   │   ├── destination/
│   │   │   ├── trip/
│   │   │   ├── monitoring/
│   │   │   ├── alerts/
│   │   │   ├── contacts/
│   │   │   ├── history/
│   │   │   └── settings/
│   │   ├── services/
│   │   │   ├── location/
│   │   │   ├── notifications/
│   │   │   ├── background_monitoring/
│   │   │   └── maps/
│   │   └── main.dart
│   └── test/
├── backend/
│   ├── src/
│   │   ├── modules/
│   │   ├── common/
│   │   ├── config/
│   │   └── main.*
│   ├── migrations/
│   └── tests/
├── ml-service/
│   ├── app/
│   ├── training/
│   ├── evaluation/
│   └── tests/
├── infra/
│   ├── docker/
│   ├── terraform/
│   ├── kubernetes/
│   └── monitoring/
└── plan.md
```

---

# 26. Development Phases

## Phase 1 — Foundation

Build:

- Authentication.
- User profile.
- Trusted contacts.
- Destination search.
- Route retrieval.
- Trip lifecycle.
- Database schema.

**Deliverable:** user can create and start a trip.

## Phase 2 — Mobile Monitoring

Build:

- Background/foreground monitoring.
- Permission flows.
- GPS collection.
- Local persistence.
- Offline queue.
- Arrival alert.

**Deliverable:** monitored trips and arrival alerts work.

## Phase 3 — Deterministic Safety Engine

Build:

- GPS quality gate.
- Kalman smoothing.
- Map matching.
- ETA analysis.
- Progress tracking.
- Direction detection.
- Adaptive deviation.
- Stop detection.
- Risk state machine.

**Deliverable:** normal and abnormal simulated trips are distinguishable.

## Phase 4 — Alerts and Escalation

Build:

- Soft warning.
- High-risk alert.
- Acknowledgement.
- Escalation timer.
- Trusted-contact notifications.
- Notification logs.

**Deliverable:** complete safety flow works end-to-end.

## Phase 5 — ML Intelligence

Build:

- Data pipeline.
- Feature engineering.
- LightGBM/XGBoost baseline.
- Isolation Forest.
- Evaluation.
- Calibration.
- Model serving.
- Shadow testing.

**Deliverable:** ML improves risk estimation without being the sole escalation authority.

## Phase 6 — Production Hardening

Build:

- Event queue.
- Rate limiting.
- Observability.
- CI/CD.
- Backups.
- Security testing.
- Load testing.
- Privacy controls.

## Phase 7 — Field Validation

Measure:

- False positives.
- Missed anomalies.
- Battery usage.
- GPS quality.
- Alert latency.
- Background reliability.
- User understanding.

Tune only from measured evidence.

---

# 27. CI/CD

For every pull request:

1. Format/lint.
2. Static analysis.
3. Unit tests.
4. Build.
5. Dependency/security scan.
6. Integration tests where possible.

For the main branch:

1. Create versioned artifact.
2. Validate migrations.
3. Deploy to staging.
4. Run smoke tests.
5. Approval gate where required.
6. Deploy to production.
7. Monitor health and rollback signals.

Environments:

```text
local
development
staging
production
```

Never use production secrets or raw production location data in lower environments.

---

# 28. Non-Functional Requirements

## Reliability

- Active trips recover gracefully after transient failures.
- Alerts and notifications are idempotent.
- Notification failures are retried according to policy.

## Latency

Define near-real-time targets after field testing and measure actual performance.

## Battery

Use adaptive location frequency; do not run maximum-frequency GPS unnecessarily.

## Scalability

Location ingestion and risk processing must scale horizontally.

## Accuracy

Measure:

- False-positive rate.
- Miss rate.
- Precision.
- Recall.
- Calibration.
- Performance by travel mode.

## Explainability

Store alert contributors such as:

- ETA increased.
- Progress decreased.
- Direction mismatch persisted.
- No plausible detour found.

This is required for debugging and support.

---

# 29. Product Limitations

The application must clearly state:

- It is an assistive safety system, not a guarantee of physical safety.
- Route anomalies are not proof of criminal activity or danger.
- GPS, network, maps, device background services, and notifications can fail or degrade.
- Escalation depends on permissions, connectivity, configuration, and supported platform behavior.
- In immediate danger, the app must not delay the user from contacting appropriate emergency services.

---

# 30. Final Architecture

```text
USER
 │
 ▼
FLUTTER MOBILE APP
 │
 ├── Destination Search
 ├── Route Setup
 ├── Trip Monitoring
 ├── GPS Collection
 ├── Local Arrival Alert
 └── Safety UI
 │
 ▼
BACKEND API
 │
 ├── Authentication
 ├── Trip Management
 ├── Contacts
 └── Location Ingestion
 │
 ▼
EVENT QUEUE
 │
 ▼
LOCATION + RISK PROCESSOR
 │
 ├── GPS Quality
 ├── Kalman Smoothing
 ├── Map Matching
 ├── ETA Analysis
 ├── Progress Analysis
 ├── Direction Analysis
 ├── Deviation Analysis
 ├── Stop Detection
 └── Feature Extraction
 │
 ├────────────► ML RISK SERVICE
 │              ├── LightGBM/XGBoost
 │              ├── Isolation Forest
 │              └── Calibration
 │
 ▼
SAFETY DECISION ENGINE
 │
 ├── SAFE
 ├── OBSERVE
 ├── SOFT_WARNING
 ├── HIGH_RISK
 └── ESCALATED
 │
 ▼
NOTIFICATION SERVICE
 │
 ├── User Alert
 ├── Trusted Contact Push
 ├── SMS Fallback
 └── Delivery Tracking
 │
 ▼
POSTGRESQL + POSTGIS
REDIS
AUDIT LOGS
```

---

# 31. Recommended Final Stack

## Frontend
- Flutter.
- Riverpod or BLoC.
- Secure local storage.
- Drift/SQLite.
- Maps SDK through provider abstraction.

## Backend
- NestJS + TypeScript, or FastAPI if choosing a single Python backend.
- REST APIs.
- Event-driven risk processing.

## Database
- PostgreSQL.
- PostGIS.
- Redis.

## Async Processing
- RabbitMQ or managed cloud queue.

## Maps
- Google Maps or Mapbox behind a provider abstraction.
- Routing, ETA, alternatives, and map matching selected based on required coverage and travel modes.

## ML
- Python.
- FastAPI.
- scikit-learn.
- LightGBM or XGBoost.
- Isolation Forest.
- HDBSCAN/DBSCAN where needed.

## Notifications
- Firebase Cloud Messaging.
- SMS fallback for configured escalation.

## Infrastructure
- Docker.
- Managed PostgreSQL.
- Cloud object storage.
- Secrets manager.
- CI/CD.
- OpenTelemetry-compatible monitoring.

---

# 32. Production Definition of Done

The application is ready for production only when:

- [ ] Secure account management works.
- [ ] Trusted contacts work.
- [ ] Trips can be created and started.
- [ ] Primary and alternative routes work.
- [ ] Background monitoring is implemented within platform policies.
- [ ] GPS samples are validated and smoothed.
- [ ] Road-aware map matching or equivalent logic is operational.
- [ ] ETA, progress, direction, deviation, and stop signals are calculated.
- [ ] Valid detours are handled.
- [ ] Risk uses temporal persistence.
- [ ] Soft warnings can be acknowledged.
- [ ] High-risk alerts follow deterministic escalation policy.
- [ ] Trusted contacts can receive notifications.
- [ ] Arrival alerts work.
- [ ] Offline/degraded states are modeled.
- [ ] Trip and alert history work according to retention policy.
- [ ] ML models are evaluated, calibrated, versioned, and monitored.
- [ ] Alert decisions are explainable.
- [ ] Security and privacy controls are implemented.
- [ ] End-to-end observability is available.
- [ ] Simulation and field tests cover normal and abnormal scenarios.
- [ ] Battery, latency, reliability, and false-positive performance are measured.

---

# Final Summary

This project is a full-stack passive travel monitoring system. Its main technical challenge is not simply tracking GPS; it is correctly deciding whether a journey is still progressing reasonably toward its destination.

The complete system combines:

```text
GPS quality processing
+ Kalman smoothing
+ map matching
+ ETA progress analysis
+ destination progress tracking
+ direction analysis
+ adaptive route deviation
+ stop anomaly detection
+ temporal persistence
+ deterministic safety rules
+ ML risk and anomaly estimation
+ staged alerts
+ trusted-contact escalation
+ destination arrival alerts
```

The final behavior should be simple for the user:

**Set the destination. Start the trip. Travel normally. The system stays quiet when everything looks normal and increases attention only when multiple signals show sustained abnormal journey behavior.**
