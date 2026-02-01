# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the app
swift build

# Run the app
swift run

# Build for release
swift build -c release
```

## Architecture

FinansApp is a macOS personal finance application built with SwiftUI. It parses credit card statements (PDF) using AI (OpenAI or Google Gemini) and provides spending analytics.

### Core Components

**AppState** (`Services/AppState.swift`)
- Central state management using `@MainActor` and `@ObservableObject`
- Coordinates all data operations between UI and services
- Handles PDF parsing workflow with AI providers

**DatabaseService** (`Services/DatabaseService.swift`)
- SQLite-based local storage (singleton pattern)
- Tables: `cards`, `statements`, `transactions`, `categories`
- Located at `~/Library/Application Support/FinansApp/finans.db`

**AI Services** (`Services/OpenAIService.swift`, `Services/GeminiService.swift`)
- Parse PDF statements into structured data (`ParsedStatement`)
- Extract card info, statement details, and categorized transactions
- API keys stored in UserDefaults

### Data Flow

1. User uploads PDF → AI service extracts `ParsedStatement`
2. AppState creates/finds Card, creates Statement, creates Transactions
3. DatabaseService persists all data
4. Views observe AppState for updates

### Navigation Structure

`ContentView` uses `NavigationSplitView` with sidebar navigation:
- Dashboard (charts, stats)
- Statements (PDF uploads)
- Transactions (list with bulk category editing)
- Cards (manage credit cards)
- Comparison (month-to-month analysis)
- AI Insights
- Settings

### Key Models (`Models/Models.swift`)

- `Card`, `Statement`, `Transaction` - Core data models (Codable)
- `Category` - Spending categories with custom category support
- `DateFilter` - Flexible date range filtering
- `NavigationItem` - Sidebar navigation enum

## Localization

UI is in Turkish. Currency format: TRY (₺).
