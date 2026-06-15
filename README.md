# FitConnect

A fitness tracking ecosystem connecting a Garmin ConnectIQ watch app, a mobile companion app, and a backend data service.

## Repository Structure

```
FitConnect/
├── Mobile/          # Expo (React Native) companion app
├── ConnectIQ/       # Garmin ConnectIQ watch app
└── Services/
    └── DataReceiver/ # Backend data ingestion service
```

## Projects

### Mobile

React Native app built with [Expo](https://expo.dev). Companion interface for viewing and managing fitness data collected from the watch.

**Tech:** TypeScript · Expo · React Native

```bash
cd Mobile
npm install
npx expo start
```

### ConnectIQ

Garmin watch application built with the [ConnectIQ SDK](https://developer.garmin.com/connect-iq/overview/).

**Tech:** Monkey C

### Services / DataReceiver

Backend service responsible for receiving and processing data from the watch and mobile app.
