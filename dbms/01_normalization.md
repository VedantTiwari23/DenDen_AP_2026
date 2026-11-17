# Database Normalization: DenDen Platform (1NF → 2NF → 3NF → BCNF)

## 1. Project Overview & Unnormalized Representation (UNF)

DenDen is a real-time communication and live streaming application featuring instant messaging, WebRTC video calling, friendship networks, and live streaming channels.

Initially, consider an unnormalized universal relation representing an active communication and streaming session:

```text
UNF_DENDEN (
    user_id, username, email, password_hash, user_created_at,
    friend_user_id, friendship_status, friendship_created_at,
    conversation_id, conversation_title, is_group, conversation_created_at,
    participant_user_id, participant_joined_at, participant_role,
    message_id, message_sender_id, message_content, message_type, message_sent_at,
    call_id, caller_id, receiver_id, call_type, call_status, call_started_at, call_ended_at,
    stream_id, streamer_id, stream_title, stream_status, stream_started_at, stream_ended_at,
    stream_viewer_id, stream_joined_at
)
```

### Anomalies in the Unnormalized State:
1. **Insertion Anomaly:** A new user cannot be registered without also creating a fake message, conversation, or stream.
2. **Update Anomaly:** Updating a user's email requires modifying thousands of redundant rows across all messages and calls they participated in.
3. **Deletion Anomaly:** Deleting a completed live stream or message deletes the profile records of participating users.

---

## 2. First Normal Form (1NF)

### 1NF Criteria:
- All column values must be atomic (no repeating groups, comma-separated lists, or arrays).
- Each record must be uniquely identifiable by a primary key.

### Transformation to 1NF:
We separate repeating multi-valued groups into distinct flat tabular structures with composite identifiers:

1. **`USER_ACCOUNT`** (`user_id`, `username`, `email`, `password_hash`, `status`, `created_at`)
2. **`FRIENDSHIP`** (`user_id`, `friend_id`, `status`, `created_at`)
3. **`CONVERSATION`** (`conversation_id`, `conversation_title`, `is_group`, `created_at`)
4. **`CONVERSATION_PARTICIPANT`** (`conversation_id`, `user_id`, `joined_at`, `role`)
5. **`MESSAGE`** (`message_id`, `conversation_id`, `sender_id`, `content`, `message_type`, `created_at`)
6. **`CALL_LOG`** (`call_id`, `caller_id`, `receiver_id`, `call_type`, `status`, `started_at`, `ended_at`)
7. **`STREAM`** (`stream_id`, `streamer_id`, `title`, `stream_key`, `status`, `started_at`, `ended_at`)
8. **`STREAM_VIEWER`** (`stream_id`, `viewer_id`, `joined_at`)

All columns now contain atomic scalar values.

---

## 3. Second Normal Form (2NF)

### 2NF Criteria:
- The relation must already be in 1NF.
- **No Partial Functional Dependencies:** Every non-key attribute must be fully functionally dependent on the *entire* candidate key, not just a subset of a composite primary key.

### Analysis of Composite Key Tables:

#### A. `FRIENDSHIP`
- **Candidate Key:** `(user_id, friend_id)`
- **Functional Dependency:** `(user_id, friend_id) → status, created_at`
- *Evaluation:* `status` and `created_at` describe the relationship itself and depend on both users simultaneously. Neither attribute depends on `user_id` or `friend_id` alone. **(Satisfies 2NF)**

#### B. `CONVERSATION_PARTICIPANT`
- **Candidate Key:** `(conversation_id, user_id)`
- **Functional Dependency:** `(conversation_id, user_id) → joined_at, role`
- *Evaluation:* A user's `role` (e.g., admin, member) and `joined_at` depend on the specific conversation they joined. **(Satisfies 2NF)**

#### C. `STREAM_VIEWER`
- **Candidate Key:** `(stream_id, viewer_id)`
- **Functional Dependency:** `(stream_id, viewer_id) → joined_at`
- *Evaluation:* Fully dependent on the composite key. **(Satisfies 2NF)**

All tables with single-attribute primary keys (`users`, `conversations`, `messages`, `calls`, `streams`) automatically satisfy 2NF because a single-column primary key cannot have partial dependencies.

---

## 4. Third Normal Form (3NF)

### 3NF Criteria:
- The relation must be in 2NF.
- **No Transitive Dependencies:** Non-key attributes must not depend on other non-key attributes ($X \to Y \to Z$ where $X$ is the primary key). Every non-key attribute must depend directly on the primary key.

### Identified Transitive Dependencies & Decomposition:

1. **User Profiles vs Accounts:**
   - In `USER_ACCOUNT`: `user_id → username, email, bio, avatar_url, last_seen`.
   - While valid, to isolate high-churn presence data (`is_online`, `last_seen`) from immutable authentication credentials (`password_hash`, `email`), we decompose into:
     - `users(user_id, username, email, password_hash, created_at)`
     - `user_profiles(user_id, display_name, avatar_url, bio, is_online, last_seen)`
   - FD: `user_id → display_name, avatar_url, bio, is_online, last_seen` (Direct dependency).

2. **Call Logs:**
   - Instead of storing caller and receiver usernames in the call record, `call_records` stores only foreign keys referencing `users(user_id)`:
   - `call_records(call_id, caller_id, receiver_id, call_type, status, started_at, ended_at)`
   - `call_id → caller_id, receiver_id, call_type, status, started_at, ended_at`. No non-key transitive dependencies exist.

3. **Messages:**
   - `messages(message_id, conversation_id, sender_id, message_type, content, sent_at)`
   - `message_id → conversation_id, sender_id, message_type, content, sent_at`. Every attribute directly describes the message.

All relations now satisfy 3NF.

---

## 5. Boyce-Codd Normal Form (BCNF)

### BCNF Criteria:
- For every non-trivial functional dependency $X \to Y$, the determinant $X$ must be a **superkey**.

### Evaluation:
- **`users`:** `user_id → username, email, password_hash, created_at`. Determinant `user_id` is a superkey (PK). Also `email → user_id` and `username → user_id` where both are candidate keys with UNIQUE constraints.
- **`conversations`:** `conversation_id` is a superkey.
- **`conversation_participants`:** `(conversation_id, user_id) → role, joined_at`. Determinant is the composite primary key.
- **`friendships`:** `(user_id, friend_id) → status, created_at`. Determinant is the composite primary key.
- **`messages`:** `message_id` is a superkey.
- **`call_records`:** `call_id` is a superkey.
- **`streams`:** `stream_id` is a superkey, and unique `stream_key` is a candidate key (`stream_key → stream_id`).
- **`stream_viewers`:** `(stream_id, viewer_id)` is a superkey.

Because every determinant in every functional dependency is a superkey (primary key or candidate key), **all relations strictly satisfy BCNF**.