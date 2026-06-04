# EcoGrid Intelligence 🌍⚡

A Flutter (Android) application built for **Google Summer of Code 2025** under the [Liquid Galaxy LAB](https://github.com/LiquidGalaxyLAB) organization.

EcoGrid Intelligence is an AI-powered climate and energy monitoring platform that visualizes real-time power plant data, climate risk analysis, and environmental anomalies on Liquid Galaxy satellite displays.

---

## ✨ Features

- 🗺️ **Interactive Power Plant Explorer** – Browse and search global power plants with detailed information
- 🌡️ **Climate Risk Analysis** – Real-time climate vulnerability scoring (CVS) for each plant location
- 🤖 **AI-Powered Insights** – Natural language analysis of plant health and climate stress via Groq AI
- 📡 **Liquid Galaxy Integration** – Sends KML visualizations directly to Liquid Galaxy satellite display systems over SSH
- 📊 **Anomaly Detection Engine** – Automatically flags abnormal weather patterns and stress events
- 💾 **Offline Caching** – Local data persistence for climate and power plant data

---

## 🏗️ Architecture

This project follows **Clean Architecture** principles with three distinct layers:

```
lib/
├── config/          # App configuration, theme
├── core/            # Enums, utilities, models (CVS calculator, KML generator, anomaly engine)
├── data/            # Data sources (remote APIs, local cache) & repository implementations
├── domain/          # Entities, repository contracts (business logic layer)
├── presentation/    # BLoC state management, screens, widgets
├── service/         # SSH service for Liquid Galaxy communication
└── di/              # Dependency injection container
```

**State Management:** Flutter BLoC  
**Dependency Injection:** GetIt  
**Architecture Pattern:** Clean Architecture (Data → Domain → Presentation)

---

## 🔌 APIs & Services

| Service | Purpose |
|--------|---------|
| [Open-Meteo](https://open-meteo.com/) | Free real-time and historical weather data |
| [Groq AI](https://groq.com/) | Fast AI inference for plant health analysis |
| SSH (dartssh2) | Liquid Galaxy display control |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- Android Studio / VS Code
- Android device or emulator (API 21+)

### Installation

```bash
# Clone the repository
git clone https://github.com/LiquidGalaxyLAB/ecogrid-intelligence.git
cd ecogrid-intelligence

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Environment Setup

Create a `.env` file in the root directory (never commit this file):

```
GROQ_API_KEY=your_groq_api_key_here
```

---

## 🤝 Contributing

This project is developed as part of GSoC 2025. All contributions are made through Pull Requests targeting the `main` branch following [Conventional Commits](https://www.conventionalcommits.org/) standards.

---

## 👩‍💻 Developer

**Bhoomi Shivhare**  
GSoC 2025 Contributor – Liquid Galaxy LAB  

---

## 📄 License

This project is licensed under the Apache 2.0 License.
