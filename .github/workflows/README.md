# CI/CD Workflows & Code Quality Guide

The primary purpose of these automated pipelines is to ensure code quality, run static analysis, and verify tests on every Pull Request and branch push before merging changes into shared branches.

---

## 1. Workflows Overview

### A. Flutter Mobile App CI (`app-ci.yml`)

* **Triggers:** Push or Pull Request affecting files inside `app/**` or the workflow file `.github/workflows/app-ci.yml`. Also supports manual execution via `workflow_dispatch`.
* **Execution steps:**
  1. **Checkout repository** – Retrieves the codebase.
  2. **Set up Java 17 & Flutter SDK** – Configures the build environment with dependency caching enabled.
  3. **Create mock `.env`** – Copies `.env.example` to `.env` so asset resolution in `pubspec.yaml` does not fail during analysis and tests.
  4. **Install dependencies** – Executes `flutter pub get`.
  5. **Static code analysis** – Runs `flutter analyze` with strict rules (fails on any error or warning).
  6. **Unit & widget tests** – Executes `flutter test` in an isolated environment using mocks.

### B. Django Backend CI (`server-ci.yml`)

* **Triggers:** Push or Pull Request affecting files inside `server/**` or the workflow file `.github/workflows/server-ci.yml`.
* **Execution steps:**
  1. **Set up Python 3.12**.
  2. **Install dependencies** from `requirements.txt`.
  3. **Run tests (`python manage.py test`)** – Tests run using an in-memory/SQLite database setup to avoid calling the cloud development database (Neon).
* *Deployment note:* Continuous Deployment (**CD**) for the backend runs on Render automatically upon merging changes into the `develop` branch.

---

## 2. Pre-Commit Checklist (Flutter)

To prevent CI failures caused by styling or linting violations, always run the following commands inside `app/` before creating a commit:

```bash
cd app

# 1. Automatically apply simple linter fixes
dart fix --apply

# 2. Format code and organize import directives
dart format .

# 3. Run static analysis (must report "No issues found!")
flutter analyze

# 4. Run test suite
flutter test
```

---

## 3. IDE Setup (Format & Fix on Save)

Configuring your IDE ensures formatting and import sorting happen automatically on every `Ctrl + S` / `Cmd + S`.

### Android Studio

1. Open **Settings** (`Ctrl + Alt + S` on Windows/Linux or `Cmd + ,` on macOS).
2. Navigate to: **Languages & Frameworks** → **Flutter**.
3. Check the following:
   * **Format code on save**
   * **Organize imports on save**
4. Alternatively, under **Tools** → **Actions on Save**, enable:
   * **Reformat code**
   * **Optimize imports**

*Helpful shortcuts:*
* `Ctrl + Alt + L` (`Cmd + Option + L`) – Reformat current file.
* `Ctrl + Alt + O` (`Cmd + Option + O`) – Optimize and sort imports.
* `Alt + Enter` – Quick-fix menu on highlighted warnings/errors.

---

## 4. Common Linter Rules & Troubleshooting

1. **`directives_ordering` (Import ordering):**
   * All `package:` imports must reside in a **single group** sorted alphabetically (e.g., `package:common_pantry/...` before `package:flutter/...`).
   * Avoid blank lines between import statements of the same package group.

2. **`always_use_package_imports`:**
   * Do not use relative imports (such as `../core/...` or `'app.dart'`) inside the `lib/` directory. Always use the project package URI:
     ```dart
     import 'package:common_pantry/app.dart';
     ```

3. **`inference_failure_on_function_invocation` (Explicit Generics):**
   * Network and serialization methods (such as `dio.fetch` or `dio.post`) require explicit type arguments:
     ```dart
     final response = await dio.post<Map<String, dynamic>>('/api/auth/token/', data: ...);
     ```

4. **`unchecked_use_of_nullable_value`:**
   * When accessing response data dictionaries, use null-aware access (`response.data?['key']`) because `data` can be null if the request encounters an issue.

5. **`*_test.dart` entrypoints:**
   * Every file matching `*_test.dart` inside the `test/` folder is treated as an executable test suite and **must** define a `void main()` function. Never commit empty or completely commented-out `*_test.dart` files.