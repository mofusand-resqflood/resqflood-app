# ResQFlood

ResQFlood is a Flutter application for flood emergency coordination in Malaysia. The project has three planned user roles: Residents, First Responders, and Shelter Managers.

The **Resident** role is implemented first. The **Responder** and **Shelter Manager** roles are currently in progress, with placeholder files prepared for their upcoming implementations. Some screens and routes are placeholders until their assigned Jira stories are implemented. Do not treat placeholder screens or sample data as production-ready emergency services.

## Technology

- Flutter and Dart
- Supabase Authentication and backend services
- English and Bahasa Melayu localization

## Project structure

```text
lib/
  core/                    Shared app setup, authentication gate, routes, theme
  features/
    resident/
      auth/                Resident registration and sign-in
      chatbot/             Emergency topics and chatbot
      dashboard/           Resident home screen
      nearby/              Shelters and blocked roads
      offline/             Offline queue and synchronization
      profile/             Resident profile and settings
      sos/                 Emergency request form
      tracking/            Active rescue request tracking
  l10n/                    Source and generated localization files
  models/                  Data models shared by features
  services/                Backend, device, and application services
  widgets/                 Reusable widgets shared by multiple features

assets/
  ml/                      Machine-learning assets
  topics/                  Offline emergency-topic content

supabase/
  functions/               Supabase Edge Functions
  migrations/              Database schema and access policies

test/
  resident/                Resident feature tests
```

Keep feature-specific widgets inside their respective feature folders. For example:

`lib/features/resident/dashboard/widgets/`

Place a widget in `lib/widgets/` only when it is shared across multiple features.

## Naming and organization rules

- Name Dart files and folders using `snake_case`, such as `sos_form_screen.dart`.
- Name classes and enums using `UpperCamelCase`, such as `ResidentProfile`.
- Name variables, methods, and route constants using `lowerCamelCase`, such as `signIn` and `activeRequest`.
- Group resident code by feature. Keep each feature's screens and feature-specific widgets together.
- Put shared app setup in `lib/core/`, shared data models in `lib/models/`, and application services in `lib/services/`.
- Add tests under `test/resident/` and name them according to the behavior they cover, such as `phone_validation_test.dart`.
- Register named navigation routes in `lib/core/app_routes.dart` using `AppRoutes` constants.

## Requirements

Install and configure the following:

- Flutter SDK
- Git
- Android Studio and Android SDK for Android development
- A Supabase project for authentication and backend features

Check that Flutter is installed and available:

```bash
flutter --version
flutter doctor
```

## Clone and set up the project

Clone the repository and switch to the `develop` branch:

```bash
git clone --branch develop https://github.com/mofusand-resqflood/resqflood-app.git
cd resqflood-app
flutter pub get
```

If you already have a local copy of the repository, update it from `develop` instead:

```bash
git switch develop
git pull --ff-only origin develop
flutter pub get
```

## Supabase configuration

The app reads the following compile-time values:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Create a file named `.env.json` in the project root (the same folder as `pubspec.yaml`):

```json
{
  "SUPABASE_URL": "https://YOUR_PROJECT_REF.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY"
}
```

Replace the example values with the URL and publishable key (or legacy anon key) from your Supabase project.

Run the app using this configuration file:

```bash
flutter run --dart-define-from-file=.env.json
```

**Important security notes:**

- Keep `.env.json` out of Git. It is already included in this project's `.gitignore`.
- Never commit or expose `.env.json` in the GitHub repository.
- Never put a Supabase `service_role` key or secret key in the Flutter application, README, or any other client-accessible file.
- Backend access must be protected by appropriate Supabase Row Level Security (RLS) policies.
- Each team member must create their own local `.env.json` file. The file is not shared through GitHub.

## Run and test

List the available devices:

```bash
flutter devices
```

Run the application on a connected device or select a device when prompted:

```bash
flutter run --dart-define-from-file=.env.json
```

Before pushing your changes, run formatting, static analysis, and tests:

```bash
dart format lib test
flutter analyze
flutter test
```

All checks should complete successfully before creating a pull request.

Some test files may contain temporary placeholder tests while their corresponding features are still under development. Replace these with actual test cases when implementing the relevant features.

### Running on Windows (PowerShell)

With `.env.json` in the project root, run:

```powershell
.\run_resqflood.ps1
```

## Jira branch and pull-request workflow

Do not commit feature work directly to `develop` or `main`.

Start from the latest `develop` branch and create a feature branch containing the relevant Jira issue key:

```bash
git switch develop
git pull --ff-only origin develop
git switch -c feature/RQF-123-short-description
```

Replace `RQF-123-short-description` with the actual Jira issue key and a short description of the feature.

After implementing and testing the story, check your changes:

```bash
git status
git diff --check
```

Stage the relevant files, commit your changes, and push the feature branch:

```bash
git add path/to/changed-file.dart
git commit -m "feat(RQF-123): short description"
git push -u origin HEAD
```

Replace the example Jira key and commit description with the actual issue details.

Open a pull request on GitHub with `develop` as the base branch. Request a review from a team member.

After the pull request has been approved and merged, update your local `develop` branch:

```bash
git switch develop
git pull --ff-only origin develop
```

Continue new development work from the updated `develop` branch.