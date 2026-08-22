# Construction Management System (CMS) Mobile App

A feature-rich Flutter mobile application designed for real-time construction site management, resource tracking, and field reporting. The app integrates with a Frappe ERP backend using a clean architecture design pattern.

---

## 🏗️ Architecture

This project follows **Clean Architecture** principles separated into layers to ensure maintainability, testability, and clear separation of concerns.

```
lib/
├── core/                  # Core modules (configurations, themes, network, services)
│   ├── config/            # App-wide configs & environment variables
│   ├── di/                # Dependency injection using GetIt
│   ├── error/             # Exception classes, failures, and session managers
│   ├── services/          # Shared cross-cutting services (e.g. project selection)
│   └── theme/             # Custom UI theme guidelines
└── features/              # Feature modules (domain, data, presentation per feature)
    └── [feature_name]/
        ├── data/          # Models & data sources (Frappe SDK connections)
        ├── domain/        # Entities & Use cases
        └── presentation/  # Widgets, Pages & BLoC state management
```

* **State Management:** [flutter_bloc](https://pub.dev/packages/flutter_bloc) (BLoC pattern) for predictability and state separation.
* **Dependency Injection:** [get_it](https://pub.dev/packages/get_it) service locator to manage instances dynamically.
* **Data Layer Integration:** Communicates with Frappe API using the customized `frappe_mobile_sdk`.

---

## 📱 Features

The application supports the following core modules:

* 🔐 **Authentication (`auth`)**: Integrated login and profile system using Frappe OAuth.
* 📂 **Projects (`projects`)**: View project details, dashboard metrics, stages, and timelines.
* ✍️ **Site Diary (`site_diary`)**: Log daily events on-site, upload progress photos (via camera/gallery), and capture geolocator GPS coordinates.
* 📦 **Stock Entry (`stock_entry`)**: Record and track material transfers and issues directly from the field.
* 🚚 **Material Requests (`material_requests`)**: Raise and review requests for construction materials on-demand.
* 🧾 **Purchase Receipts (`purchase_receipts`)**: Issue and inspect mobile receipts for delivered materials.
* 👥 **Usage Tracking (`usage`)**: Log daily manpower (labor) and equipment usage against project tasks.
* 📅 **Task Progress & Tasks (`task_progress`, `tasks`)**: Monitor daily progress reports, milestones, and direct task lists.
* 🗺️ **Attendance (`attendance`)**: Track check-ins and check-outs tagged with real-time GPS locations.
* ✅ **Approvals (`approvals`)**: Process and authorize pending construction workflows.

---

## 🚀 Getting Started

### Prerequisites

* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.11.5`)
* Android SDK (for Android build) & Xcode (for iOS build)
* CocoaPods (for iOS dependency management)

### Setup Configurations

1. **Clone the repository:**
   ```bash
   git clone https://github.com/QuantbitERP/construction-mgmt-sys-mobile.git
   cd construction-mgmt-sys-mobile
   ```

2. **Configure Environment Variables:**
   Copy the example environment template and fill in your Frappe instance credentials:
   ```bash
   cp .env.example .env
   ```
   Open the `.env` file and configure it with your host URL and OAuth client keys:
   ```env
   BASE_URL=https://your-frappe-instance.frappe.cloud/
   OAUTH_CLIENT_ID=your_oauth_client_id
   OAUTH_CLIENT_SECRET=your_oauth_client_secret
   ```

3. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the Project:**
   ```bash
   # Run in debug mode
   flutter run
   ```

---

## 🛠️ Dev Dependencies & Generators

* **Launcher Icons:** Uses `flutter_launcher_icons` to build platform-specific icons from the template image at `assets/images/app_icon.png`.
* To rebuild icons after modifying:
  ```bash
  flutter pub run flutter_launcher_icons
  ```