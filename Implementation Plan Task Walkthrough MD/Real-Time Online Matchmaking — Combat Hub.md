# Real-Time Online Matchmaking — Combat Hub

## Overview
The Combat Hub currently shows a static radar with online user count and a list of open rooms. This plan turns it into a **real matchmaking system** that:

1. Shows **live registered players** who are online right now with their username, level, and avatar
2. Provides **smart auto-matchmaking** — tap "FIND MATCH" and the system automatically pairs you with the best opponent by skill (level proximity)
3. Allows **direct challenges** — tap a player on the radar → challenge them
4. Still supports **manual room creation** for custom battles
5. Host waits in a live room screen until opponent joins, then both get pushed to `/game`

---

## How It Works (Architecture)

```
Player opens Combat Hub
      │
      ▼
Presence channel tracks: { user_id, display_name, username, current_level, avatar_url, status: 'idle'|'searching'|'in_match' }
      │
      ├─► Radar shows all idle/searching players as live pips (with names + levels)
      │
      ├─► "FIND MATCH" button → sets status = 'searching'
      │       └─► Background: scan rooms table every 2s, auto-join best match OR create room if none found after 5s
      │
      ├─► "CHALLENGE" (tap a pip) → creates a room targeting that player_id
      │
      └─► Room accepted → both navigate to /game with shared seed
```

---

## Supabase Changes Required

> [!IMPORTANT]
> You need to run these SQL migrations in your Supabase project dashboard (SQL Editor):

```sql
-- 1. Add matchmaking fields to rooms table
ALTER TABLE rooms
  ADD COLUMN IF NOT EXISTS host_username TEXT,
  ADD COLUMN IF NOT EXISTS host_level    INT DEFAULT 1,
  ADD COLUMN IF NOT EXISTS guest_username TEXT,
  ADD COLUMN IF NOT EXISTS challenged_user_id UUID,   -- for direct challenges
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();

-- 2. Clean up stale rooms older than 10 minutes
CREATE OR REPLACE FUNCTION delete_old_rooms() RETURNS void AS $$
  DELETE FROM rooms WHERE created_at < now() - interval '10 minutes' AND status = 'waiting';
$$ LANGUAGE sql;
```

---

## Proposed Changes

### 1. Multiplayer Provider — `[MODIFY]`
#### [MODIFY] `lib/features/lobby/providers/multiplayer_provider.dart`

**New `PresenceUser` model:**
```dart
class PresenceUser {
  final String userId, displayName, username;
  final int level;
  final String? avatarUrl;
  final String status; // 'idle' | 'searching' | 'in_match'
}
```

**New `Room` fields:** `hostUsername`, `hostLevel`, `guestUsername`, `challengedUserId`, `createdAt`

**New `MultiplayerState` fields:** `presenceUsers`, `matchmakingStatus` (`idle`/`searching`/`matched`), `myRoom`

**New methods on `MultiplayerNotifier`:**
- `startMatchmaking()` — sets presence status to `searching`, auto-joins the closest-level waiting room or creates one
- `stopMatchmaking()` — cancels search, removes room if created
- `challengePlayer(PresenceUser target)` — creates a targeted room
- `_watchForMatch(String roomId)` — streams room updates; when `status == 'playing'`, navigates to game
- Presence now tracks: `current_level`, `status`, `username`

---

### 2. Combat Hub Screen — `[MODIFY]`
#### [MODIFY] `lib/features/lobby/screens/multiplayer_lobby_screen.dart`

**New UI sections:**

**A. Live Player Radar (enhanced)**
- Player pips now show username (3 chars) + level badge
- Color-coded: green = idle (challengeable), amber = searching (matchable), red = in match (busy)
- Tap any green/amber pip → shows a `_ChallengeDialog` with player card + "CHALLENGE" button

**B. Matchmaking Banner** (replaces just the room list header)
- `FIND MATCH` button with animated pulse when searching
- Shows "Searching… X players in queue" during search
- Animated "MATCH FOUND!" card when paired

**C. Open Rooms list** — shows host name, host level, difficulty badge, BATTLE button
- Room cards now show host username and level instead of raw UUID

**D. Active Challenges section** — shows incoming direct challenges with Accept/Decline

---

### 3. Waiting Room Screen — `[NEW]`
#### [NEW] `lib/features/lobby/screens/waiting_room_screen.dart`
- Shown to the room host after creating a room / starting matchmaking
- Animated "Waiting for opponent…" pulsing ring
- Shows the host's level & the room settings
- Live Supabase stream: when `room.status == 'playing'` → auto-navigate to `/game`
- Cancel button → deletes room, returns to Combat Hub

---

### 4. Router — `[MODIFY]`
#### [MODIFY] `lib/core/router/app_router.dart`
- Add `/waiting-room` route that takes a `Room` via `extra`

---

## Verification Plan

### Automated
- `flutter analyze` — 0 errors

### Manual (two devices / accounts)
1. Open Combat Hub on Device A → see yourself on radar
2. Open Combat Hub on Device B → see Device A player on radar
3. Device B taps "FIND MATCH" → both devices auto-match → both enter game
4. Device A taps Device B's pip → Challenge dialog → Device B sees incoming challenge card → Accept → both enter game
5. Stale rooms (>10min) auto-clean

---

## Open Questions

> [!NOTE]
> **Difficulty for auto-matchmaking**: Should "FIND MATCH" always use `medium` difficulty, or should the player pick it first?
> Defaulting to a quick difficulty picker shown before matchmaking starts.

> [!NOTE]
> **Skill matching**: Matching by closest `current_level`. Is this acceptable, or do you want ELO-style rating later?
