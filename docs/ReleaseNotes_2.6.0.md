# OpenResponses Release Notes - Version 2.6.0

## Overview
Version 2.6.0 resolves parameter compliance conflicts with the OpenAI Responses API, introduces an interactive model picker on the main chat page, and migrates CI/CD guidelines to Apple Xcode Cloud.

---

## Key Updates

### 1. OpenAI Responses API Compliance
* Resolved a `400 Bad Request` error caused by duplicate root-level `verbosity` parameters in `OpenAIService.swift`.
* Normalized payload mapping to pass the verbosity level nested under `text.verbosity` in alignment with the official Responses API specification.

### 2. Conversations API Resilience
* Added a graceful interceptor for `405 Method Not Allowed` responses on the listing endpoint `GET /v1/conversations`.
* The client fallback logic automatically returns an empty list response, preventing network error logs on launch and stabilizing local execution.

### 3. Interactive Model Picker Menu
* Upgraded the static model badge in `ChatStatusBar` to an interactive `Menu` picker.
* Users can now select and switch models on-the-fly directly from the main chat viewport.
* Supports active validation: changing the model evaluates tool compatibility (such as dynamically disabling the computer tool if the model lacks support) and saves the changes to persistent storage.
* Implemented new color tokens for visual identification: `.teal` for the GPT-5.6 family and `.indigo` for the GPT-5 family.

### 4. Native Xcode Cloud CI/CD Migration
* Removed legacy Fastlane automation guidelines from `CI_CD_Pipeline.md` and release pipelines.
* Documented native **Xcode Cloud** workflows to handle automated UI/unit testing, signing, archiving, and TestFlight internal releases.
* Consolidated the App Store Release Plan Checklist for the 2.6.0 submission target.

---

## Verification Evidence
* **Unit & UI Tests:** Completed with 0 failures on the iOS 27.0 (iPhone 17 Pro) simulator target.
* **Build Targets:** Clean builds verified for testing schemes, Release configurations, and App Store Connect archiving.
