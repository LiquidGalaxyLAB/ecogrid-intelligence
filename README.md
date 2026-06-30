# 🌍 EcoGrid Intelligence

<div align="center">
  <img src="assets/images/regions/dark/africa.png" alt="EcoGrid Intelligence" height="200" />
</div>

<p align="center">
  <strong>AI-Driven Climate Resilience Analysis for Global Energy Infrastructure on Liquid Galaxy</strong>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://dart.dev/"><img src="https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"></a>
  <a href="https://liquidgalaxy.eu/"><img src="https://img.shields.io/badge/Liquid_Galaxy-000000.svg?style=for-the-badge&logo=google-earth&logoColor=white" alt="Liquid Galaxy"></a>
</p>

## 📖 Overview

**EcoGrid Intelligence** is an advanced Flutter application designed specifically for the **Liquid Galaxy** platform. It provides an interactive, AI-driven analysis of global energy infrastructure and climate resilience. By combining interactive maps, large language models (Google Gemini), and rich visualization, it allows researchers and policymakers to explore energy data across different regions of the world.

## ✨ Key Features

- **🌐 Liquid Galaxy Integration**: Native SSH-based connection to control and visualize data across a Liquid Galaxy rig.
- **🤖 AI Insights**: Powered by the **Gemini API** to provide deep, contextual intelligence on climate resilience and energy infrastructure.
- **🗺️ Interactive Maps**: Built-in Google Maps integration to explore energy plants and infrastructure globally.
- **🎙️ Voice & TTS**: Speech-to-text for querying, and Text-to-speech (TTS) for reading out AI insights.
- **📊 Data Visualization**: Beautiful and responsive charts to visualize complex energy data.
- **🌙 Dark/Light Modes**: Thematic UI that adapts to user preference with custom regional styling.

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Flutter BLoC](https://bloclibrary.dev/)
- **Dependency Injection**: [GetIt](https://pub.dev/packages/get_it)
- **Database (Local Cache)**: [Drift (SQLite)](https://drift.simonbinder.eu/)
- **Networking**: [Dio](https://pub.dev/packages/dio)
- **Liquid Galaxy**: [DartSSH2](https://pub.dev/packages/dartssh2)
- **AI Integration**: Custom Gemini integration

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.12.0`)
- A Liquid Galaxy rig (or virtual setup) for the full experience
- Google Maps API Key
- Gemini API Key

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/LiquidGalaxyLAB/ecogrid-intelligence.git
   cd ecogrid-intelligence
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Environment Setup:**
   Create a `.env` file in the root of the project with the following keys:
   ```env
   GEMINI_API_KEY=your_gemini_api_key_here
   GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
   ```

4. **Run the App:**
   ```bash
   flutter run
