# Spendora Flutter

Spendora is a personal finance app prototype built with Flutter.

## Current MVP

- Dashboard with balance, income, and expense summaries
- Transactions feed with income/expense filters
- Budgets tab with per-category spending progress
- Insights tab with spending breakdown by category
- Add-entry flow using a bottom sheet form

## Run

```bash
flutter pub get
flutter run
```

### Real Device Backend URL

If you run on a physical Android/iOS device, set your backend LAN URL:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080
```

Use your machine's local network IP instead of `192.168.1.10`.

## Test

```bash
flutter test
```
