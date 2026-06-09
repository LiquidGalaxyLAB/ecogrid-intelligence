# EcoGrid Intelligence 🌍⚡

A Flutter Android application developed as part of **Google Summer of Code 2026** under [Liquid Galaxy LAB](https://github.com/LiquidGalaxyLAB).

## About

Global power generation facilities face escalating threats from severe climate events — heatwaves, droughts, and wind anomalies. Critical infrastructure and meteorological data are typically siloed, preventing stakeholders from achieving a unified understanding of environmental stress on energy systems.

EcoGrid Intelligence is an AI-driven geospatial analysis system built for the Liquid Galaxy platform. It dynamically fuses live climate anomalies with global energy infrastructure maps, proactively identifying power grids at risk of operational failure in real-time.

## How It Works

| Component | Source | Description |
|-----------|--------|-------------|
| Climate Data | Open-Meteo API | Live climate anomalies: temperature deviations, precipitation extremes, and wind intensity |
| Infrastructure Data | Global Power Plant Database (WRI) | Geospatial coordinates, generation type, and operational capacity |
| Risk Model | Climate Vulnerability Score (CVS) | Computes dynamic risk by evaluating anomaly intensity against plant type sensitivities |

## Tech Stack

- **Flutter** (Android)
- **Clean Architecture** with BLoC state management
- **Liquid Galaxy** integration via SSH

## Getting Started

```bash
flutter pub get
flutter run
```
