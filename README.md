# Daily Katha

Flutter user-facing app for Daily Katha.

## API Base URL

The app reads the CMS app APIs from `API_BASE_URL`.

Default behavior:

- Android emulator: `http://10.0.2.2:4000`
- iOS simulator / desktop / web: `http://localhost:4000`

For a physical Android phone, `localhost` points to the phone itself, not your computer. Use your computer LAN IP.

Current local example:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.0.3:4000
```

If you build an APK for a physical phone:

```bash
flutter build apk --debug --dart-define=API_BASE_URL=http://192.168.0.3:4000
```

The backend must also listen on all interfaces, for example:

```bash
HOST=0.0.0.0 PORT=4000 npm run dev
```

or the equivalent command for your CMS server.

## Public APIs Used

- `GET /api/app/stories`
- `GET /api/app/stories/:storyId/days/:dayNumber`
- `POST /api/app/questions/:questionId/check-answer`

No admin APIs are used.

## Web Preview

To view the app UI in the browser without running the CMS, build with demo data:

```bash
flutter build web --dart-define=USE_DEMO_DATA=true
python3 -m http.server 8080 --directory build/web
```

Open:

```text
http://localhost:8080
```

To connect the web app to the CMS instead, run the CMS server and build without `USE_DEMO_DATA`, or pass a custom base URL:

```bash
flutter build web --dart-define=API_BASE_URL=http://localhost:4000
```

## Checks

```bash
flutter analyze
flutter build web --dart-define=USE_DEMO_DATA=true
flutter build apk --debug
```
