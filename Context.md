# Draft Tactics — Master Context (Minimal)

## What This Is

Draft Tactics is a Roblox auto-battler built in Lua and synced to Roblox Studio using Rojo.

It is:
- Server-authoritative
- Deterministic
- Architected as a layered simulation
- Designed for clarity and iteration speed

All relevant files are assumed to be linked and self-documented via strong header comments.

This document provides only high-level context.

---

## Game Overview

Draft Tactics is a short-session roguelike auto-battler.

Core loop:
1. Draft a unit
2. Watch an automated battle
3. Repeat

Design principles:
- Player is a spectator, not a controller
- One meaningful decision per fight
- Battles are 20–30 seconds
- Losses must feel explainable
- Visual clarity > mechanical complexity
- Depth emerges from combinations, not systems

No mid-fight input.
No live matchmaking (async PvP model).
No complex meta-progression in MVP.

---

## Simulation Philosophy

The battle simulation is:

- Fully automated
- Server-authoritative
- Deterministic per frame
- Stateless at decision layer
- Explicit at execution layer

The system separates:

- Decision (AI intent)
- Execution (movement, fire, damage)
- Data (configs, enums)
- Orchestration (battle lifecycle)

No engine magic.
No hidden physics behavior.
No implicit movement.

All locomotion is code-driven.

---

## Architectural Model

The project follows a strict layered model:

- Configs → Immutable data
- Decision Layer → Stateless AI logic
- Runtime Layer → Mutable per-entity execution
- Services → Lifecycle orchestration
- Client Layer → UI + camera only

Rules:
- Deterministic update order
- No cross-layer leakage
- No global state mutation from runtime entities
- All side effects must be explicit

Files are self-describing via structured headers.
This document does not describe file-level responsibilities.

---

## Rojo Mapping

Source folders are mapped into Roblox Studio via Rojo:

- `src/shared` → `ReplicatedStorage/Shared`
- `src/server` → `ServerScriptService/Server`
- `src/client` → `StarterPlayer/StarterPlayerScripts/Client`

Shared contains enums, configs, and deterministic logic.
Server contains runtime simulation and orchestration.
Client contains UI and camera logic only.

---

## Collaboration Guidelines

All suggestions and changes should follow these principles:

- Work in small, incremental steps.
- Explain reasoning before proposing code changes.
- Avoid large architectural shifts unless explicitly requested.
- Prefer minimal surface-area refactors.
- Do not rewrite stable systems without cause.
- Do not introduce new abstractions prematurely.
- Avoid tangents or speculative redesigns.
- Preserve determinism and layer boundaries.
- Keep changes localized whenever possible.

If proposing a refactor:
- Clearly state the problem being solved.
- Describe the minimal viable change.
- Avoid touching unrelated systems.

The goal is controlled evolution, not opportunistic redesign.

---

## Core Constraints

- Short sessions (15–25 minutes)
- Small team sizes
- No feature sprawl
- No mid-battle abilities
- No hidden mechanics
- No non-deterministic behavior

Clarity, determinism, and architectural discipline are prioritized over feature volume.

---

## Assumptions

- All files contain strong header comments describing their role and invariants.
- This document intentionally avoids referencing individual modules.
- Detailed behavior is defined in-file, not here.

---

End of master context.