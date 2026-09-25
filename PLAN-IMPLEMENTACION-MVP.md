# PLAN DE IMPLEMENTACIÓN — PIPE MVP

**Documento complementario a:** `../PRD-PIPE FINANZAS PERSONALES.txt`
**Proyecto:** `pipefinanzaspersonales`
**Plataforma inicial:** Android
**Creado:** 2026-09-25

---

## 0. Cómo usar este documento

Este plan existe para que **cualquier sesión de OpenCode pueda retomar el trabajo
exactamente donde se dejó**, sin depender de la memoria de una conversación anterior.

### 0.1 Veredicto sobre el PRD

**Sí, el PRD es suficiente para construir el MVP completo.** Cubre los 39 apartados
necesarios:

| Área PRD | Cobertura | ¿Alcanza? |
|---|---|---|
| Alcance (§4) | Incluido / excluido explícitos | Sí |
| Modelo de datos (§28–30) | Tablas, campos, relaciones | Sí |
| Pantallas (§11–13) | Dashboard, historial, resumen mensual | Sí |
| Validaciones (§15) | Monto, categoría, fecha, descripción | Sí |
| Paleta y tema (§17–21) | Hex completos y reglas de uso | Sí |
| Arquitectura (§25–27) | Capas y estructura de carpetas | Sí |
| Cálculos (§32) | Balance, totales, agrupamiento | Sí |
| Testing (§33) | Unit y widget tests obligatorios | Sí |
| Privacidad (§36) | Local, sin red, sin permisos | Sí |

**Lo que el PRD NO define** son 13 puntos de implementación (state management,
navegación, tipos de columna, formato de moneda, etc.). Todos quedan cerrados en la
[sección 2](#2-decisiones-técnicas-cerradas). **Ninguno cambia el alcance del
producto** — son decisiones técnicas que el PRD deja deliberadamente abiertas.

**Regla de precedencia:** el PRD manda sobre *qué* construir. Este plan manda sobre
*cómo* se implementa. Si el código escrito contradice al PRD, es un bug: corregir
el código.

### 0.2 Protocolo de reanudación

**Al empezar una sesión:**

1. Leer este documento completo.
2. Leer el PRD (`../PRD-PIPE FINANZAS PERSONALES.txt`).
3. Ir a la [sección 4](#4-mapa-de-secuencias) y localizar la **primera secuencia
   cuyo checkbox esté en `[ ]`**.
4. Verificar que todas sus dependencias están en `[x]`.
5. Ejecutar esa secuencia **completa**, sin dejarla a medias.
6. Arranque obligatorio antes de tocar código:

```bash
cd "C:/pruebas/pipe dev/proyectos/app finanzas personales/pipefinanzaspersonales"
git status
git log --oneline -5
flutter --version
flutter analyze
```

**Al terminar una secuencia:**

1. Marcar el checkbox como `[x]` en la [sección 4](#4-mapa-de-secuencias).
2. Correr los **comandos de aceptación** de esa secuencia. Todos deben pasar.
3. Commit con el mensaje del "Checkpoint" de la secuencia.
4. **No** hacer commit si algún comando de aceptación falla.

**Regla de alcance:** una secuencia por sesión. Si una queda a medias, no marcarla
como completada y anotar en el mensaje de commit qué falta.

---

## 1. Estado actual del repositorio

### 1.1 Ya hecho (no rehacer)

| Elemento | Detalle |
|---|---|
| Proyecto Flutter | Flutter 3.41.2 · Dart 3.11.0 · Android |
| Íconos de launcher | `flutter_launcher_icons` en 6 plataformas |
| Assets de imagen | `app_icon.png`, `app_icon_foreground.png`, `logo_mark.png`, `logo_horizontal.png` |
| Nombre visible | "Pipe Finanzas" en Android, iOS y Web |
| `analysis_options.yaml` | Configurado; excluye `tool/` |
| `tool/make_icon.dart` | Generador reproducible de íconos |

### 1.2 A reemplazar en S00

| Archivo | Motivo |
|---|---|
| `lib/main.dart` | Contiene el contador de demo de Flutter |
| `lib/screens/splash_screen.dart` | Fuera de la estructura del PRD; define `AppColors` que contradice la paleta del PRD |

### 1.3 Restricción crítica del entorno

El SDK local es **Dart 3.11.0** y **Flutter 3.41.2 fija `meta 1.17.0`**. Esto
restringe qué versiones de paquetes se pueden instalar. Ya se verificó por
resolución real (`flutter pub add --dry-run`) qué conjunto funciona.

**No subir estas versiones sin volver a verificar**, o la resolución falla.

---

## 2. Decisiones técnicas cerradas

### 2.1 Stack y versiones verificadas

```yaml
dependencies:
  flutter_riverpod: ^3.3.2      # 3.4.x exige Dart ^3.12.0 — NO subir
  go_router: ^17.0.1            # 18.x exige Dart ^3.12.0 — NO subir
  drift: ^2.34.0
  drift_flutter: ^0.3.1
  intl: ^0.20.3

dev_dependencies:
  build_runner: ^2.15.1         # >=2.15.2 exige meta ^1.18.3 — NO subir
  drift_dev: ^2.34.0            # 2.35.0 exige analyzer >=13 → meta ^1.18 — NO subir
```

Versiones que efectivamente se resuelven: `analyzer 10.0.1`, `build_runner 2.15.1`,
`drift 2.34.0`, `drift_dev 2.34.0`, `flutter_riverpod 3.3.2`, `go_router 17.0.1`,
`intl 0.20.3`, `sqlite3 3.5.2`.

**Por qué `drift_flutter` y no `sqlite3_flutter_libs` directamente:** la versión
`0.6.0+eol` está marcada *end-of-life*. `drift_flutter` la envuelve y además resuelve
`path_provider` y la ruta de almacenamiento por plataforma con un solo método
(`driftDatabase(name:)`).

### 2.2 Decisiones donde el PRD quedó abierto

| # | Tema | Decisión | Justificación |
|---|---|---|---|
| D1 | State management | **Riverpod 3.3.2**, API de clases (`Notifier`, `StreamProvider`). Sin code generation | Cumple §31 (testeable, sin sobrearquitectura) y §35 (escalable). La codegen añade un paso de build sin valor aquí |
| D2 | Navegación | **go_router 17.0.1** con `StatefulShellRoute.indexedStack` | 2 tabs con estado preservado + rutas modales del formulario |
| D3 | Package ID Android | `com.pipefinanzas.app` | Reemplaza el placeholder `com.example.pipefinanzaspersonales` |
| D4 | Paleta | **PRD al pie de la letra**: Primary `#2563EB`, Background `#F8FAFC` | El logo es `#427BAA`; se acepta que la UI sea más saturada que el logo |
| D5 | Fondo del splash | `#F8FAFC` (PRD) | Consistencia con el resto de la app |
| D6 | Tipo del monto | `INTEGER` = pesos enteros, siempre positivo | COP no usa centavos en la práctica (§9 muestra `$25.000`). Evita errores de punto flotante. El signo lo determina `type`, nunca el monto (§7) |
| D7 | Balance | **Siempre calculado, nunca almacenado** | §7 y §13 lo exigen explícitamente |
| D8 | Formato de moneda | Clase `CurrencyFormatter` con `enum CurrencyCode` | §9: la lógica de negocio no debe quedar acoplada a COP |
| D9 | Icono de categoría | Se guarda una **clave de texto** (`'restaurant'`), nunca un codepoint de `IconData` | Un codepoint queda roto si Flutter cambia el set de iconos |
| D10 | Nombres de mes | Lista `const` en español, **no** `DateFormat` con locale | `intl` exige `initializeDateFormatting` para fechas no-sistema: un fallo de runtime fácil de no detectar. La app es solo en español |
| D11 | Cálculos | Funciones **puras** en domain, sin SQL de agregación | §32: "deben poder probarse independientemente de la interfaz". SQL agrega en C, no se puede testear igual |
| D12 | Filtro mensual | SQL filtra por rango de fechas; Dart agrega | Combina eficiencia (pocos rows) con testabilidad (cálculo puro en Dart) |
| D13 | Colisión de nombres Drift | Importar las entidades de dominio con prefijo en la capa `data` | Drift genera la clase `Category` para la tabla `Categories`, que choca con la entidad de dominio `Category`. Un `import ... as domain` lo resuelve sin renombrar nada |
| D14 | Tests de base de datos | Prioridad a tests **puros** (sin BD) + fakes del repositorio | `NativeDatabase.memory()` puede necesitar `sqlite3.dll` no disponible en `flutter test` en Windows. Ver la nota en S08 |

### 2.3 Conflictos ya resueltos

| Conflicto | Resolución |
|---|---|
| Logo `#427BAA` vs PRD `#2563EB` | Gana el PRD en la UI. El logo no se regenera |
| Splash crema `#E9E5DB` vs PRD `#F8FAFC` | Gana el PRD |
| `sqlite3_flutter_libs` EOL | Usar `drift_flutter` |
| `flutter_riverpod` / `go_router` / `build_runner` más recientes | Fijados a §2.1 |
| `lib/screens/` no existe en la estructura del PRD | Se elimina en S00 |

---

## 3. Arquitectura objetivo

```text
lib/
├── main.dart                          # Bootstrap: ProviderScope + PipeApp
├── app.dart                           # MaterialApp.router + tema
│
├── core/
│   ├── database/
│   │   ├── app_database.dart          # @DriftDatabase, conexión, migraciones, seed
│   │   ├── tables.dart                # Categories, Movements, MovementTypeConverter
│   │   ├── daos.dart                  # CategoriesDao, MovementsDao
│   │   ├── database_providers.dart    # appDatabaseProvider
│   │   └── seed/default_categories.dart
│   ├── providers/
│   │   └── repository_providers.dart   # movementRepositoryProvider, categoryRepositoryProvider
│   ├── router/
│   │   └── app_router.dart            # GoRouter + rutas
│   ├── theme/
│   │   ├── app_colors.dart            # Única fuente de color (§19)
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   ├── app_theme.dart             # ThemeData claro, preparado para dark
│   │   └── theme_extensions.dart      # ThemeExtension para income/expense
│   └── utils/
│       ├── currency_formatter.dart     # D8
│       ├── date_utils.dart             # D10
│       └── validators.dart             # §15, funciones puras
│
├── features/
│   ├── movements/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── movement_type.dart
│   │   │   │   ├── movement.dart
│   │   │   │   └── category.dart
│   │   │   ├── repositories/
│   │   │   │   └── movement_repository.dart
│   │   │   ├── financial_calculator.dart   # D11
│   │   │   └── financial_summary.dart
│   │   ├── data/
│   │   │   └── drift_movement_repository.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── movement_form_controller.dart
│   │       │   └── history_providers.dart
│   │       ├── screens/
│   │       │   ├── movement_form_screen.dart
│   │       │   └── history_screen.dart
│   │       └── widgets/
│   │           ├── movement_tile.dart
│   │           ├── amount_input_field.dart
│   │           ├── category_picker.dart
│   │           ├── movement_type_selector.dart
│   │           └── date_picker_field.dart
│   │
│   ├── categories/
│   │   ├── domain/
│   │   │   ├── entities/category.dart
│   │   │   └── repositories/category_repository.dart
│   │   ├── data/
│   │   │   └── drift_category_repository.dart
│   │   └── presentation/
│   │       ├── category_icon_registry.dart    # D9
│   │       ├── providers/category_providers.dart
│   │       └── widgets/category_icon.dart
│   │
│   └── dashboard/
│       ├── domain/monthly_summary.dart
│       ├── data/                            # vacío en el MVP: reutiliza movements
│       └── presentation/
│           ├── providers/dashboard_providers.dart
│           ├── screens/dashboard_screen.dart
│           └── widgets/
│               ├── month_selector.dart
│               ├── balance_card.dart
│               ├── totals_row.dart
│               ├── category_breakdown.dart
│               └── recent_movements.dart
│
└── shared/
    └── widgets/
        ├── app_scaffold.dart           # Scaffold + NavigationBar + FAB
        ├── empty_state.dart             # §14
        ├── confirm_dialog.dart          # §12
        └── feedback.dart                # §15 SnackBars
```

**Reglas de dependencia (inviolables, §27 y §37):**

```text
presentation  →  domain  →  (nada)
data          →  domain
core/theme    →  (nada)
core/utils    →  (nada, salvo domain)
```

- `presentation` **nunca** importa `drift` ni `sqlite3`.
- `domain` **nunca** importa `package:flutter/material.dart` ni `package:drift/drift.dart`.
- Ningún widget escribe un hex literal. Todo sale de `AppColors`, de
  `Theme.of(context)` o del `ThemeExtension` semántico.

---

## 4. Mapa de secuencias

| ID | Secuencia | Depende de | Estado |
|---|---|---|---|
| **S00** | [Cimientos: estructura, tema, navegación](#s00--ciimientos) | — | `[x]` |
| **S01** | [Base de datos Drift](#s01--base-de-datos-drift) | S00 | `[x]` |
| **S02** | [Dominio y cálculos financieros](#s02--dominio-y-cálculos) | S01 | `[x]` |
| **S03** | [Categorías](#s03--categorías) | S02 | `[ ]` |
| **S04** | [Registro de movimientos](#s04--registro-de-movimientos) | S03 | `[ ]` |
| **S05** | [Historial](#s05--historial) | S04 | `[ ]` |
| **S06** | [Dashboard y resumen mensual](#s06--dashboard-y-resumen-mensual) | S05 | `[ ]` |
| **S07** | [Estados vacíos y pulido](#s07--estados-vacíos-y-pulido) | S06 | `[ ]` |
| **S08** | [Testing](#s08--testing) | S07 | `[ ]` |
| **S09** | [Release Android](#s09--release-android) | S08 | `[ ]` |

```text
S00 ──► S01 ──► S02 ──► S03 ──► S04 ──► S05 ──► S06 ──► S07 ──► S08 ──► S09
```

---

<a id="s00--ciimientos"></a>

## S00 — Cimientos

**Objetivo:** estructura de carpetas, tema del PRD, `go_router` y build verde.
**Dejar para:** que S01 solo tenga que crear la capa de base de datos.

### Paso 1 — Dependencias

```bash
flutter pub add flutter_riverpod:^3.3.2 go_router:^17.0.1 drift:^2.34.0 drift_flutter:^0.3.1 intl:^0.20.3
flutter pub add --dev build_runner:^2.15.1 drift_dev:^2.34.0
flutter pub get
```

**Si la resolución falla, parar y reportar.** No subir versiones.

### Paso 2 — Estructura de carpetas

```bash
mkdir -p lib/core/database/seed \
         lib/core/providers \
         lib/core/router \
         lib/core/theme \
         lib/core/utils \
         lib/features/movements/domain/entities \
         lib/features/movements/domain/repositories \
         lib/features/movements/data \
         lib/features/movements/presentation/providers \
         lib/features/movements/presentation/screens \
         lib/features/movements/presentation/widgets \
         lib/features/categories/domain/entities \
         lib/features/categories/domain/repositories \
         lib/features/categories/data \
         lib/features/categories/presentation/providers \
         lib/features/categories/presentation/widgets \
         lib/features/dashboard/domain \
         lib/features/dashboard/presentation/providers \
         lib/features/dashboard/presentation/screens \
         lib/features/dashboard/presentation/widgets \
         lib/shared/widgets
rm -f lib/main.dart.bak
```

`mkdir -p` no falla si el directorio ya existe: es seguro reejecutarlo.

### Paso 3 — Eliminar el código de demo

Borrar `lib/screens/splash_screen.dart` y reescribir `lib/main.dart`.
El splash **no** se pierde: se reimplementa en `shared/widgets/app_splash.dart`
dentro de la arquitectura del PRD (§26 lista `shared/`).

### Paso 4 — `core/theme/app_colors.dart`

Fuente única de color (§19). **Todos** los valores vienen del PRD.

```dart
import 'package:flutter/material.dart';

/// §19 — Única fuente de verdad del color. Ningún otro archivo
/// define colores ni hex literales.
abstract final class AppColors {
  // Marca
  static const brandBlue = Color(0xFF2563EB);
  static const brandNavy = Color(0xFF1E3A5F);
  static const brandLight = Color(0xFFDBEAFE);

  // Superficies
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F5F9);

  // Texto
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Semánticos
  static const income = Color(0xFF16A34A);
  static const expense = Color(0xFFDC2626);
  static const warning = Color(0xFFF59E0B);

  // Bordes
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFCBD5E1);
}
```

### Paso 5 — `core/theme/theme_extensions.dart`

§21: verde = ingresos, rojo = gastos. Va en un `ThemeExtension` para que ningún
widget importe `AppColors` directamente.

```dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  const SemanticColors({
    required this.income,
    required this.expense,
    required this.warning,
    required this.surfaceVariant,
  });

  final Color income;
  final Color expense;
  final Color warning;
  final Color surfaceVariant;

  static const light = SemanticColors(
    income: AppColors.income,
    expense: AppColors.expense,
    warning: AppColors.warning,
    surfaceVariant: AppColors.surfaceVariant,
  );

  @override
  SemanticColors copyWith({
    Color? income,
    Color? expense,
    Color? warning,
    Color? surfaceVariant,
  }) {
    return SemanticColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
    );
  }

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
    );
  }
}

extension SemanticColorsX on BuildContext {
  SemanticColors get semantic => Theme.of(this).extension<SemanticColors>()!;
}
```

### Paso 6 — `core/theme/app_typography.dart`, `app_spacing.dart`, `app_theme.dart`

```dart
// app_typography.dart
import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const display = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w700, height: 1.2, letterSpacing: -0.5,
  );
  static const title = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w600, height: 1.3,
  );
  static const body = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static const bodyStrong = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5);
  static const label = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4);
  static const caption = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);
}
```

```dart
// app_spacing.dart
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;

  static const radiusSm = 8.0;
  static const radiusMd = 12.0;
  static const radiusLg = 16.0;

  static const minTouchTarget = 48.0; // §35
}
```

```dart
// app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'theme_extensions.dart';

abstract final class AppTheme {
  /// §33 — Solo se implementa el tema claro. Los tokens quedan
  /// centralizados para poder añadir dark sin reescribir widgets.
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandBlue,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.brandBlue,
        onPrimary: AppColors.textOnPrimary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.expense,
        outlineVariant: AppColors.border,
      ),
      scaffoldBackgroundColor: AppColors.background,
    );

    return base.copyWith(
      extensions: const [SemanticColors.light],
      textTheme: base.textTheme.copyWith(
        headlineLarge: AppTypography.display,
        titleLarge: AppTypography.title,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.label,
        labelSmall: AppTypography.caption,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
          borderSide: BorderSide(color: AppColors.brandBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
          borderSide: BorderSide(color: AppColors.expense),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
          borderSide: BorderSide(color: AppColors.expense, width: 2),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.brandLight,
        elevation: 0,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brandBlue,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52), // §35: objetivo táctil ≥48
          backgroundColor: AppColors.brandBlue,
          foregroundColor: AppColors.textOnPrimary,
          textStyle: AppTypography.bodyStrong,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSm)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandBlue,
          textStyle: AppTypography.label,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusMd)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: TextStyle(color: AppColors.textOnPrimary),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.divider, thickness: 1),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textSecondary,
        contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }
}
```

### Paso 7 — `core/utils/date_utils.dart` (D10)

```dart
import 'package:flutter/material.dart';

const _kMonthNames = <String>[
  'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
  'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
];

const _kWeekdayNames = <String>[
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
];

/// D10 — Sin `intl` para nombres: lista constante, sin locale, sin init.
abstract final class AppDateUtils {
  static String monthName(int month) => _kMonthNames[month - 1];

  static String weekdayName(int weekday) => _kWeekdayNames[weekday - 1];

  /// §12 — "13 ene 2026" / "13 ene 2026, 14:30"
  static String formatShort(DateTime date) =>
      '${date.day} ${_kShortMonths[date.month - 1]} ${date.year}';

  static String formatShortWithTime(DateTime date) =>
      '${formatShort(date)}, ${_two(date.hour)}:${_two(date.minute)}';

  /// Etiqueta de mes para el selector: "Enero 2026"
  static String formatMonth(DateTime date) => '${monthName(date.month)} ${date.year}';

  /// Etiqueta de mes relativo cuando aplica.
  static String formatMonthRelative(DateTime date, DateTime now) {
    if (date.year == now.year && date.month == now.month) return 'Este mes';
    final prev = DateTime(now.year, now.month - 1);
    if (date.year == prev.year && date.month == prev.month) return 'Mes anterior';
    return formatMonth(date);
  }

  /// Rango inclusivo [start, end) del mes — el último día a medianoche del
  /// mes siguiente. Comparable, seguro para índices.
  static DateTimeRange monthRange(DateTime date) => DateTimeRange(
        start: DateTime(date.year, date.month),
        end: DateTime(date.year, date.month + 1),
      );

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _two(int v) => v.toString().padLeft(2, '0');
}

const _kShortMonths = <String>[
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];
```

### Paso 8 — `core/router/app_router.dart` (D2)

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Rutas centralizadas (§27). Nunca escribir literales de ruta en un widget.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const dashboard = '/';
  static const history = '/historial';
  static const newMovement = '/movimiento/nuevo';
  static const editMovement = '/movimiento/editar';
  static const movementById = '/movimiento/:id';

  static String editMovementPath(String id) => '/movimiento/editar/$id';
}

/// `param` llega como String en go_router 17; `pathParameters` es el acceso tipado.
String? movementIdFrom(GoRouterState state) => state.pathParameters['id'];
```

`app.dart` monta el `GoRouter` con `StatefulShellRoute` de 2 branches y el
formulario como ruta modal **fuera** del shell (con su propio
`parentNavigatorKey`), para que al guardar se superponga al shell y no deje
pestañas desincronizadas:

```dart
// app.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/router_provider.dart';
import 'core/theme/app_theme.dart';

class PipeApp extends ConsumerWidget {
  const PipeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Pipe Finanzas',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
```

```dart
// core/providers/router_provider.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../router/app_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// D2 — S00 registra las pantallas con placeholders. S04–S06 las sustituyen
/// por las implementaciones reales sin cambiar la forma del router.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SplashPlaceholder(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              builder: (context, state) => const DashboardPlaceholder(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.history,
              builder: (context, state) => const HistoryPlaceholder(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: AppRoutes.newMovement,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: MovementFormPlaceholder(),
        ),
      ),
      GoRoute(
        path: AppRoutes.movementById,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = movementIdFrom(state);
          return MaterialPage(
            fullscreenDialog: true,
            child: MovementFormPlaceholder(id: id),
          );
        },
      ),
    ],
  );
});
```

En S00 los `*Placeholder` son `Scaffold` con el texto del nombre de la pantalla.
**Se sustituyen en S04/S05/S06.** El router no se vuelve a tocar.

### Paso 9 — `shared/widgets/app_splash.dart`

Reimplementa el splash con los tokens del PRD (D5). El splash **no** depende de
la base de datos: por eso va en `shared/`, no en `features/`.

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';

/// Splash del PRD. Muestra el logo y navega a la primera pantalla.
class AppSplash extends StatefulWidget {
  const AppSplash({super.key});

  @override
  State<AppSplash> createState() => _AppSplashState();
}

class _AppSplashState extends State<AppSplash> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      context.go(AppRoutes.dashboard);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // D5
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo_mark.png', height: 96),
            const SizedBox(height: 24),
            const Text(
              'Pipe Finanzas',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.brandNavy,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Paso 10 — `main.dart` y `shared/widgets/app_scaffold.dart`

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // §16 — portrait only
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const ProviderScope(child: PipeApp()));
}
```

`AppScaffold` es el único lugar que dibuja la `NavigationBar` y el FAB (§12):

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// §12 — Scaffold con NavigationBar de 2 destinos y FAB central.
class AppScaffold extends StatelessWidget {
  const AppScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.newMovement),
        tooltip: 'Nuevo movimiento',
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}
```

### Comandos de aceptación S00

```bash
flutter analyze
flutter build apk --debug
flutter run
```

**Debe cumplirse:**
- [ ] `flutter analyze` → `No issues found!`
- [ ] `flutter build apk --debug` → APK generado
- [ ] La app arranca, muestra el splash con fondo `#F8FAFC` y el logo
- [ ] `/` y `/historial` muestran su placeholder
- [ ] El FAB abre `/movimiento/nuevo` a pantalla completa
- [ ] La `NavigationBar` cambia de rama y **preserva el scroll** al volver
- [ ] `pubspec.yaml` tiene las versiones exactas de §2.1

**Checkpoint:**
```bash
git add -A
git commit -m "S00: estructura, tema PRD, go_router y build verde"
```

### Desviaciones registradas en S00

| Tema | El plan decía | Se hizo | Por qué |
|---|---|---|---|
| Placeholders | `SplashPlaceholder` en el router | `AppSplash` real desde el router | El splash es parte del entregable de marca. Se implementó ya y `SplashPlaceholder` se eliminó. |
| `router_provider.dart` | Routeas en `core/router/app_router.dart` | Provider en `core/providers/router_provider.dart`; `app_router.dart` queda solo con `AppRoutes` y `movementIdFrom` | Un provider no pertenece a la capa de rutas. Además evita el import circular entre router y app.dart |
| Placeholders | Un solo archivo de screens | `core/router/placeholder_screens.dart` | Agrupar los 4 placeholders deja obvio qué falta reemplazar |
| `pubspec.yaml` | `^3.3.2` etc. | `flutter pub add` escribió pines exactos; ajustados a `^` | Pub resolverá el SDK igual, pero el caret documenta la intención del plan |
| Test de arranque | No especificado | `test/widget_test.dart` con 3 smoke tests de navegación | El `widget_test.dart` de `flutter create` probaba el contador de demo, que ya no existe |

---

<a id="s01--base-de-datos-drift"></a>

## S01 — Base de datos Drift

**Objetivo:** esquema, DAOs, repositorios, seed y migraciones.
**Dejar para:** S02, que solo escriba entidades de dominio y cálculos sobre una
base ya funcionando.

### Paso 1 — Tablas (`core/database/tables.dart`)

```dart
import 'package:drift/drift.dart';
import '../../features/movements/domain/entities/movement_type.dart';

/// §28 — Categories. 14 filas de solo lectura (S03 no las borra).
@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get iconKey => text().withLength(min: 1, max: 40)();
  IntColumn get colorValue => integer()();
  IntColumn get type => intEnum<MovementType>()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// §28 — Movements. `amount` en COP enteros y SIEMPRE positivo (D6);
/// el signo lo determina `type` (§7).
@DataClassName('MovementRow')
class Movements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get amount => integer()();
  IntColumn get type => intEnum<MovementType>()();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get date => dateTime()();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// Límites de negocio aplicados en la capa de dominio (§15), no aquí:
/// SQLite no soporta CHECK de forma portable a través de Drift.
class TableIndexes {
  /// Consulta mensual del dashboard y del filtro del historial.
  static const byDate = 'CREATE INDEX IF NOT EXISTS idx_movements_date '
      'ON movements (date DESC)';
  static const byCategory = 'CREATE INDEX IF NOT EXISTS idx_movements_category '
      'ON movements (category_id)';
}
```

**Sobre D13 (colisión de nombres):** los `@DataClassName` generating `CategoryRow` y
`MovementRow` evitan el choque con las entidades de dominio `Category` y
`Movement`. Aun así, en los DAOs se importa el dominio con prefijo `domain:` para
que quede inequívoco cuál es cuál.

### Paso 2 — Seed (`core/database/seed/default_categories.dart`)

14 categorías: 10 de gasto, 4 de ingreso. Los valores de `colorValue` son ARGB de
`AppColors`; los `iconKey` son claves del registro de iconos (D9).

```dart
import '../../../../features/movements/domain/entities/movement_type.dart';

/// §30 — Catálogo inicial. Semilla idempotente: se aplica una sola vez.
const defaultCategories = <DefaultCategory>[
  // ── Gastos (10) ────────────────────────────────────────────
  DefaultCategory('Alimentación', 'restaurant', 0xFFF97316, MovementType.expense, 1),
  DefaultCategory('Transporte', 'directions_bus', 0xFF0EA5E9, MovementType.expense, 2),
  DefaultCategory('Vivienda', 'home', 0xFF8B5CF6, MovementType.expense, 3),
  DefaultCategory('Servicios', 'bolt', 0xFFEAB308, MovementType.expense, 4),
  DefaultCategory('Salud', 'favorite', 0xFFEF4444, MovementType.expense, 5),
  DefaultCategory('Entretenimiento', 'movie', 0xFFEC4899, MovementType.expense, 6),
  DefaultCategory('Educación', 'school', 0xFF6366F1, MovementType.expense, 7),
  DefaultCategory('Ropa', 'shopping_bag', 0xFF14B8A6, MovementType.expense, 8),
  DefaultCategory('Tecnología', 'devices', 0xFF3B82F6, MovementType.expense, 9),
  DefaultCategory('Otros', 'more_horiz', 0xFF64748B, MovementType.expense, 10),
  // ── Ingresos (4) ───────────────────────────────────────────
  DefaultCategory('Salario', 'work', 0xFF16A34A, MovementType.income, 11),
  DefaultCategory('Freelance', 'laptop_mac', 0xFF22C55E, MovementType.income, 12),
  DefaultCategory('Inversiones', 'trending_up', 0xFF10B981, MovementType.income, 13),
  DefaultCategory('Otros ingresos', 'savings', 0xFF059669, MovementType.income, 14),
];

class DefaultCategory {
  const DefaultCategory(this.name, this.iconKey, this.colorValue, this.type, this.sortOrder);
  final String name;
  final String iconKey;
  final int colorValue;
  final MovementType type;
  final int sortOrder;
}
```

### Paso 3 — Conexión (`core/database/app_database.dart`)

```dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';

import 'daos.dart';
import 'seed/default_categories.dart';
import 'tables.dart';

part 'app_database.g.dart';

/// §36 — 100% local. Sin red, sin permisos, sin telemetría.
@DriftDatabase(tables: [Categories, Movements], daos: [CategoriesDao, MovementsDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Solo para tests (§33). Ver la nota de plataforma de S08.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        beforeOpen: (details) async {
          // `PRAGMA foreign_keys` debe ir en `beforeOpen`, no solo en `onCreate`:
          // es la única forma de que aplique a la conexión ya abierta.
          await customStatement('PRAGMA foreign_keys = ON');
          if (details.wasCreated) await _seedCategories();
        },
      );

  Future<void> _createIndexes() async {
    for (final sql in [TableIndexes.byDate, TableIndexes.byCategory]) {
      await customStatement(sql);
    }
  }

  /// Idempotente: si ya hay filas, no hace nada.
  Future<void> _seedCategories() async {
    final existing = await (select(categories)..limit(1)).get();
    if (existing.isNotEmpty) return;

    await batch((b) {
      b.insertAll(categories, defaultCategories
          .map((c) => CategoriesCompanion.insert(
                name: c.name,
                iconKey: c.iconKey,
                colorValue: c.colorValue,
                type: c.type,
                sortOrder: Value(c.sortOrder),
                isDefault: const Value(true),
              ))
          .toList());
    });
  }

  @override
  int get schemaVersion => 1;
}

/// Conexión real (§36). `drift_flutter` resuelve la ruta por plataforma,
/// incluido `path_provider`; no hace falta construir la ruta a mano.
QueryExecutor _openConnection() => driftDatabase(name: 'pipe_finanzas');
```

** Notas de implementación de `app_database.dart`:**

- Imports: `package:drift/drift.dart`, `package:drift_flutter/drift_flutter.dart`.
- No usar `NativeDatabase.createInBackground(File(...))` salvo que se quiera
  control explícito de la ruta; en ese caso sí hacen falta `package:path` y
  `package:path_provider`.
- Para tests: `AppDatabase.forTesting(NativeDatabase.memory())` — ver S08.
- `dart:io` y `package:flutter/foundation.dart` **no** hacen falta en este
  archivo con esta implementación. No importarlos.

### Paso 4 — DAOs (`core/database/daos.dart`)

```dart
import 'package:drift/drift.dart';

import '../../features/movements/domain/entities/category.dart' as domain;
import '../../features/movements/domain/entities/movement.dart' as domain;
import '../../features/movements/domain/entities/movement_type.dart';
import 'tables.dart';

part 'daos.g.dart';

@DriftAccessor(tables: [Categories])
class CategoriesDao extends DatabaseAccessor<AppDatabase> with _$CategoriesDaoMixin {
  CategoriesDao(super.db);

  /// S03 — Solo lectura: el catálogo es fijo en el MVP (§10).
  Future<List<domain.Category>> getAll() async {
    final rows = await (db.select(db.categories)
          ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
        .get();
    return rows.map(_toEntity).toList();
  }

  Stream<List<domain.Category>> watchAll() {
    return (db.select(db.categories)
          ..orderBy([(c) => OrderingTerm(expression: c.sortOrder)]))
        .watch()
        .map(_toEntity);
  }

  Future<domain.Category?> getById(int id) async {
    final row = await (db.select(db.categories)..where((c) => c.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toEntity(row);
  }

  domain.Category _toEntity(CategoryRow row) => domain.Category(
        id: row.id,
        name: row.name,
        iconKey: row.iconKey,
        colorValue: row.colorValue,
        type: row.type,
        isDefault: row.isDefault,
        sortOrder: row.sortOrder,
      );
}

@DriftAccessor(tables: [Movements, Categories])
class MovementsDao extends DatabaseAccessor<AppDatabase> with _$MovementsDaoMixin {
  MovementsDao(super.db);

  /// Con JOIN para traer la categoría sin N+1. Se proyecta a un mapa y luego
  /// se convierte: el `map` es síncrono, el JOIN ya está resuelto por Drift.
  Stream<List<domain.Movement>> watchAll() {
    final query = db.select(db.movements).join([
      innerJoin(db.categories, db.categories.id.equalsExp(db.movements.categoryId)),
    ])
      ..orderBy([OrderingTerm.desc(db.movements.date)]);

    return query.watch().map(_toEntities);
  }

  Stream<List<domain.Movement>> watchByMonth(DateTime month) {
    final range = _monthRange(month);
    final query = db.select(db.movements).join([
      innerJoin(db.categories, db.categories.id.equalsExp(db.movements.categoryId)),
    ])
      ..where(db.movements.date.isBiggerOrEqualValue(range.start)
          & db.movements.date.isSmallerThanValue(range.end))
      ..orderBy([OrderingTerm.desc(db.movements.date)]);

    return query.watch().map(_toEntities);
  }

  Future<List<domain.Movement>> getByMonth(DateTime month) async {
    final range = _monthRange(month);
    final query = db.select(db.movements).join([
      innerJoin(db.categories, db.categories.id.equalsExp(db.movements.categoryId)),
    ])
      ..where(db.movements.date.isBiggerOrEqualValue(range.start)
          & db.movements.date.isSmallerThanValue(range.end))
      ..orderBy([OrderingTerm.desc(db.movements.date)]);
    return _toEntities(await query.get());
  }

  Future<domain.Movement?> getById(int id) async {
    final query = db.select(db.movements).join([
      innerJoin(db.categories, db.categories.id.equalsExp(db.movements.categoryId)),
    ])..where(db.movements.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _toEntity(row.readTable(db.movements), row.readTable(db.categories));
  }

  Future<int> insertMovement(MovementsCompanion entry) =>
      db.into(db.movements).insert(entry);

  Future<bool> updateMovementById(int id, MovementsCompanion entry) =>
      db.update(db.movements).replace(entry.copyWith(
            id: Value(id),
            updatedAt: Value(DateTime.now()),
          ));

  Future<int> deleteById(int id) =>
      (db.delete(db.movements)..where((m) => m.id.equals(id))).go();

  List<domain.Movement> _toEntities(List<TypedResult> rows) => rows
      .map((r) => _toEntity(r.readTable(db.movements), r.readTable(db.categories)))
      .toList();

  domain.Movement _toEntity(MovementRow m, CategoryRow c) => domain.Movement(
        id: m.id,
        amount: m.amount,
        type: m.type,
        category: domain.Category(
          id: c.id,
          name: c.name,
          iconKey: c.iconKey,
          colorValue: c.colorValue,
          type: c.type,
          isDefault: c.isDefault,
          sortOrder: c.sortOrder,
        ),
        date: m.date,
        description: m.description,
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
      );

  static DateTimeRange _monthRange(DateTime d) => DateTimeRange(
        start: DateTime(d.year, d.month),
        end: DateTime(d.year, d.month + 1),
      );
}
```

> **Nota sobre `db.categories.id.equalsExp(...)`:** en Drift el `JOIN` se escribe
> así. Verificar la firma exacta en la versión instalada; si `equalsExp` no aplica
> sobre la columna referenciada, usar `db.movements.categoryId.equalsExp(db.categories.id)`.
> Es el único punto del plan con API que conviene confirmar contra el paquete
> instalado en el momento de escribirlo.

### Paso 5 — Repositorios (dominio ↔ Drift)

```dart
// features/movements/data/drift_movement_repository.dart
import '../../../core/database/daos.dart';
import '../domain/entities/category.dart';
import '../domain/entities/movement.dart';
import '../domain/entities/movement_type.dart';
import '../domain/repositories/movement_repository.dart';

class DriftMovementRepository implements MovementRepository {
  DriftMovementRepository(this._dao);
  final MovementsDao _dao;

  @override
  Stream<List<Movement>> watchAll() => _dao.watchAll();

  @override
  Stream<List<Movement>> watchByMonth(DateTime month) => _dao.watchByMonth(month);

  @override
  Future<List<Movement>> getByMonth(DateTime month) => _dao.getByMonth(month);

  @override
  Future<Movement?> getById(int id) => _dao.getById(id);

  @override
  Future<int> create(MovementDraft draft) => _dao.insertMovement(
        MovementsCompanion.insert(
          amount: draft.amount,
          type: draft.type,
          categoryId: draft.categoryId,
          date: draft.date,
          description: Value(draft.description),
        ),
      );

  @override
  Future<bool> update(int id, MovementDraft draft) => _dao.updateMovementById(
        id,
        MovementsCompanion.insert(
          amount: draft.amount,
          type: draft.type,
          categoryId: draft.categoryId,
          date: draft.date,
          description: Value(draft.description),
        ),
      );

  @override
  Future<void> delete(int id) async => _dao.deleteById(id);
}
```

`MovementDraft` (en `domain/repositories/movement_repository.dart`) es el tipo de
entrada: un `Movement` recién creado todavía no tiene `id`. Esto evita que la
capa de presentación construya `Companion` (que es de Drift).

### Paso 6 — Providers

```dart
// core/database/database_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

/// `keepAlive: false` implícito: se cierra al destruirse el ProviderScope.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
```

### Comandos de aceptación S01

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

**Debe cumplirse:**
- [ ] `app_database.g.dart` y `daos.g.dart` se generan sin error
- [ ] `flutter analyze` → `No issues found!`
- [ ] La app arranca sin excepción
- [ ] El archivo `pipe_finanzas.sqlite` aparece en el directorio de la app
- [ ] Reabrir la app **no duplica** las 14 categorías (idempotencia de la semilla)
- [ ] `MovementRow` y `CategoryRow` son las únicas clases de fila en el código

**Checkpoint:**
```bash
git add -A
git commit -m "S01: esquema Drift, DAOs, repositorios y seed de 14 categorías"
```

### Desviaciones registradas en S01

Ocho diferencias respecto al plan. Las tres primeras resuelven las dudas que
§6.1 había marcado como "verificar contra el paquete instalado"; las siguientes
las detectaron los tests.

| Tema | El plan decía | Se hizo | Por qué |
|---|---|---|---|
| **`equalsExp` (duda de §6.1)** | "verificar la firma exacta" | `categories.id.equalsExp(movements.categoryId)` | Confirmado: el lado izquierdo es la columna de la tabla del `innerJoin`, el derecho la expresión foránea. Tal cual estaba escrito. |
| **Tipo del JOIN (duda de §6.1)** | "verificar" | `JoinedSelectStatement<HasResultSet, dynamic> _joined()` | Drift declara `join()` devolviendo `JoinedSelectStatement` **sin argumentos**; Dart rellena los bounds. El segundo parámetro queda en `dynamic` y el resultado se lee como `TypedResult`. Anotarlo `SimpleSelectStatement<...>` es incorrecto: esa clase expone `Selectable<MovementRow>` y no tiene `readTable`. |
| **Actualización (duda implícita)** | `replace` | `write` | `replace` reescribe **todas** las columnas. Como el companion no lleva `createdAt`, la base le ponía una marca de tiempo nueva en **cada edición**. `write` solo toca las columnas presentes. Lo detectó el test de `createdAt`. |
| **Granularidad de `DateTime`** | No considerada | Documentada en `tables.dart` | Drift serializa `DateTime` como unix en **segundos**. Dos ediciones en el mismo segundo dan el mismo `updatedAt`. No afecta al usuario (la UI del MVP no muestra esos campos) y hay un test que fija el límite. |
| **`attachedDatabase`** | `=> (db as AppDatabase)` | No se overridea | En Drift 2.34 `attachedDatabase` es un campo `final` que asigna el constructor, y `db` es una extensión que devuelve `attachedDatabase`. Overriding con `db` causa **recursión infinita**. Las tablas se acceden con los getters `categories` / `movements` del mixin generado. |
| **Orden de las entidades** | Entidades en S02 | `movement_type.dart`, `category.dart`, `movement.dart` en S01 | Los DAOs mapean a entidades de dominio: S01 no compila sin ellas. |
| **Contratos de repositorio** | `movement_repository.dart` en S02 | En S01 | Las implementaciones de `data` los necesitan para compilar. A S02 solo quedan calculadora, validadores y formateador. |
| **Comando de build_runner** | `--delete-conflicting-outputs` | `dart run build_runner build` | La flag se eliminó en build_runner 2.15.1. |

**Dos detalles de imports que suelen morder:**

- Un test que importa `package:drift/drift.dart` choca con `matcher`:
  `isNull` e `isNotNull` existen en ambos. Resolver con
  `import 'package:drift/drift.dart' hide isNull, isNotNull;`.
- `MovementsCompanion` y `CategoryRow` se generan como `part` de
  `app_database.dart`, no de `tables.dart`. Quien los necesite debe importar
  `app_database.dart`.

**Prueba añadida en S01:** `test/database/app_database_test.dart`, 18 tests que
cubren semilla (14 filas, orden, idempotencia), JOIN sin N+1 ni duplicados,
rango de mes `[start, end)`, normalización del draft, update, delete y
integridad referencial. **`NativeDatabase.memory()` sí funciona en este
entorno**, así que el nivel 2 de S08 queda confirmado.

---

<a id="s02--dominio-y-cálculos"></a>

## S02 — Dominio y cálculos financieros

**Objetivo:** entidades puras, validaciones y la aritmética de §32.
**Dejar para:** S03, que solo necesita las entidades y el DAO de categorías.

Este es el núcleo del MVP. **Aquí no hay UI, ni Drift, ni `package:flutter`.**
Todo es `dart test`-able al instante.

### Paso 1 — `movement_type.dart`

```dart
/// §7 — El tipo determina el signo del monto. El monto siempre es positivo (D6).
enum MovementType {
  income,
  expense;

  bool get isIncome => this == MovementType.income;
  bool get isExpense => this == MovementType.expense;

  /// Signo que este tipo aporta al balance (§32).
  int get sign => isIncome ? 1 : -1;

  String get label => switch (this) {
        MovementType.income => 'Ingreso',
        MovementType.expense => 'Gasto',
      };

  static MovementType fromName(String value) => MovementType.values.firstWhere(
        (t) => t.name == value,
        orElse: () => MovementType.expense,
      );
}
```

### Paso 2 — `category.dart`

```dart
import 'movement_type.dart';

/// §28 — Categoría del catálogo. `iconKey` es una clave de texto, nunca un
/// codepoint (D9). `colorValue` es un ARGB entero.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.type,
    required this.isDefault,
    required this.sortOrder,
  });

  final int id;
  final String name;
  final String iconKey;
  final int colorValue;
  final MovementType type;
  final bool isDefault;
  final int sortOrder;
}
```

### Paso 3 — `movement.dart`

```dart
import 'category.dart';
import 'movement_type.dart';

/// §28 — Movimiento. `amount` en COP enteros y siempre positivo (D6).
/// `id` es 0 mientras el movimiento no ha sido persistido.
class Movement {
  const Movement({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int amount;
  final MovementType type;
  final Category category;
  final DateTime date;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isIncome => type.isIncome;

  /// Monto con signo, para sumas. Es la única fuente de la verdad del signo (§7).
  int get signedAmount => type.sign * amount;

  /// Copia inmutable con los campos de negocio actualizados. El `id` no cambia.
  Movement copyWith({
    int? amount,
    MovementType? type,
    Category? category,
    DateTime? date,
    String? description,
    DateTime? updatedAt,
  }) {
    return Movement(
      id: id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      description: description ?? this.description,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Movement && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
```

### Paso 4 — Contrato del repositorio

```dart
import '../entities/movement.dart';

/// Datos de entrada para crear o editar. Sin `id`: es un movimiento nuevo.
class MovementDraft {
  const MovementDraft({
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    required this.description,
  });

  final int amount;      // entero positivo (D6)
  final MovementType type;
  final int categoryId;
  final DateTime date;
  final String description;

  /// §15 — El borrador normaliza antes de persistir: monto absoluto, descripción
  /// recortada y fecha a medianoche local.
  MovementDraft normalized() => MovementDraft(
        amount: amount.abs(),
        type: type,
        categoryId: categoryId,
        date: DateTime(date.year, date.month, date.day),
        description: description.trim(),
      );
}

/// Contrato del repositorio. La capa `data` lo implementa; `presentation`
/// depende solo de esta interfaz (§27).
abstract interface class MovementRepository {
  Stream<List<Movement>> watchAll();
  Stream<List<Movement>> watchByMonth(DateTime month);
  Future<List<Movement>> getByMonth(DateTime month);
  Future<Movement?> getById(int id);
  Future<int> create(MovementDraft draft);
  Future<bool> update(int id, MovementDraft draft);
  Future<void> delete(int id);
}
```

### Paso 5 — `core/utils/currency_formatter.dart` (D8)

```dart
import 'package:intl/intl.dart';

/// D8 — Enum para desacoplar la lógica de negocio de COP.
/// El dominio nunca formatea moneda; solo la capa de presentación.
enum CurrencyCode { cop, usd, mxn }

/// §9 — "25.000" sin decimales; con decimales: "25.000,50".
class CurrencyFormatter {
  const CurrencyFormatter(this.code, {this.locale = 'es_CO'});

  final CurrencyCode code;
  final String locale;

  String get symbol => switch (code) {
        CurrencyCode.cop => r'$',
        CurrencyCode.usd => r'$',
        CurrencyCode.mxn => r'$',
      };

  static const _noDecimals = <CurrencyCode>{CurrencyCode.cop};

  /// Formatea un monto ya en la unidad mínima de la moneda.
  /// Para COP, la unidad mínima es el peso: no se divide.
  String format(int amount) {
    final decimals = _noDecimals.contains(code) ? 0 : 2;
    final f = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: decimals,
    );
    final absolute = amount.abs();
    final sign = amount < 0 ? '-' : '';
    return '$sign$symbol${f.format(absolute)}';
  }

  /// Con signo explícito para el balance del dashboard (§13).
  String formatSigned(int amount) =>
      amount < 0 ? '-${format(amount.abs())}' : '+${format(amount)}';
}
```

**Por qué sí usar `intl` aquí y no en las fechas:** `NumberFormat.decimalPattern`
no necesita `initializeDateFormatting`; los patrones numéricos vienen con el
locale por defecto. El problema de runtime solo aparece con `DateFormat`, y por
eso D10 lo evita.

### Paso 6 — `core/utils/validators.dart` (§15)

Funciones puras y sin Flutter: son el objetivo de los tests de S08.

```dart
class ValidationResult {
  const ValidationResult.ok() : error = null;
  const ValidationResult.invalid(this.error);

  final String? error;
  bool get isValid => error == null;
}

/// §15 — Monto: entero > 0, sin decimales (D6), sin signo.
ValidationResult validateAmount(String? raw) {
  final text = (raw ?? '').trim();
  if (text.isEmpty) return const ValidationResult.invalid('Ingresa un monto');
  if (text.contains(',') || text.contains('.')) {
    return const ValidationResult.invalid('Ingresa un monto sin decimales');
  }
  final value = int.tryParse(text.replaceAll(RegExp(r'[^\d]'), ''));
  if (value == null || value <= 0) {
    return const ValidationResult.invalid('El monto debe ser mayor a cero');
  }
  if (value > 999999999999) {
    return const ValidationResult.invalid('El monto es demasiado grande');
  }
  return const ValidationResult.ok();
}

/// §15 — Descripción: opcional, máximo 100 caracteres.
ValidationResult validateDescription(String? raw) {
  final text = (raw ?? '').trim();
  if (text.length > 100) {
    return const ValidationResult.invalid('Máximo 100 caracteres');
  }
  return const ValidationResult.ok();
}

/// §15 — No se permiten fechas futuras.
ValidationResult validateDate(DateTime? date, {DateTime? now}) {
  if (date == null) return const ValidationResult.invalid('Selecciona una fecha');
  final today = now ?? DateTime.now();
  final todayAtMidnight = DateTime(today.year, today.month, today.day);
  final selected = DateTime(date.year, date.month, date.day);
  if (selected.isAfter(todayAtMidnight)) {
    return const ValidationResult.invalid('La fecha no puede ser futura');
  }
  return const ValidationResult.ok();
}

/// Combina los tres. La categoría se valida aparte porque requiere async.
ValidationResult validateMovement({
  required String amount,
  required String description,
  required DateTime? date,
  int? categoryId,
}) {
  final a = validateAmount(amount);
  if (!a.isValid) return a;
  final d = validateDescription(description);
  if (!d.isValid) return d;
  final dt = validateDate(date);
  if (!dt.isValid) return dt;
  if (categoryId == null) {
    return const ValidationResult.invalid('Selecciona una categoría');
  }
  return const ValidationResult.ok();
}
```

### Paso 7 — `financial_calculator.dart` (D11)

El corazón del MVP. Funciones puras: sin Drift, sin Flutter, sin `BuildContext`.

```dart
import 'entities/movement.dart';
import 'financial_summary.dart';

/// §32 — Todos los cálculos del MVP. Funciones puras: entrada → salida,
/// sin estado y sin dependencias externas.
abstract final class FinancialCalculator {
  /// §32 — Total de ingresos del período.
  static int totalIncome(Iterable<Movement> movements) => movements
      .where((m) => m.isIncome)
      .fold(0, (sum, m) => sum + m.amount);

  /// §32 — Total de gastos del período.
  static int totalExpense(Iterable<Movement> movements) => movements
      .where((m) => m.type.isExpense)
      .fold(0, (sum, m) => sum + m.amount);

  /// §13 — Ingresos − gastos. Se calcula, nunca se almacena (D7).
  static int balance(Iterable<Movement> movements) {
    var result = 0;
    for (final m in movements) {
      result += m.signedAmount;
    }
    return result;
  }

  /// §13 — Porcentaje de gasto de cada categoría dentro del total de gastos.
  /// Devuelve [] si no hay gastos: evita división por cero.
  /// Los porcentajes están redondeados a 1 decimal y suman ~100.
  static List<CategoryBreakdown> breakdownByCategory(Iterable<Movement> movements) {
    final expenses = movements.where((m) => m.type.isExpense).toList();
    if (expenses.isEmpty) return const [];

    final total = expenses.fold(0, (sum, m) => sum + m.amount);
    final byCategory = <int, ({int amount, String name, int color, String iconKey})>{};

    for (final m in expenses) {
      final prev = byCategory[m.category.id];
      byCategory[m.category.id] = (
        amount: (prev?.amount ?? 0) + m.amount,
        name: m.category.name,
        color: m.category.colorValue,
        iconKey: m.category.iconKey,
      );
    }

    final result = byCategory.entries
        .map((e) => CategoryBreakdown(
              categoryId: e.key,
              categoryName: e.value.name,
              colorValue: e.value.color,
              iconKey: e.value.iconKey,
              amount: e.value.amount,
              percentage: (e.value.amount * 100 / total * 10).round() / 10,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return result;
  }

  /// §13 — Tasa de ahorro: (ingresos − gastos) / ingresos × 100.
  /// 0 si no hay ingresos.
  static double savingsRate(Iterable<Movement> movements) {
    final income = totalIncome(movements);
    if (income == 0) return 0;
    final result = (balance(movements) * 100 / income);
    return (result * 10).round() / 10;
  }

  /// §13 — movements agrupados por día, con subtotales por día.
  /// Usado por el historial agrupado (S05).
  static List<DailyGroup> groupByDay(Iterable<Movement> movements) {
    final byDay = <DateTime, List<Movement>>{};
    for (final m in movements) {
      final day = DateTime(m.date.year, m.date.month, m.date.day);
      byDay.putIfAbsent(day, () => []).add(m);
    }

    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    return days
        .map((day) {
          final items = byDay[day]!;
          return DailyGroup(
            date: day,
            movements: items,
            totalIncome: totalIncome(items),
            totalExpense: totalExpense(items),
          );
        })
        .toList();
  }

  /// S07 — Gráfico de barras de los últimos 6 meses.
  /// `now` se inyecta para poder testear sin depender del reloj.
  static List<MonthlyBar> lastMonths(Iterable<Movement> movements,
      {required int count, DateTime? now}) {
    final ref = now ?? DateTime.now();
    final months = <MonthlyBar>[];

    for (var i = count - 1; i >= 0; i--) {
      final d = DateTime(ref.year, ref.month - i);
      final start = DateTime(d.year, d.month);
      final end = DateTime(d.year, d.month + 1);
      final inMonth = movements.where(
        (m) => !m.date.isBefore(start) && m.date.isBefore(end),
      );
      months.add(MonthlyBar(
        month: d,
        income: totalIncome(inMonth),
        expense: totalExpense(inMonth),
      ));
    }
    return months;
  }
}
```

### Paso 8 — `financial_summary.dart`

```dart
import 'entities/movement.dart';
import 'financial_calculator.dart';

/// §13 — Resultado inmutable de un período. Lo consumen las vistas.
class FinancialSummary {
  const FinancialSummary({
    required this.period,
    required this.income,
    required this.expense,
    required this.balance,
    required this.breakdown,
    required this.savingsRate,
    required this.movementCount,
  });

  final DateTime period;
  final int income;
  final int expense;
  final int balance;
  final List<CategoryBreakdown> breakdown;
  final double savingsRate;
  final int movementCount;

  bool get hasData => movementCount > 0;

  static FinancialSummary from(Iterable<Movement> movements, DateTime period) {
    final list = movements.toList();
    return FinancialSummary(
      period: period,
      income: FinancialCalculator.totalIncome(list),
      expense: FinancialCalculator.totalExpense(list),
      balance: FinancialCalculator.balance(list),
      breakdown: FinancialCalculator.breakdownByCategory(list),
      savingsRate: FinancialCalculator.savingsRate(list),
      movementCount: list.length,
    );
  }
}

class CategoryBreakdown {
  const CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.colorValue,
    required this.iconKey,
    required this.amount,
    required this.percentage,
  });

  final int categoryId;
  final String categoryName;
  final int colorValue;
  final String iconKey;
  final int amount;
  final double percentage;
}

class DailyGroup {
  const DailyGroup({
    required this.date,
    required this.movements,
    required this.totalIncome,
    required this.totalExpense,
  });

  final DateTime date;
  final List<Movement> movements;
  final int totalIncome;
  final int totalExpense;
}

class MonthlyBar {
  const MonthlyBar({
    required this.month,
    required this.income,
    required this.expense,
  });

  final DateTime month;
  final int income;
  final int expense;
}
```

### Comandos de aceptación S02

```bash
flutter analyze
```

**Debe cumplirse:**
- [x] `flutter analyze` → `No issues found!`
- [x] Ningún archivo de `features/*/domain/` importa `package:flutter` ni `package:drift`
- [x] `FinancialCalculator.balance` usa `signedAmount`; no hay `amount` con signo en disco
- [x] `breakdownByCategory` devuelve `[]` (no `NaN`) sin gastos
- [x] `savingsRate` devuelve `null` (no `NaN`) sin ingresos
- [x] `lastMonths(count: 6)` devuelve exactamente 6 elementos, ordenados de más antiguo a más reciente

**Checkpoint:**
```bash
git add -A
git commit -m "S02: entidades de dominio, validadores y cálculos financieros puros"
```

### Desviaciones registradas en S02

| Tema | El plan decía | Se hizo | Por qué |
|---|---|---|---|
| **`savingsRate` sin ingresos** | "devuelve `0` (no `NaN`)" | Devuelve **`null`** | `0` es un valor falso: la UI mostraría "Ahorro 0%" cuando en realidad no se puede calcular. Con `null` el widget decide si pinta la fila o no. Es un `double?`, no un `double`. |
| **Dónde viven los value objects** | `financial_summary.dart` | `financial_values.dart` aparte | `FinancialSummary.from` necesita `FinancialCalculator` y la calculadora necesita `CategoryBreakdown` / `DailyGroup` / `MonthlyBar`. Con todo en un archivo, el import es circular. Separarlos deja el ciclo explícito y un archivo por responsabilidad. |
| **`FinancialSummary.from`** | Calculaba el desglose | Pide también `List<Category>` | Sin las categorías solo se conoce el id: no hay nombre, color ni icono. El desglose es medio useless sin ellas. |
| **Tests de S02** | En S08 | Escritos en S02 (45 tests) | Son funciones puras: probarlas cuesta segundos y es la única forma de verificar que la aritmética del balance, los porcentajes y la ventana de meses es correcta. S08 queda solo con fakes y widgets. |
| **`lastMonths` orden** | "de más antiguo a más reciente" | Corregido a cronológico | La primera implementación restaba `i` al mes de referencia y salía al revés (nuevo → viejo). Un gráfico de barras leído de izquierda a derecha necesita lo contrario. Lo detectó el test de frontera de año. |
| **`CurrencyFormatter` `const`** | `static const _currency` | `final` + `NumberFormat` cacheado | Construir un `NumberFormat` por llamada es caro en una lista de movimientos. Se cachea en un `late final` por instancia, lo que obliga a quitar `const`. |
| **`validateAmount` con signo** | `replaceAll(RegExp(r'[^0-9]'), '')` | Rechaza el signo explícitamente | Ese regex converts `-5` en `5` y lo daba por **válido**, contradiciendo la regla de §15. Ahora se valida el formato antes de convertir. |
| **`DailyGroup.movements`** | `List<Movement>` | Igual, pero **no** `List<dynamic>` | `dynamic` habría roto todo el tipado del historial en S05. |

**Restricción heredada de S00:** `core/utils/` mezcla código puro y código con
Flutter. `currency_formatter.dart` y `validators.dart` son puros y se testean sin
widget; **`date_utils.dart` no lo es**, porque `monthRange` devuelve un
`DateTimeRange` de material. Consecuencia: `AppDateUtils.monthRange` solo se
puede llamar desde `presentation`, nunca desde `domain` ni desde `data`. Quien
necesite el rango para consultar la base debe usar `date.start` / `date.end`.

**Estado de aceptación S02:** los seis puntos de "Debe cumplirse" verificados,
más 45 tests nuevos. Total de la suite: 66 tests, todos en verde.

---

<a id="s03--categorías"></a>

## S03 — Categorías

**Objetivo:** exponer el catálogo como provider y poder pintar iconos.
**Dejar para:** S04, que ya puede abrir el formulario con la lista cargada.

### Paso 1 — Repositorio de categorías

```dart
// features/categories/domain/repositories/category_repository.dart
import '../entities/category.dart';

abstract interface class CategoryRepository {
  Stream<List<Category>> watchAll();
  Future<List<Category>> getAll();
  Future<Category?> getById(int id);
}
```

```dart
// features/categories/data/drift_category_repository.dart
import '../../../core/database/daos.dart';
import '../domain/entities/category.dart';
import '../domain/repositories/category_repository.dart';

class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._dao);
  final CategoriesDao _dao;

  @override
  Stream<List<Category>> watchAll() => _dao.watchAll();

  @override
  Future<List<Category>> getAll() => _dao.getAll();

  @override
  Future<Category?> getById(int id) => _dao.getById(id);
}
```

### Paso 2 — Registro de iconos (D9)

Las claves viven en el dominio como `String`; aquí se convierten a `IconData`.
Si una clave no existe, se cae a un icono genérico en vez de romper.

```dart
// features/categories/presentation/category_icon_registry.dart
import 'package:flutter/material.dart';

/// D9 — Mapea la clave textual guardada en la BD a un `IconData` de Material.
abstract final class CategoryIconRegistry {
  static const _icons = <String, IconData>{
    // Gastos
    'restaurant': Icons.restaurant,
    'directions_bus': Icons.directions_bus,
    'home': Icons.home,
    'bolt': Icons.bolt,
    'favorite': Icons.favorite,
    'movie': Icons.movie,
    'school': Icons.school,
    'shopping_bag': Icons.shopping_bag,
    'devices': Icons.devices,
    // Ingresos
    'work': Icons.work,
    'laptop_mac': Icons.laptop_mac,
    'trending_up': Icons.trending_up,
    'savings': Icons.savings,
    // Común
    'more_horiz': Icons.more_horiz,
  };

  static IconData resolve(String key) => _icons[key] ?? Icons.category;
}
```

### Paso 3 — Widget `CategoryIcon`

```dart
// features/categories/presentation/widgets/category_icon.dart
import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';
import '../category_icon_registry.dart';

/// §12 — Ícono circular con el color de la categoría.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    required this.category,
    this.size = 44,
    super.key,
  });

  final Category category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(
        CategoryIconRegistry.resolve(category.iconKey),
        size: size * 0.5,
        color: color,
      ),
    );
  }
}
```

### Paso 4 — Providers

```dart
// features/categories/presentation/providers/category_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

/// Stream: se reconstruye solo si el catálogo cambia (§35).
/// S09 puede invalidarlo tras sembrar categorías nuevas.
final categoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

/// Categorías de gasto, ordenadas por `sortOrder` (§12 selector de tipo).
final expenseCategoriesProvider = Provider<List<Category>>((ref) {
  return ref
      .watch(categoriesProvider)
      .maybeWhen(
        data: (list) => list.where((c) => c.type.isExpense).toList(),
        orElse: () => const [],
      );
});

final incomeCategoriesProvider = Provider<List<Category>>((ref) {
  return ref
      .watch(categoriesProvider)
      .maybeWhen(
        data: (list) => list.where((c) => c.type.isIncome).toList(),
        orElse: () => const [],
      );
});

/// Lookup por id: el `Movement` ya trae su `Category` embebida, pero el
/// formulario necesita resolver la seleccionada.
final categoryByIdProvider = Provider.family<AsyncValue<Category?>, int>((ref, id) {
  return ref.watch(categoriesProvider).maybeWhen(
        data: (list) => AsyncData(list.where((c) => c.id == id).firstOrNull),
        orElse: () => const AsyncLoading(),
      );
});
```

**Sobre `repository_providers.dart`** (en `core/providers/`): expone los
repositorios como providers para que presentation no importe `data`:

```dart
final movementRepositoryProvider = Provider<MovementRepository>(
  (ref) => DriftMovementRepository(ref.watch(movementsDaoProvider)),
);
final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => DriftCategoryRepository(ref.watch(categoriesDaoProvider)),
);
```

Y en `core/database/database_providers.dart`, además de `appDatabaseProvider`:

```dart
final movementsDaoProvider = Provider<MovementsDao>(
  (ref) => MovementsDao(ref.watch(appDatabaseProvider)),
);
final categoriesDaoProvider = Provider<CategoriesDao>(
  (ref) => CategoriesDao(ref.watch(appDatabaseProvider)),
);
```

### Paso 5 — Smoke test de UI

En S03 no hay pantalla nueva. Solo verificar que el provider resuelve
14 elementos. Es un test widget mínimo; el suite completo llega en S08.

```dart
testWidgets('categoriesProvider expone 10 gastos y 4 ingresos', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [categoryRepositoryProvider.overrideWithValue(FakeCategoryRepository())],
      child: const Consumer(builder: (c, r, _) => SizedBox()),
    ),
  );
  final container = ProviderScope.containerOf(tester.element(find.byType(SizedBox)));
  final list = await container.read(categoriesProvider.future);
  expect(list.where((c) => c.type.isExpense), hasLength(10));
  expect(list.where((c) => c.type.isIncome), hasLength(4));
});
```

### Comandos de aceptación S03

```bash
flutter analyze
```

**Debe cumplirse:**
- [ ] `flutter analyze` → `No issues found!`
- [ ] Ningún archivo de `presentation/` importa `package:drift` ni `core/database/`
- [ ] `CategoryIconRegistry.resolve` devuelve `Icons.category` para una clave desconocida (no lanza)
- [ ] `expenseCategoriesProvider` y `incomeCategoriesProvider` devuelven listas ya ordenadas

**Checkpoint:**
```bash
git add -A
git commit -m "S03: catálogo de categorías, registro de iconos y providers"
```

---

<a id="s04--registro-de-movimientos"></a>

## S04 — Registro de movimientos

**Objetivo:** el formulario de crear y editar, con validación en vivo.
**Dejar para:** S05, que ya puede navegar a editar y mostrar SnackBars.

### Paso 1 — Controller del formulario

Riverpod 3: `NotifierProvider` para el estado. El estado es **inmutable** y
contiene los campos crudos, para que `TextFormField` no pierda el cursor.

```dart
// features/movements/presentation/providers/movement_form_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/entities/movement.dart';
import '../../domain/entities/movement_type.dart';
import '../../domain/repositories/movement_repository.dart';

/// Estado del formulario. Los campos se guardan crudos (§15 valida al guardar).
class MovementFormState {
  const MovementFormState({
    this.id,
    this.amount = '',
    this.type = MovementType.expense,
    this.categoryId,
    this.date,
    this.description = '',
    this.isSaving = false,
    this.saveError,
  });

  final int? id;                 // null = creando
  final String amount;
  final MovementType type;
  final int? categoryId;
  final DateTime? date;
  final String description;
  final bool isSaving;
  final String? saveError;

  bool get isEditing => id != null;

  /// §15 — Validación de un solo campo, para el error en vivo.
  String? amountError() => validateAmount(amount).error;
  String? descriptionError() => validateDescription(description).error;
  String? dateError() => validateDate(date).error;
  String? categoryError() =>
      categoryId == null ? 'Selecciona una categoría' : null;

  /// Todo el formulario.
  String? get firstError {
    for (final e in [amountError(), categoryError(), dateError(), descriptionError()]) {
      if (e != null) return e;
    }
    return null;
  }

  MovementFormState copyWith({
    int? Function()? id,
    String? amount,
    MovementType? type,
    int? Function()? categoryId,
    DateTime? Function()? date,
    String? description,
    bool? isSaving,
    String? Function()? saveError,
  }) {
    return MovementFormState(
      id: id != null ? id() : this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      date: date != null ? date() : this.date,
      description: description ?? this.description,
      isSaving: isSaving ?? this.isSaving,
      saveError: saveError != null ? saveError() : this.saveError,
    );
  }
}

/// `family` con el id de la ruta: null = formulario de creación.
final movementFormProvider =
    NotifierProvider.autoDispose.family<MovementFormController, MovementFormState, int?>(
  MovementFormController.new,
);

class MovementFormController extends FamilyNotifier<MovementFormState, int?> {
  @override
  MovementFormState build(int? arg) {
    final id = arg;
    if (id == null) {
      return MovementFormState(date: _today());
    }

    final existing = ref.watch(movementByIdProvider(id));
    return existing.maybeWhen(
      data: (m) {
        if (m == null) return const MovementFormState(date: _today());
        return MovementFormState(
          id: m.id,
          amount: m.amount.toString(),
          type: m.type,
          categoryId: m.category.id,
          date: m.date,
          description: m.description,
        );
      },
      orElse: () => MovementFormState(date: _today()),
    );
  }

  static DateTime? _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void setAmount(String value) => state = state.copyWith(amount: value, saveError: () => null);
  void setType(MovementType value) {
    // Cambiar de tipo limpia la categoría: las de gasto no aplican a ingreso (§12).
    state = state.copyWith(type: value, categoryId: () => null, saveError: () => null);
  }
  void setCategory(int? value) => state = state.copyWith(categoryId: () => value, saveError: () => null);
  void setDate(DateTime value) => state = state.copyWith(date: () => value, saveError: () => null);
  void setDescription(String value) => state = state.copyWith(description: value, saveError: () => null);

  /// §15 — Valida y persiste. Devuelve `true` si tuvo éxito.
  Future<bool> save() async {
    final error = state.firstError;
    if (error != null) {
      state = state.copyWith(saveError: () => error);
      return false;
    }

    state = state.copyWith(isSaving: true, saveError: () => null);

    final draft = MovementDraft(
      amount: int.parse(state.amount.replaceAll(RegExp(r'[^\d]'), '')),
      type: state.type,
      categoryId: state.categoryId!,
      date: state.date!,
      description: state.description,
    ).normalized();

    try {
      final repo = ref.read(movementRepositoryProvider);
      if (state.isEditing) {
        await repo.update(state.id!, draft);
      } else {
        await repo.create(draft);
      }
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, saveError: () => 'No se pudo guardar. Intenta de nuevo.');
      return false;
    }
  }
}
```

**Dos riesgos a verificar al escribir S04:**

1. `FamilyNotifier<State, Arg>` requiere Riverpod 3. Si el análisis falla con esa
   firma, el equivalente es `NotifierProvider.autoDispose.family` con un
   `Notifier` normal y el argumento leído de `arg` en `build`. Comprobar la API
   instalada antes de asumir.
2. `ref.watch(movementByIdProvider(id))` dentro de `build` re-construye el
   formulario cuando cambia el movimiento. Es el comportamiento deseado al editar.

### Paso 2 — `movementByIdProvider`

```dart
// features/movements/presentation/providers/history_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/movement.dart';
import '../../domain/entities/movement_type.dart';

/// §13 — Todos los movimientos del mes seleccionado, ordenados desc.
final movementsForSelectedMonthProvider = StreamProvider<List<Movement>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(movementRepositoryProvider).watchByMonth(month);
});

/// Para editar: carga puntual por id.
final movementByIdProvider = FutureProvider.family<Movement?, int>((ref, id) {
  return ref.watch(movementRepositoryProvider).getById(id);
});

/// Mes visible en el dashboard. Notifier para que S07 lo pueda cambiar
/// con los controles ‹ ›.
class SelectedMonth extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void previous() {
    state = DateTime(state.year, state.month - 1);
  }

  void next() {
    final now = DateTime.now();
    final candidate = DateTime(state.year, state.month + 1);
    // No se puede avanzar más allá del mes actual.
    if (candidate.isAfter(DateTime(now.year, now.month))) return;
    state = candidate;
  }

  void goTo(DateTime month) => state = DateTime(month.year, month.month);
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonth, DateTime>(SelectedMonth.new);
```

### Paso 3 — Widgets del formulario

```dart
// amount_input_field.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';

/// §9 y §15 — Campo numérico con prefijo de moneda.
/// Se usa `FilteringTextInputFormatter.digitsOnly`: el usuario no puede
/// escribir letras, signos ni el símbolo de moneda.
class AmountInputField extends ConsumerWidget {
  const AmountInputField({
    required this.controller,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(12),
      ],
      style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        labelText: 'Monto',
        hintText: '0',
        prefixText: '${const CurrencyFormatter(CurrencyCode.cop).symbol} ',
        prefixStyle: theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        errorText: errorText,
        errorMaxLines: 2,
      ),
    );
  }
}
```

```dart
// movement_type_selector.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../domain/entities/movement_type.dart';

/// §12 — SegmentedButton de 2 opciones, con color semántico.
class MovementTypeSelector extends StatelessWidget {
  const MovementTypeSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final MovementType value;
  final ValueChanged<MovementType> onChanged;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semantic;
    return SegmentedButton<MovementType>(
      segments: [
        ButtonSegment(
          value: MovementType.expense,
          label: const Text('Gasto'),
          icon: Icon(Icons.trending_down, color: semantic.expense),
        ),
        ButtonSegment(
          value: MovementType.income,
          label: const Text('Ingreso'),
          icon: Icon(Icons.trending_up, color: semantic.income),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}
```

```dart
// category_picker.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/widgets/category_icon.dart';

/// §12 — Grid de categorías filtradas por tipo. Objeto seleccionable único.
class CategoryPicker extends StatelessWidget {
  const CategoryPicker({
    required this.categories,
    required this.selectedId,
    required this.onChanged,
    super.key,
  });

  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.95,
      ),
      itemCount: categories.length,
      itemBuilder: (context, i) {
        final c = categories[i];
        final selected = c.id == selectedId;
        return InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => onChanged(c.id),
          child: Container(
            decoration: BoxDecoration(
              color: selected
                  ? Color(c.colorValue).withValues(alpha: 0.12)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: selected ? Color(c.colorValue) : Theme.of(context).dividerColor,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CategoryIcon(category: c, size: 36),
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

```dart
// date_picker_field.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';

/// §15 — Fecha por defecto: hoy. `lastDate` impide elegir futuro.
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    required this.value,
    required this.onChanged,
    this.errorText,
    super.key,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          // No se puede seleccionar una fecha futura (§15).
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year, now.month, now.day),
          helpText: 'Selecciona la fecha',
          cancelText: 'Cancelar',
          confirmText: 'Aceptar',
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Fecha',
          errorText: errorText,
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(
          value == null ? 'Selecciona una fecha' : AppDateUtils.formatShort(value!),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: value == null
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
```

### Paso 4 — Pantalla del formulario

```dart
// features/movements/presentation/screens/movement_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/feedback.dart';
import '../../../categories/domain/entities/movement_type.dart';
import '../../domain/entities/movement.dart';
import '../providers/movement_form_controller.dart';
import '../widgets/amount_input_field.dart';
import '../widgets/category_picker.dart';
import '../widgets/date_picker_field.dart';
import '../widgets/movement_type_selector.dart';

/// §12 — Crear y editar comparten pantalla. `id == null` → crear.
class MovementFormScreen extends ConsumerStatefulWidget {
  const MovementFormScreen({this.id, super.key});

  final int? id;

  @override
  ConsumerState<MovementFormScreen> createState() => _MovementFormScreenState();
}

class _MovementFormScreenState extends ConsumerState<MovementFormScreen> {
  late final TextEditingController _amount = TextEditingController();
  late final TextEditingController _description = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(movementFormProvider(widget.id));

    // Siembra los `TextEditingController` una vez que el estado llega con datos.
    if (!_seeded && state.id != null) {
      _seeded = true;
      _amount.text = state.amount;
      _description.text = state.description;
    }

    final categories = ref.watch(
      state.type.isExpense ? expenseCategoriesProvider : incomeCategoriesProvider,
    );
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(state.isEditing ? 'Editar movimiento' : 'Nuevo movimiento'),
        actions: [
          if (state.isEditing)
            IconButton(
              tooltip: 'Eliminar',
              icon: const Icon(Icons.delete_outline),
              color: theme.colorScheme.error,
              onPressed: () => _confirmDelete(context, state.id!),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          MovementTypeSelector(
            value: state.type,
            onChanged: (t) => ref
                .read(movementFormProvider(widget.id).notifier)
                .setType(t),
          ),
          const SizedBox(height: AppSpacing.lg),
          AmountInputField(
            controller: _amount,
            onChanged: (v) =>
                ref.read(movementFormProvider(widget.id).notifier).setAmount(v),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Categoría', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          categories.when(
            data: (list) => CategoryPicker(
              categories: list,
              selectedId: state.categoryId,
              onChanged: (id) => ref
                  .read(movementFormProvider(widget.id).notifier)
                  .setCategory(id),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text('No se pudieron cargar las categorías',
                style: TextStyle(color: theme.colorScheme.error)),
          ),
          if (state.categoryError() != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs, left: AppSpacing.sm),
              child: Text(
                state.categoryError()!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          DatePickerField(
            value: state.date,
            errorText: state.dateError(),
            onChanged: (d) =>
                ref.read(movementFormProvider(widget.id).notifier).setDate(d),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _description,
            onChanged: (v) => ref
                .read(movementFormProvider(widget.id).notifier)
                .setDescription(v),
            maxLength: 100,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Descripción (opcional)',
              hintText: 'Ej: almuerzo en la oficina',
              errorText: state.descriptionError(),
              helperText: '${state.description.length}/100',
            ),
          ),
          if (state.saveError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.saveError!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          SizedBox(height: bottomInset > 0 ? bottomInset : AppSpacing.lg),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          child: FilledButton(
            onPressed: state.isSaving ? null : _save,
            child: state.isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(state.isEditing ? 'Guardar cambios' : 'Guardar'),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final ok = await ref.read(movementFormProvider(widget.id).notifier).save();
    if (!ok || !mounted) return;
    final wasEditing = ref.read(movementFormProvider(widget.id)).isEditing;
    context.pop();
    showAppSnackBar(
      context,
      wasEditing ? 'Movimiento actualizado' : 'Movimiento registrado',
      SnackBarKind.success,
    );
  }

  Future<void> _confirmDelete(BuildContext context, int id) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Eliminar movimiento',
      message: 'Se eliminará de forma permanente. ¿Continuar?',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(movementRepositoryProvider).delete(id);
    if (!mounted) return;
    context.pop();
    showAppSnackBar(context, 'Movimiento eliminado', SnackBarKind.info);
  }
}
```

### Paso 5 — `shared/widgets/feedback.dart` y `confirm_dialog.dart`

```dart
// shared/widgets/feedback.dart
import 'package:flutter/material.dart';
import '../../core/theme/theme_extensions.dart';

enum SnackBarKind { success, error, info }

/// §15 — SnackBar unificado. Colores del `ThemeExtension` semántico.
void showAppSnackBar(BuildContext context, String message, SnackBarKind kind) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final semantic = context.semantic;
  final color = switch (kind) {
    SnackBarKind.success => semantic.income,
    SnackBarKind.error => semantic.expense,
    SnackBarKind.info => null,
  };

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
```

```dart
// shared/widgets/confirm_dialog.dart
import 'package:flutter/material.dart';

/// §12 y §37 — Confirmación para acciones destructivas.
/// `destructive` pinta el botón de confirmar en rojo.
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool destructive = false,
}) {
  final theme = Theme.of(context);
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
```

### Paso 6 — Sustituir los placeholders en el router

En `app_router_provider.dart` (el archivo de S00), reemplazar los placeholders:
`MovementFormPlaceholder` → `MovementFormScreen`, `SplashPlaceholder` →
`AppSplash`. La forma del router no cambia.

```dart
GoRoute(
  path: AppRoutes.newMovement,
  parentNavigatorKey: rootNavigatorKey,
  pageBuilder: (context, state) => const MaterialPage(
    fullscreenDialog: true,
    child: MovementFormScreen(),
  ),
),
GoRoute(
  path: AppRoutes.movementById,
  parentNavigatorKey: rootNavigatorKey,
  pageBuilder: (context, state) => MaterialPage(
    fullscreenDialog: true,
    child: MovementFormScreen(id: int.parse(movementIdFrom(state)!)),
  ),
),
```

### Comandos de aceptación S04

```bash
flutter analyze
flutter run
```

**Debe cumplirse:**
- [ ] `flutter analyze` → `No issues found!`
- [ ] El FAB abre el formulario; el fondo es `#F8FAFC`
- [ ] `SegmentedButton` alterna entre Gasto e Ingreso, y **la categoría se limpia** al cambiar de tipo
- [ ] El teclado solo permite dígitos; no se puede escribir `-` ni `$`
- [ ] Guardar sin categoría muestra el error bajo el grid
- [ ] `showDatePicker` no deja elegir fecha futura
- [ ] El límite de descripción es 100 caracteres
- [ ] Tras guardar, la pantalla se cierra y aparece el SnackBar
- [ ] Un movimiento nuevo aparece en el historial sin reiniciar la app
- [ ] Editar precarga monto, tipo, categoría, fecha y descripción
- [ ] Eliminar pide confirmación y borra

**Checkpoint:**
```bash
git add -A
git commit -m "S04: formulario de registro y edición de movimientos"
```

---

<a id="s05--historial"></a>

## S05 — Historial

**Objetivo:** listado agrupado por día, filtro mensual y acceso a editar/eliminar.
**Dejar para:** S06, que reutiliza el filtro de mes ya construido.

### Paso 1 — Provider del historial agrupado

```dart
// features/movements/presentation/providers/history_providers.dart (añadir)
import '../../domain/financial_calculator.dart';
import '../../domain/financial_summary.dart';

/// §13 — Historial agrupado por día, con subtotales.
final historyGroupsProvider = Provider<AsyncValue<List<DailyGroup>>>((ref) {
  return ref.watch(movementsForSelectedMonthProvider).maybeWhen(
        data: (movements) => AsyncData(FinancialCalculator.groupByDay(movements)),
        loading: () => const AsyncLoading(),
        error: (e, s) => AsyncError(e, s),
      );
});
```

### Paso 2 — `movement_tile.dart`

```dart
// features/movements/presentation/widgets/movement_tile.dart
import 'package:flutter/material.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../categories/presentation/widgets/category_icon.dart';
import '../../domain/entities/movement.dart';

/// §12 — Fila: ícono, categoría + descripción, monto con signo.
class MovementTile extends StatelessWidget {
  const MovementTile({
    required this.movement,
    required this.onTap,
    super.key,
  });

  final Movement movement;
  final VoidCallback onTap;

  static const _currency = CurrencyFormatter(CurrencyCode.cop);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final isIncome = movement.isIncome;
    final color = isIncome ? semantic.income : semantic.expense;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: CategoryIcon(category: movement.category),
      title: Text(
        movement.description.isEmpty
            ? movement.category.name
            : movement.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyLarge,
      ),
      subtitle: Text(
        '${movement.category.name} · ${AppDateUtils.formatShortWithTime(movement.date)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Text(
        '${isIncome ? '+' : '-'}${_currency.format(movement.amount)}',
        style: theme.textTheme.bodyStrong?.copyWith(color: color),
      ),
    );
  }
}
```

### Paso 3 — `history_screen.dart`

```dart
// features/movements/presentation/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/financial_summary.dart'; // DailyGroup
import '../providers/history_providers.dart';
import '../widgets/movement_tile.dart';

/// §13 — Historial del mes, agrupado por día con subtotales.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groups = ref.watch(historyGroupsProvider);
    final month = ref.watch(selectedMonthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            tooltip: 'Mes anterior',
            icon: const Icon(Icons.chevron_left),
            onPressed: () =>
                ref.read(selectedMonthProvider.notifier).previous(),
          ),
          TextButton(
            onPressed: () => _showMonthPicker(context, ref, month),
            child: Text(AppDateUtils.formatMonth(month)),
          ),
          IconButton(
            tooltip: 'Mes siguiente',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => ref.read(selectedMonthProvider.notifier).next(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(historyGroupsProvider);
          ref.invalidate(movementsForSelectedMonthProvider);
        },
        child: groups.when(
          data: (days) {
            if (days.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.5,
                    child: EmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'Sin movimientos',
                      message: AppDateUtils.formatMonthRelative(month, DateTime.now()) +
                          ' no tiene movimientos registrados.',
                      actionLabel: 'Registrar movimiento',
                      onAction: () => context.push(AppRoutes.newMovement),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl),
              itemCount: days.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: AppSpacing.md),
              itemBuilder: (context, i) {
                final group = days[i];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DayHeader(group: group),
                    ...group.movements.map(
                      (m) => MovementTile(
                        movement: m,
                        onTap: () => context.push(
                          AppRoutes.editMovementPath(m.id.toString()),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(
              'No se pudo cargar el historial',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMonthPicker(
      BuildContext context, WidgetRef ref, DateTime current) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Selecciona el mes',
    );
    if (picked != null) {
      ref.read(selectedMonthProvider.notifier).goTo(picked);
    }
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.group});

  final DailyGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const currency = CurrencyFormatter(CurrencyCode.cop);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppDateUtils.formatShort(group.date),
              style: theme.textTheme.label?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (group.totalExpense > 0)
            Text(
              '-${currency.format(group.totalExpense)}',
              style: theme.textTheme.label
                  ?.copyWith(color: theme.colorScheme.error),
            ),
        ],
      ),
    );
  }
}
```

### Paso 4 — `shared/widgets/empty_state.dart`

```dart
import 'package:flutter/material.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// §14 — Estado vacío unificado. Icono, texto y acción opcional.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTypography.title, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
```

### Comandos de aceptación S05

```bash
flutter analyze
flutter run
```

**Debe cumplirse:**
- [ ] `flutter analyze` → `No issues found!`
- [ ] Los movimientos se agrupan por día, días en orden descendente
- [ ] Cada cabecera de día muestra el subtotal de gastos del día
- [ ] Tocar un movimiento abre el formulario en modo edición
- [ ] Los controles ‹ › cambian de mes y la lista se actualiza
- [ ] El botón › está deshabilitado en el mes actual
- [ ] Mes sin movimientos muestra el estado vacío con acción
- [ ] Al guardar en el historial, la lista se actualiza sin reiniciar

**Checkpoint:**
```bash
git add -A
git commit -m "S05: historial agrupado por día con filtro mensual"
```

---

<a id="s06--dashboard-y-resumen-mensual"></a>

## S06 — Dashboard y resumen mensual

**Objetivo:** pantalla principal del PRD §13.
**Dejar para:** S07, que solo añade estados vacíos y pulido visual.

### Paso 1 — Provider del resumen

```dart
// features/dashboard/presentation/providers/dashboard_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../movements/domain/financial_calculator.dart';
import '../../../movements/domain/financial_summary.dart';
import '../../../movements/presentation/providers/history_providers.dart';

/// El mes del dashboard y el del historial comparten el mismo estado,
/// para que cambiar de pestaña no pierda el filtro.
typedef SelectedMonth = DateTime;

/// §13 — Resumen del mes: totales, balance, desglose y tasa de ahorro.
final monthlySummaryProvider = Provider<AsyncValue<FinancialSummary>>((ref) {
  final month = ref.watch(selectedMonthProvider);
  return ref.watch(movementsForSelectedMonthProvider).maybeWhen(
        data: (movements) =>
            AsyncData(FinancialSummary.from(movements, month)),
        loading: () => const AsyncLoading(),
        error: (e, s) => AsyncError(e, s),
      );
});

/// S07 — 5 movimientos más recientes del mes.
final recentMovementsProvider = Provider<AsyncValue<List<Movement>>>((ref) {
  return ref.watch(movementsForSelectedMonthProvider).maybeWhen(
        data: (list) => AsyncData(list.take(5).toList()),
        loading: () => const AsyncLoading(),
        error: (e, s) => AsyncError(e, s),
      );
});

/// Categorías que tienen movimientos este mes, ordenadas por monto.
final breakdownProvider = Provider<AsyncValue<List<CategoryBreakdown>>>((ref) {
  return ref.watch(monthlySummaryProvider).maybeWhen(
        data: (s) => AsyncData(s.breakdown),
        loading: () => const AsyncLoading(),
        error: (e, st) => AsyncError(e, st),
      );
});
```

**Nota:** `selectedMonthProvider` se define en
`features/movements/presentation/providers/history_providers.dart` (S04) y se
importa desde aquí. No duplicarlo.

### Paso 2 — `month_selector.dart`

```dart
// features/dashboard/presentation/widgets/month_selector.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';

/// §13 — Selector ‹ mes ›. `onNext` nulo deshabilita el botón.
class MonthSelector extends StatelessWidget {
  const MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Mes anterior',
        ),
        Expanded(
          child: Center(
            child: Text(
              AppDateUtils.formatMonth(month),
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Mes siguiente',
        ),
      ],
    );
  }
}
```

### Paso 3 — `balance_card.dart` y `totals_row.dart`

```dart
// balance_card.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/date_utils.dart';

/// §13 — Tarjeta principal: balance del mes con color semántico.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    required this.balance,
    required this.month,
    required this.savingsRate,
    super.key,
  });

  final int balance;
  final DateTime month;
  final double savingsRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final isPositive = balance >= 0;
    const currency = CurrencyFormatter(CurrencyCode.cop);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balance · ${AppDateUtils.formatMonth(month)}',
              style: theme.textTheme.label
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              currency.formatSigned(balance),
              style: theme.textTheme.display?.copyWith(
                color: isPositive ? semantic.income : semantic.expense,
              ),
            ),
            if (savingsRate > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Ahorro: ${savingsRate.toStringAsFixed(1)}% de tus ingresos',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

```dart
// totals_row.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/currency_formatter.dart';

/// §13 — Tarjetas de ingresos y gastos, lado a lado.
class TotalsRow extends StatelessWidget {
  const TotalsRow({required this.income, required this.expense, super.key});

  final int income;
  final int expense;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TotalCard(
            label: 'Ingresos',
            amount: income,
            icon: Icons.trending_up,
            color: context.semantic.income,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _TotalCard(
            label: 'Gastos',
            amount: expense,
            icon: Icons.trending_down,
            color: context.semantic.expense,
          ),
        ),
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final int amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const currency = CurrencyFormatter(CurrencyCode.cop);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: AppSpacing.xs),
                Text(label, style: theme.textTheme.label),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              currency.format(amount),
              style: theme.textTheme.titleLarge?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Paso 4 — `category_breakdown.dart`

```dart
// category_breakdown.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../categories/presentation/category_icon_registry.dart';
import '../../../movements/domain/financial_summary.dart';

/// §13 — Barra de progreso por categoría, ordenada de mayor a menor.
class CategoryBreakdownList extends StatelessWidget {
  const CategoryBreakdownList({required this.items, super.key});

  final List<CategoryBreakdown> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    const currency = CurrencyFormatter(CurrencyCode.cop);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gastos por categoría', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            ...items.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          CategoryIconRegistry.resolve(b.iconKey),
                          size: 16,
                          color: Color(b.colorValue),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            b.categoryName,
                            style: theme.textTheme.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${currency.format(b.amount)}  ${b.percentage.toStringAsFixed(1)}%',
                          style: theme.textTheme.label,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        // 0..1 porque LinearProgressIndicator espera fracción.
                        value: (b.percentage / 100).clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: theme.colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation(Color(b.colorValue)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Paso 5 — `recent_movements.dart`

```dart
// recent_movements.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../movements/presentation/widgets/movement_tile.dart';
import '../../../movements/domain/entities/movement.dart';

/// §13 — Los 5 movimientos más recientes del mes.
class RecentMovements extends StatelessWidget {
  const RecentMovements({required this.movements, super.key});

  final List<Movement> movements;

  @override
  Widget build(BuildContext context) {
    if (movements.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.xs),
            child: Text('Movimientos recientes', style: theme.textTheme.titleMedium),
          ),
          ...movements.map(
            (m) => MovementTile(
              movement: m,
              onTap: () => context.push(AppRoutes.editMovementPath(m.id.toString())),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Paso 6 — `dashboard_screen.dart`

```dart
// features/dashboard/presentation/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../movements/presentation/providers/history_providers.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/balance_card.dart';
import '../widgets/category_breakdown.dart';
import '../widgets/month_selector.dart';
import '../widgets/recent_movements.dart';
import '../widgets/totals_row.dart';

/// §13 — Pantalla de inicio. Es la primera pestaña del shell.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final summary = ref.watch(monthlySummaryProvider);
    final recent = ref.watch(recentMovementsProvider);
    final breakdown = ref.watch(breakdownProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pipe Finanzas')),
      body: summary.when(
        data: (s) {
          if (!s.hasData) {
            return EmptyState(
              icon: Icons.pie_chart_outline,
              title: AppDateUtils.formatMonthRelative(month, DateTime.now()),
              message: 'Aún no tienes movimientos este mes. '
                  'Registra tu primer ingreso o gasto para ver tu resumen.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(monthlySummaryProvider);
              ref.invalidate(recentMovementsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, 0, AppSpacing.md, 96),
              children: [
                MonthSelector(
                  month: month,
                  onPrevious: () =>
                      ref.read(selectedMonthProvider.notifier).previous(),
                  onNext: ref.read(selectedMonthProvider.notifier).canGoNext
                      ? () => ref.read(selectedMonthProvider.notifier).next()
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                BalanceCard(
                  balance: s.balance,
                  month: month,
                  savingsRate: s.savingsRate,
                ),
                const SizedBox(height: AppSpacing.md),
                TotalsRow(income: s.income, expense: s.expense),
                const SizedBox(height: AppSpacing.md),
                breakdown.maybeWhen(
                  data: (items) => items.isEmpty
                      ? const SizedBox.shrink()
                      : CategoryBreakdownList(items: items),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.md),
                recent.maybeWhen(
                  data: (list) => list.isEmpty
                      ? const SizedBox.shrink()
                      : RecentMovements(movements: list),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('No se pudo cargar el resumen',
              style: TextStyle(color: theme.colorScheme.error)),
        ),
      ),
    );
  }
}
```

**Añadir `canGoNext` a `SelectedMonth`** (definido en S04). El dashboard lo usa
para deshabilitar el botón › en el mes actual:

```dart
bool get canGoNext {
  final now = DateTime.now();
  final next = DateTime(state.year, state.month + 1);
  return !next.isAfter(DateTime(now.year, now.month));
}
```

### Paso 7 — Sustituir el placeholder del dashboard

En `app_router_provider.dart`, reemplazar `DashboardPlaceholder` por
`DashboardScreen`. El shell queda igual.

### Comandos de aceptación S06

```bash
flutter analyze
flutter run
```

**Debe cumplirse:**
- [ ] `flutter analyze` → `No issues found!`
- [ ] El dashboard muestra balance, ingresos y gastos del mes actual
- [ ] El balance es verde si ≥ 0 y rojo si < 0
- [ ] El desglose por categoría está ordenado de mayor a menor y suma ~100 %
- [ ] El selector de mes cambia los tres bloques a la vez
- [ ] No se puede avanzar más allá del mes actual
- [ ] Con exactamente 1 movimiento, el balance es exactamente ese monto
- [ ] Sin movimientos del mes, aparece el estado vacío
- [ ] Al volver de la pestaña Historial, el dashboard mantiene el mes elegido

**Checkpoint:**
```bash
git add -A
git commit -m "S06: dashboard con balance, totales, desglose y resumen mensual"
```

---

<a id="s07--estados-vacíos-y-pulido"></a>

## S07 — Estados vacíos y pulido

**Objetivo:** cubrir los estados que el PRD nombra pero no se han materializado.
**Dejar para:** S08, con la app ya congelada funcionalmente.

### Paso 1 — Estados vacíos en todas las pantallas

Revisar las tres pantallas contra §14. Ninguna debe mostrar un espacio en blanco.

| Pantalla | Condición | Ícono | Título | Mensaje | Acción |
|---|---|---|---|---|---|
| Dashboard | mes sin movimientos | `pie_chart_outline` | "Este mes" | "Aún no tienes movimientos este mes. Registra tu primer ingreso o gasto para ver tu resumen." | ninguna |
| Historial | mes sin movimientos | `inbox_outlined` | "Sin movimientos" | "{Mes} no tiene movimientos registrados." | "Registrar movimiento" |
| Historial | mes sin movimientos | `search_off` | "Sin resultados" | "No hay movimientos que coincidan." | "Limpiar filtros" |

```dart
// Sustituir los iconos hardcodeados del §14 por un mapa central,
// para que añadir un estado no requiera tocar cada pantalla.
abstract final class EmptyStates {
  static const noMovements = EmptyStateData(
    icon: Icons.inbox_outlined,
    title: 'Sin movimientos',
    message: 'No hay movimientos registrados en este mes.',
  );
  static const noResults = EmptyStateData(
    icon: Icons.search_off,
    title: 'Sin resultados',
    message: 'No hay movimientos que coincidan.',
  );
}

class EmptyStateData {
  const EmptyStateData({required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;
}
```

### Paso 2 — Gráfico de barras de 6 meses (§13)

```dart
// features/dashboard/presentation/widgets/monthly_bars.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../movements/domain/financial_summary.dart';

/// §13 — Barras comparativas de ingresos vs gastos de los últimos 6 meses.
class MonthlyBars extends StatelessWidget {
  const MonthlyBars({required this.bars, super.key});

  final List<MonthlyBar> bars;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final semantic = context.semantic;
    final maxValue = bars
        .map((b) => b.income > b.expense ? b.income : b.expense)
        .fold(0, (a, b) => a > b ? a : b);

    if (maxValue == 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Últimos 6 meses', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: bars.map((b) {
                  return Expanded(
                    child: _BarGroup(
                      bar: b,
                      maxValue: maxValue,
                      incomeColor: semantic.income,
                      expenseColor: semantic.expense,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legend(color: semantic.income, label: 'Ingresos'),
                const SizedBox(width: AppSpacing.md),
                _Legend(color: semantic.expense, label: 'Gastos'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BarGroup extends StatelessWidget {
  const _BarGroup({
    required this.bar,
    required this.maxValue,
    required this.incomeColor,
    required this.expenseColor,
  });

  final MonthlyBar bar;
  final int maxValue;
  final Color incomeColor;
  final Color expenseColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Bar(
              value: bar.income,
              max: maxValue,
              color: incomeColor,
            ),
            const SizedBox(width: 3),
            _Bar(
              value: bar.expense,
              max: maxValue,
              color: expenseColor,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppDateUtils.monthName(bar.month.month).substring(0, 3),
          style: theme.textTheme.labelSmall,
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.max, required this.color});

  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = value / max;
    return Tooltip(
      message: CurrencyFormatter(CurrencyCode.cop).format(value),
      child: Container(
        width: 10,
        // Mínimo visible de 2 px para que un valor pequeño no desaparezca.
        height: value == 0 ? 0 : (14 * ratio).clamp(2.0, 126.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
```

Provider correspondiente, en `dashboard_providers.dart`:

```dart
/// S07 — Últimos 6 meses para el gráfico de barras.
final lastSixMonthsProvider = Provider<AsyncValue<List<MonthlyBar>>>((ref) {
  return ref.watch(movementRepositoryProvider).watchAll().asyncMap((all) {
    return FinancialCalculator.lastMonths(all, count: 6);
  }).then(AsyncData<List<MonthlyBar>>.new).onError(
        (e, s) => AsyncError<List<MonthlyBar>>(e, StackTrace.current),
      );
});
```

Y añadir `<MonthlyBars>` al `ListView` del dashboard, después de `TotalsRow`.

### Paso 3 — Pulido visual contra el PRD

Recorrer §17–§21 y verificar punto por punto:

- [ ] Fondo `#F8FAFC` en las 3 pantallas
- [ ] Tarjetas blancas con borde `#E2E8F0` y radio 12, sin sombra difusa
- [ ] Primary `#2563EB` en FAB, botón principal y elementos activos
- [ ] Texto principal `#0F172A`, secundario `#64748B`
- [ ] Verde `#16A34A` solo para ingresos, rojo `#DC2626` solo para gastos
- [ ] `NavigationBar` con indicador `#DBEAFE`
- [ ] Splash con fondo `#F8FAFC`
- [ ] Radio de 12 en tarjetas, 8 en inputs y botones
- [ ] Espaciado múltiplo de 8
- [ ] Todos los targets táctiles ≥ 48 dp (§35)

```bash
# Verificar que no quede ningún hex fuera de AppColors
grep -rn "Color(0x" lib/ --include=*.dart | grep -v "core/theme\|seed/default_categories"
```

Debe devolver **cero** resultados fuera de los archivos permitidos.

### Paso 4 — Accesibilidad básica

- [ ] Todos los iconos de acción tienen `tooltip` (§35)
- [ ] El `Semantics` del balance anuncia el valor con signo
- [ ] Los textos de las tarjetas no se truncan a 320 px de ancho
- [ ] Con `textScaleFactor` en 1.3 no hay desbordes (`RenderFlex overflowed`)

```bash
flutter run
# En el dispositivo: Settings > Display > Font size > Grande
```

### Comandos de aceptación S07

```bash
flutter analyze
flutter run
```

**Debe cumplirse:**
- [ ] `flutter analyze` → `No issues found!`
- [ ] Los tres estados vacíos de la tabla de S07 se ven correctamente
- [ ] El gráfico de 6 meses aparece con barras visibles, incluso con valores pequeños
- [ ] Ningún hex literal fuera de `AppColors` y del seed
- [ ] Sin desbordes con fuente grande

**Checkpoint:**
```bash
git add -A
git commit -m "S07: estados vacíos, gráfico de 6 meses y pulido visual"
```

---

<a id="s08--testing"></a>

## S08 — Testing

**Objetivo:** cumplir §33 con tests que **pasen de verdad** en este entorno.
**Dejar para:** S09, con la lógica ya congelada y verificada.

### Advertencia previa sobre la base de datos en tests

`NativeDatabase.memory()` usa `sqlite3` de FFI, que en `flutter test` sobre Windows
puede fallar si falta la DLL. **Estrategia de dos niveles**, aplicada en este orden:

1. **Nivel 1 (obligatorio, sin BD):** tests de `financial_calculator.dart`,
   `currency_formatter.dart`, `validators.dart`, `date_utils.dart` y
   `movement_type.dart`. Son funciones puras: pasan siempre.
2. **Nivel 2 (opcional):** tests de repositorio con BD real. Se intentan con
   `drift/native.dart`; si el runner falla por la DLL, se marcan como `skip`
   documentando la causa y se validan manualmente en `flutter run`.

**Nunca bloquear S08 por el nivel 2.** El nivel 1 es el que cubre §33.

### Paso 1 — Tests del dominio

```dart
// test/domain/financial_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/financial_calculator.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/financial_summary.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/category.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';

Category _cat(int id, String name, MovementType type) => Category(
      id: id,
      name: name,
      iconKey: 'more_horiz',
      colorValue: 0xFF64748B,
      type: type,
      isDefault: true,
      sortOrder: id,
    );

Movement _m(int id, int amount, MovementType type, {int? day}) => Movement(
      id: id,
      amount: amount,
      type: type,
      category: _cat(1, 'Test', type),
      date: DateTime(2026, 1, day ?? 1),
      description: '',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  group('totalIncome / totalExpense', () {
    test('suma solo los movimientos del tipo correspondiente', () {
      final list = [
        _m(1, 500000, MovementType.income),
        _m(2, 200000, MovementType.expense),
        _m(3, 300000, MovementType.income),
        _m(4, 100000, MovementType.expense),
      ];
      expect(FinancialCalculator.totalIncome(list), 800000);
      expect(FinancialCalculator.totalExpense(list), 300000);
    });

    test('devuelve 0 con lista vacía', () {
      expect(FinancialCalculator.totalIncome([]), 0);
      expect(FinancialCalculator.totalExpense([]), 0);
    });
  });

  group('balance', () {
    test('ingresos menos gastos', () {
      final list = [
        _m(1, 500000, MovementType.income),
        _m(2, 200000, MovementType.expense),
      ];
      expect(FinancialCalculator.balance(list), 300000);
    });

    test('negativo cuando los gastos superan los ingresos', () {
      final list = [
        _m(1, 100000, MovementType.income),
        _m(2, 400000, MovementType.expense),
      ];
      expect(FinancialCalculator.balance(list), -300000);
    });

    test('0 con lista vacía', () {
      expect(FinancialCalculator.balance([]), 0);
    });

    test('usa el tipo, no el signo del monto', () {
      // Un gasto con monto positivo resta igual (D6, §7).
      expect(FinancialCalculator.balance([_m(1, 100, MovementType.expense)]), -100);
      expect(FinancialCalculator.balance([_m(1, 100, MovementType.income)]), 100);
    });
  });

  group('breakdownByCategory', () {
    test('devuelve lista vacía sin gastos, sin NaN', () {
      final result = FinancialCalculator.breakdownByCategory(
        [_m(1, 100000, MovementType.income)],
      );
      expect(result, isEmpty);
    });

    test('ignora los ingresos', () {
      final result = FinancialCalculator.breakdownByCategory([
        _m(1, 100000, MovementType.income),
      ]);
      expect(result, isEmpty);
    });

    test('ordena de mayor a menor', () {
      final a = Category(id: 1, name: 'A', iconKey: 'home', colorValue: 1,
          type: MovementType.expense, isDefault: true, sortOrder: 1);
      final b = Category(id: 2, name: 'B', iconKey: 'home', colorValue: 2,
          type: MovementType.expense, isDefault: true, sortOrder: 2);

      final list = [
        Movement(id: 1, amount: 10000, type: MovementType.expense, category: a,
            date: DateTime(2026, 1, 5), description: '', createdAt: DateTime(2026, 1, 5), updatedAt: DateTime(2026, 1, 5)),
        Movement(id: 2, amount: 30000, type: MovementType.expense, category: b,
            date: DateTime(2026, 1, 5), description: '', createdAt: DateTime(2026, 1, 5), updatedAt: DateTime(2026, 1, 5)),
      ];

      final result = FinancialCalculator.breakdownByCategory(list);
      expect(result.first.categoryName, 'B');
      expect(result.first.amount, 30000);
      expect(result.first.percentage, 75.0);
    });
  });

  group('savingsRate', () {
    test('0 sin ingresos, sin NaN', () {
      expect(FinancialCalculator.savingsRate([_m(1, 100, MovementType.expense)]), 0);
    });

    test('porcentaje de ahorro sobre ingresos', () {
      final list = [
        _m(1, 1000000, MovementType.income),
        _m(2, 250000, MovementType.expense),
      ];
      expect(FinancialCalculator.savingsRate(list), 75.0);
    });
  });

  group('groupByDay', () {
    test('agrupa por día y ordena descendente', () {
      final list = [
        _m(1, 100, MovementType.expense, day: 1),
        _m(2, 200, MovementType.expense, day: 3),
        _m(3, 300, MovementType.expense, day: 1),
      ];
      final groups = FinancialCalculator.groupByDay(list);
      expect(groups.length, 2);
      expect(groups.first.date.day, 3);
      expect(groups.last.movements.length, 2);
      expect(groups.last.totalExpense, 400);
    });
  });

  group('lastMonths', () {
    test('devuelve exactamente 6 barras en orden ascendente', () {
      final now = DateTime(2026, 3, 15);
      final bars = FinancialCalculator.lastMonths([], count: 6, now: now);
      expect(bars.length, 6);
      expect(bars.first.month, DateTime(2025, 10));
      expect(bars.last.month, DateTime(2026, 3));
    });

    test('filtra por mes correctamente', () {
      final now = DateTime(2026, 3, 15);
      final list = [
        _m(1, 1000, MovementType.income, day: 1), // enero 2026
      ];
      final bars = FinancialCalculator.lastMonths(list, count: 6, now: now);
      expect(bars.first.income, 1000);
      expect(bars.last.income, 0);
    });
  });
}
```

```dart
// test/domain/validators_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/utils/validators.dart';

void main() {
  group('validateAmount', () {
    test('acepta enteros positivos', () {
      expect(validateAmount('25000').isValid, isTrue);
      expect(validateAmount('1').isValid, isTrue);
    });

    test('rechaza vacío', () {
      expect(validateAmount('').isValid, isFalse);
      expect(validateAmount(null).isValid, isFalse);
    });

    test('rechaza cero y negativos', () {
      expect(validateAmount('0').isValid, isFalse);
      expect(validateAmount('-5').isValid, isFalse);
    });

    test('rechaza decimales', () {
      expect(validateAmount('100.50').isValid, isFalse);
      expect(validateAmount('100,50').isValid, isFalse);
    });

    test('rechaza montos absurdos', () {
      expect(validateAmount('9999999999999').isValid, isFalse);
    });
  });

  group('validateDescription', () {
    test('opcional y vacío es válido', () {
      expect(validateDescription('').isValid, isTrue);
      expect(validateDescription(null).isValid, isTrue);
    });

    test('máximo 100 caracteres', () {
      expect(validateDescription('a' * 100).isValid, isTrue);
      expect(validateDescription('a' * 101).isValid, isFalse);
    });
  });

  group('validateDate', () {
    test('rechaza futuro', () {
      final now = DateTime(2026, 1, 15);
      expect(validateDate(DateTime(2026, 1, 16), now: now).isValid, isFalse);
    });

    test('acepta hoy', () {
      final now = DateTime(2026, 1, 15, 18, 30);
      expect(validateDate(DateTime(2026, 1, 15), now: now).isValid, isTrue);
    });

    test('acepta pasado', () {
      final now = DateTime(2026, 1, 15);
      expect(validateDate(DateTime(2025, 12, 31), now: now).isValid, isTrue);
    });

    test('rechaza null', () {
      expect(validateDate(null).isValid, isFalse);
    });
  });

  group('validateMovement', () {
    test('exige categoría', () {
      final r = validateMovement(
        amount: '1000',
        description: '',
        date: DateTime(2026, 1, 1),
        categoryId: null,
      );
      expect(r.error, 'Selecciona una categoría');
    });

    test('acepta un movimiento completo válido', () {
      final r = validateMovement(
        amount: '1000',
        description: 'almuerzo',
        date: DateTime(2026, 1, 1),
        categoryId: 1,
      );
      expect(r.isValid, isTrue);
    });
  });
}
```

```dart
// test/domain/currency_formatter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/utils/currency_formatter.dart';

void main() {
  const cop = CurrencyFormatter(CurrencyCode.cop);

  test('formatea miles sin decimales', () {
    expect(cop.format(25000), r'$25.000');
    expect(cop.format(1000000), r'$1.000.000');
  });

  test('usa el valor absoluto', () {
    expect(cop.format(-50000), r'$50.000');
  });

  test('formatSigned distingue ingreso y gasto', () {
    expect(cop.formatSigned(50000), r'+$50.000');
    expect(cop.formatSigned(-50000), r'-$50.000');
  });

  test('usd muestra dos decimales', () {
    const usd = CurrencyFormatter(CurrencyCode.usd, locale: 'en_US');
    expect(usd.format(25), r'$25.00');
  });
}
```

### Paso 2 — Fakes para tests de widget

```dart
// test/helpers/fakes.dart
import 'dart:async';

import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/repositories/movement_repository.dart';
import 'package:pipefinanzaspersonales/features/categories/domain/entities/category.dart';
import 'package:pipefinanzaspersonales/features/categories/domain/repositories/category_repository.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';

/// Repositorio en memoria. Sustituye a Drift en los tests de widget (D14).
class FakeMovementRepository implements MovementRepository {
  FakeMovementRepository([List<Movement>? initial])
      : _items = [...?initial];

  final List<Movement> _items;
  final _controller = StreamController<List<Movement>>.broadcast();

  void _emit() => _controller.add(List.unmodifiable(_items));

  @override
  Stream<List<Movement>> watchAll() => _controller.stream;

  @override
  Stream<List<Movement>> watchByMonth(DateTime month) {
    return _controller.stream.map((all) {
      final start = DateTime(month.year, month.month);
      final end = DateTime(month.year, month.month + 1);
      return all
          .where((m) => !m.date.isBefore(start) && m.date.isBefore(end))
          .toList();
    });
  }

  @override
  Future<List<Movement>> getByMonth(DateTime month) async {
    return await watchByMonth(month).first;
  }

  @override
  Future<Movement?> getById(int id) async =>
      _items.where((m) => m.id == id).firstOrNull;

  @override
  Future<int> create(MovementDraft draft) async {
    final id = _items.isEmpty ? 1 : _items.last.id + 1;
    _items.add(Movement(
      id: id,
      amount: draft.amount,
      type: draft.type,
      category: testCategories.first,
      date: draft.date,
      description: draft.description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    _emit();
    return id;
  }

  @override
  Future<bool> update(int id, MovementDraft draft) async {
    final i = _items.indexWhere((m) => m.id == id);
    if (i < 0) return false;
    _items[i] = _items[i].copyWith(
      amount: draft.amount,
      type: draft.type,
      date: draft.date,
      description: draft.description,
      updatedAt: DateTime.now(),
    );
    _emit();
    return true;
  }

  @override
  Future<void> delete(int id) async {
    _items.removeWhere((m) => m.id == id);
    _emit();
  }
}

class FakeCategoryRepository implements CategoryRepository {
  @override
  Stream<List<Category>> watchAll() => Stream.value(testCategories);

  @override
  Future<List<Category>> getAll() async => testCategories;

  @override
  Future<Category?> getById(int id) async =>
      testCategories.where((c) => c.id == id).firstOrNull;
}

final testCategories = <Category>[
  Category(id: 1, name: 'Alimentación', iconKey: 'restaurant',
      colorValue: 0xFFF97316, type: MovementType.expense, isDefault: true, sortOrder: 1),
  Category(id: 2, name: 'Transporte', iconKey: 'directions_bus',
      colorValue: 0xFF0EA5E9, type: MovementType.expense, isDefault: true, sortOrder: 2),
  Category(id: 11, name: 'Salario', iconKey: 'work',
      colorValue: 0xFF16A34A, type: MovementType.income, isDefault: true, sortOrder: 11),
];
```

El fake expone un getter público para que los tests puedan inspeccionarlo:

```dart
List<Movement> get items => List.unmodifiable(_items);
```

### Paso 3 — Tests de widget

```dart
// test/widget/movement_form_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pipefinanzaspersonales/core/providers/repository_providers.dart';
import 'package:pipefinanzaspersonales/features/movements/domain/entities/movement_type.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/providers/movement_form_controller.dart';
import 'package:pipefinanzaspersonales/features/movements/presentation/screens/movement_form_screen.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeMovementRepository movements;
  late FakeCategoryRepository categories;

  setUp(() {
    movements = FakeMovementRepository();
    categories = FakeCategoryRepository();
  });

  Widget harness() => ProviderScope(
        overrides: [
          movementRepositoryProvider.overrideWithValue(movements),
          categoryRepositoryProvider.overrideWithValue(categories),
        ],
        child: const MaterialApp(home: MovementFormScreen()),
      );

  testWidgets('exige categoría antes de guardar', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '25000');
    await tester.tap(find.text('Guardar'));
    await tester.pump();

    expect(find.text('Selecciona una categoría'), findsOneWidget);
  });

  testWidgets('guarda un movimiento válido', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, '25000');
    await tester.tap(find.text('Transporte'));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(movements.items.length, 1);
    expect(movements.items.first.amount, 25000);
  });

  testWidgets('cambiar de tipo limpia la categoría', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Transporte'));
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MovementFormScreen)),
    );
    expect(container.read(movementFormProvider(null)).categoryId, 2);

    await tester.tap(find.text('Ingreso'));
    await tester.pump();
    expect(container.read(movementFormProvider(null)).categoryId, isNull);
  });
}
```

### Paso 4 — Ejecutar

```bash
flutter test
```

**Debe cumplirse:**
- [ ] `flutter test` termina en verde
- [ ] Cobertura de `financial_calculator.dart` ≥ 90 % en las ramas de negocio
- [ ] `validators_test.dart` cubre los 4 mensajes de error de §15
- [ ] `currency_formatter_test.dart` cubre el separador de miles
- [ ] El nivel 2 (BD real) pasa, o está `skip` con la causa documentada
- [ ] `flutter analyze` sigue en `No issues found!`

**Checkpoint:**
```bash
git add -A
git commit -m "S08: suite de tests de dominio y widgets con fakes"
```

---

<a id="s09--release-android"></a>

## S09 — Release Android

**Objetivo:** cambiar el package ID, generar un APK firmable y cerrar el MVP.
**Dejar para:** nada. Es la última secuencia.

### Paso 1 — Cambiar el package ID (D3)

`android/app/build.gradle.kts`:

```kotlin
android {
    namespace = "com.pipefinanzas.app"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.pipefinanzas.app"
        // ...
    }
}
```

Mover el archivo Kotlin y ajustar el `package`:

```bash
mkdir -p android/app/src/main/kotlin/com/pipefinanzas/app
git mv android/app/src/main/kotlin/com/example/pipefinanzaspersonales/MainActivity.kt \
       android/app/src/main/kotlin/com/pipefinanzas/app/MainActivity.kt
rmdir -p android/app/src/main/kotlin/com/example 2>/dev/null || true
```

```kotlin
// android/app/src/main/kotlin/com/pipefinanzas/app/MainActivity.kt
package com.pipefinanzas.app

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
```

Comprobar que no queda ninguna referencia al paquete antiguo:

```bash
grep -rn "com.example.pipefinanzaspersonales" android/ lib/ 2>/dev/null
```

Debe devolver **cero** resultados.

### Paso 2 — Nombre y versión de la app

```xml
<!-- android/app/src/main/res/values/strings.xml -->
<string name="app_name">Pipe Finanzas</string>
```

```kotlin
// android/app/build.gradle.kts
defaultConfig {
    versionCode = 1          // §31
    versionName = "1.0.0"
}
```

### Paso 3 — Build de release

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Artefacto: `build/app/outputs/flutter-apk/app-release.apk`.

### Paso 4 — Proguard y reglas

Drift y `intl` no requieren reglas específicas. Flutter ya incluye las suyas.
**No añadir reglas especulativas**: si el build falla con R8, leer el error real.

Si apareciera un error de R8, el archivo sería `android/app/proguard-rules.pro`
y el build usaría:

```kotlin
// android/app/build.gradle.kts
buildTypes {
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro",
        )
    }
}
```

**Por qué NO se recomienda por defecto:** `isMinifyEnabled = true` con SQLite
reflexivo puede fallar en runtime y no en build. Se deja en `false` hasta que
haya evidencia de que el tamaño del APK es un problema real.

### Paso 5 — Permisos (§36)

`android/app/src/main/AndroidManifest.xml` debe tener **exactamente** un permiso:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application ...>
        <!-- Sin INTERNET: la app es 100% local (§36) -->
    </application>
</manifest>
```

**Ningún permiso `INTERNET`, `ACCESS_NETWORK_STATE` ni de ubicación.**

> `flutter create` puede no añadir `INTERNET` en release; verificar el manifest
> final del APK, no solo el fuente.

Verificación:

```bash
# Con aapt2 (Android SDK build-tools) o unzip del APK
grep -c "android.permission.INTERNET" build/app/outputs/flutter-apk/app-release.apk
```

### Paso 6 — Prueba de regresión final

```bash
flutter run --release
```

Recorrer el flujo completo del §11:

- [ ] Arranca, muestra el splash y llega al dashboard vacío
- [ ] Registra un gasto → aparece en el dashboard con balance negativo
- [ ] Registra un ingreso mayor → el balance pasa a verde
- [ ] El historial muestra ambos, agrupados por día
- [ ] Edita el gasto, cambia el monto → dashboard e historial se actualizan
- [ ] Elimina el gasto con confirmación → desaparece de ambos
- [ ] Cambia de mes con ‹ › → el mes vacío muestra su estado vacío
- [ ] Cierra y reabre la app → los datos persisten
- [ ] La app funciona con el dispositivo en modo avión

### Comandos de aceptación S09

**Debe cumplirse:**
- [ ] `grep -rn "com.example.pipefinanzaspersonales" android/ lib/` → vacío
- [ ] `flutter build apk --release` → `app-release.apk` generado
- [ ] `flutter test` sigue en verde
- [ ] El APK instalado arranca y el flujo completo funciona
- [ ] Cero permisos de red en el manifest final
- [ ] El icono y el nombre son los de "Pipe Finanzas"
- [ ] `versionCode = 1`, `versionName = "1.0.0"`

**Checkpoint:**
```bash
git add -A
git commit -m "S09: package ID, release Android y verificación de privacidad"
```

---

## 5. Definición de "hecho" (§6)

El MVP está completo cuando **todo** lo siguiente es cierto:

### Funcional
- [ ] Registrar y editar ingresos y gastos con validación completa
- [ ] Eliminar con confirmación
- [ ] Dashboard con balance, ingresos, gastos, desglose y 6 meses
- [ ] Historial agrupado por día con filtro mensual
- [ ] Estados vacíos en las 3 pantallas
- [ ] Los datos persisten tras cerrar la app

### Calidad
- [ ] `flutter analyze` → `No issues found!`
- [ ] `flutter test` → todo en verde
- [ ] Cero hex literales fuera de `AppColors`
- [ ] `domain/` sin imports de Flutter ni Drift
- [ ] `presentation/` sin imports de `drift`
- [ ] Sin TODOs ni `print()` en el código

### Privacidad
- [ ] Cero permisos de red
- [ ] Cero dependencias de red
- [ ] Base de datos solo en almacenamiento local de la app

### Build
- [ ] `flutter build apk --release` funciona
- [ ] Package ID: `com.pipefinanzas.app`
- [ ] Versión: `1.0.0` (versionCode 1)

---

## 6. Notas para OpenCode

### 6.1 Errores ya conocidos de este plan

**Actualizado tras S01.** Las dos dudas que había aquí están resueltas y
documentadas en §S01 — Desviaciones. Si vas a escribir un DAO nuevo, ten en
cuenta:

| Punto | Regla |
|---|---|
| JOIN de Drift | El tipo es `JoinedSelectStatement<HasResultSet, dynamic>`. Se lee con `row.readTable(movements)`. No anularlo con `SimpleSelectStatement<...>`. |
| `attachedDatabase` | No overridearlo. `db` es una extensión que devuelve `attachedDatabase`; overridear con `db` recursiona infinitamente. |
| Tablas en el DAO | Usar los getters `categories` / `movements` del mixin generado, no `db.categories`. |
| `replace` vs `write` | Para editar, `write`. `replace` pisa `createdAt` con una marca nueva. |
| `DateTime` en Drift | Se serializa en **segundos**. Nada de assertions de milisegundo. |
| `FamilyNotifier<State, Arg>` en Riverpod 3.3.2 | Sigue **sin verificar**. Relevant en S04. Si falla, usar `NotifierProvider.autoDispose.family` con un `Notifier` normal leyendo `arg` en `build`. |
| `LinearProgressIndicator` | Espera una **fracción** (0..1), no un porcentaje. |

Además, tres detalles de imports que el analizador marca como `unused_import` si
se copian sin revisar: `history_screen.dart` no usa `validators.dart` y sí
importa `domain/financial_summary.dart` para `DailyGroup`; `date_picker_field.dart`
necesita `core/theme/app_spacing.dart`; `test/helpers/fakes.dart` necesita
`dart:async`.

### 6.2 Reglas para no desviarse

1. **El PRD manda sobre el código.** Si el código contradice al PRD, el bug está
   en el código.
2. **No agregar features.** El §4 del PRD define el alcance. Si una idea parece
   buena pero no está en el PRD, no se implementa en el MVP.
3. **No subir versiones de paquetes** sin `flutter pub add --dry-run` previo.
4. **No bloquear una secuencia** por un test de BD que no arranca en Windows:
   se marca `skip` y se sigue (§33 es el objetivo, no una barrera).
5. **Una secuencia por sesión.** Si algo queda a medias, se anota en el commit
   y no se marca el checkbox.
6. **Nada de `print()` ni `debugPrint()`** en producción. Si hace falta
   diagnosticar, se quita antes del commit.

### 6.3 Orden de lectura de este documento

1. [Sección 0](#0-cómo-usar-este-documento) — protocolo
2. [Sección 2](#2-decisiones-técnicas-cerradas) — decisiones
3. [Sección 3](#3-arquitectura-objetivo) — estructura
4. La secuencia pendiente del [mapa](#4-mapa-de-secuencias)
5. La sección [6.1](#61-errores-ya-conocidos-de-este-plan) de esta misma página

---

## Apéndice — Trazabilidad con el PRD

| Sección PRD | Implementado en |
|---|---|
| §4 Alcance | S00 (estructura mínima) |
| §5 Principios | §3 reglas de dependencia, §6.2 |
| §6 Criterios de aceptación | Sección 5 |
| §7 Signo del monto | S02 `MovementType.sign`, S01 `Movements.amount` |
| §8 Fecha y hora | S04 `DatePickerField`, S01 `Movements.date` |
| §9 Formato de moneda | S02 `CurrencyFormatter` |
| §10 Categorías | S01 seed, S03 UI |
| §11 Pantalla de registro | S04 |
| §12 Pantalla de historial | S05 |
| §13 Dashboard | S06, S07 gráfico |
| §14 Estados vacíos | S07 |
| §15 Validación | S02 `validators.dart`, S04 formulario |
| §16–§21 Tema | S00 `app_theme.dart` |
| §22 Accesibilidad | S00 tokens, S07 punto 4 |
| §23–§24 Onboarding y extras | **Fuera del MVP** |
| §25–§27 Arquitectura | Sección 3, S00 |
| §28–§30 Modelo de datos | S01 |
| §31–§32 Cálculos | S02 |
| §33 Testing | S08 |
| §34–§35 Escalabilidad | S03, S06 |
| §36–§37 Privacidad | S01, S09 |
| §38–§39 Fuera de alcance | No implementado, por diseño |

---

*Fin del plan. Última actualización: 2026-09-25.*




