# DualBase Manager — Dual Database Suite (DBF & MS Access)
### *Advanced Legacy Data Management, Modern Desktop Interface & CRUD Integration*

---

### 🌐 Language Navigation / Navigation par Langue / تصفح اللغات
* 🇬🇧 [English Documentation](#-english)
* 🇫🇷 [Documentation en Français](#-français)
* 🇲🇦 [التوثيق باللغة العربية](#-العربية)

---

## 👨‍💼 Project Credits & Leadership
* **Lead Architect & Project Conception:** **Aymen Hassouna**
* **Role:** **IT Manager**
* **Project Name:** **DualBase Manager**
* **Ecosystem:** Flutter Desktop (Windows), C# .NET Bridge, Dart Binary Engine

---

<a name="-english"></a>
# 🇬🇧 English

## 1. Overview & Business Significance
In many enterprise IT architectures, **GED (Electronic Document Management)** and legacy ERP solutions continue to rely on legacy storage engines:
* **dBase / FoxPro DBF files (`.dbf`):** Often containing critical historical archives with dozens or hundreds of columns, but lacking modern viewers and prone to UI clutter.
* **Microsoft Access (`.accdb` / `.mdb`):** Widely used across departments for operational data, needing reliable Create, Read, Update, and Delete (CRUD) operations without risking file corruption.

**DualBase Manager** bridges the gap between legacy database systems and modern software engineering. It provides an enterprise-ready, desktop application built with Flutter that:
1. **Reads DBF databases reliably** via a custom, zero-dependency pure Dart binary parser optimized for tables with high column counts (30–100+ columns).
2. **Performs full CRUD operations on Microsoft Access databases** through a high-speed native Windows OLEDB/ACE bridge.
3. **Offers a centralized Settings Hub** with file pickers, live connection testing, character encoding selection, and one-click sample database generation.

---

## 2. Architecture & Data Flow Diagrams

### High-Level Architecture Diagram
```
+-----------------------------------------------------------------------------------+
|                         DUALBASE MANAGER - FLUTTER DESKTOP                        |
|                                                                                   |
|   +-----------------------+   +-----------------------+   +-------------------+   |
|   |   📁 DBF VIEWER       |   |   🗄️ ACCESS MANAGER    |   |   ⚙️ SETTINGS     |   |
|   |   - Read-Only         |   |   - Full CRUD (C,R,U,D)   |   |   - File Pickers  |   |
|   |   - 30-100+ Columns   |   |   - Schema Generator      |   |   - Live Ping     |   |
|   |   - Card Inspector    |   |   - Custom SQL Console    |   |   - Encodings     |   |
|   +-----------+-----------+   +-----------+-----------+   +---------+---------+   |
|               |                           |                         |             |
+---------------|---------------------------|-------------------------|-------------+
                |                           |                         |
        (Pure Dart Parser)          (Native OLEDB Bridge)        (SharedPreferences)
                |                           |                         |
                v                           v                         v
     [ 📄 Legacy .DBF File ]     [ 🗃️ MS Access .accdb/.mdb ]   [ 💾 App Settings ]
```

### DBF Column Handling Diagram
```
[ .DBF Table: 30+ Columns ]
       │
       ├──► [ Dual-Axis Scrollable Grid ] ───► Pinned Headers + Alternating Rows
       │
       ├──► [ Column Selector Modal ]    ───► Filter by Name, Toggle Visibility (e.g. 5 of 30)
       │
       ├──► [ Single Record Inspector ]  ───► Card View of all fields + Clipboard Copy
       │
       └──► [ CSV Export Engine ]        ───► Instant Download for reporting
```

### Access CRUD Workflow
```
[ User Interaction ]
       │
       ├─► [ Create ] ──► Form Modal (Auto-detects Types) ──► INSERT INTO [Table]
       ├─► [ Read ]   ──► Filtered Grid + Pagination      ──► SELECT * FROM [Table]
       ├─► [ Update ] ──► Pre-filled Modal + Validation   ──► UPDATE [Table] WHERE [Key]=ID
       ├─► [ Delete ] ──► Confirmation Safety Dialog      ──► DELETE FROM [Table] WHERE [Key]=ID
       └─► [ Custom ] ──► Interactive SQL Terminal        ──► Raw SQL Queries & DDL
```

---

## 3. Key Capabilities

### 📁 DBF Viewer (Read-Only)
* **High Column Count Resilience:** Handles 30 to 100+ columns seamlessly with dual-axis scrolling.
* **Column Visibility Manager:** Select or deselect columns on the fly with live search.
* **Record Detail Inspector:** Click any row to inspect all fields in formatted cards with copy-to-clipboard functionality.
* **Instant Text Search & Pagination:** Search across all visible fields; configurable rows-per-page (10, 25, 50, 100).
* **CSV Export:** Export filtered or visible data directly to `.csv`.

### 🗄️ Microsoft Access Manager (CRUD)
* **Multi-Table Switching:** Auto-discovers user tables (excluding MSys system tables).
* **Schema-Aware Form Generation:** Dynamically creates inputs for Text, Integer, Decimal, Date, and Boolean fields while protecting Auto-Increment and Read-Only keys.
* **Safe Mutations:** Targets records accurately using primary keys.
* **Built-in SQL Console:** Run custom queries and preview instant result sets.

### ⚙️ Settings & Diagnostics
* **Native Windows File Pickers:** Easily browse `.dbf`, `.accdb`, or `.mdb` files.
* **Live Connection Tests:** Validates existence, table schemas, and record counts.
* **Encoding Options:** Supports CP1252 (Windows-1252), UTF-8, and ISO-8859-1.
* **Sample Database Bootstrapper:** Generates realistic 30-column DBF files and sample Access databases with a single click.

---

## 4. Getting Started

### Prerequisites
* Windows 10/11 (64-bit)
* Flutter SDK (3.20+ / 3.29+)
* Microsoft Access Database Engine (ACE OLEDB 12.0 or 16.0)

### Execution
```cmd
# 1. Fetch dependencies
flutter pub get

# 2. Run the application on Windows desktop
flutter run -d windows
```

---
---

<a name="-français"></a>
# 🇫🇷 Français

## 1. Présentation & Importance Stratégique
Dans de nombreux parcs informatiques d'entreprise, les logiciels de **GED (Gestion Électronique des Documents)** et les ERP historiques s'appuient sur des formats de données d'ancienne génération :
* **Fichiers dBase / FoxPro DBF (`.dbf`) :** Riches en métadonnées et colonnes multiples (souvent plus de 30 à 50 colonnes), mais difficiles à explorer sans outils propriétaires lourds.
* **Bases Microsoft Access (`.accdb` / `.mdb`) :** Largement exploitées au quotidien pour la gestion opérationnelle, nécessitant des modifications sécurisées (Création, Lecture, Modification, Suppression).

**DualBase Manager** apporte une solution moderne et robuste développée sous **Flutter Desktop** pour répondre à ces enjeux :
1. **Lecture optimisée des fichiers DBF** grâce à un analyseur binaire natif en Dart pur, capable d'afficher un volume important de colonnes sans ralentissement.
2. **Gestion CRUD complète sur Microsoft Access** via un pont Windows natif OLEDB/ACE rapide et sécurisé.
3. **Paramétrage centralisé** permettant de pointer vers les fichiers, de tester la connexion en direct et de changer l'encodage des caractères.

---

## 2. Architecture & Schémas Explicatifs

### Schéma Global de l'Application
```
+-----------------------------------------------------------------------------------+
|                         DUALBASE MANAGER - FLUTTER DESKTOP                        |
|                                                                                   |
|   +-----------------------+   +-----------------------+   +-------------------+   |
|   |   📁 VISUALISEUR DBF  |   |   🗄️ GESTIONNAIRE     |   |   ⚙️ PARAMÈTRES   |   |
|   |   - Lecture seule     |   |     ACCESS (CRUD)     |   |   - Sélecteurs    |   |
|   |   - 30 à 100+ Colonnes|   |   - Schémas & Tables  |   |   - Tests en direct|  |
|   |   - Fiche Détaillée   |   |   - Console SQL libre |   |   - Encodages     |   |
|   +-----------+-----------+   +-----------+-----------+   +---------+---------+   |
|               |                           |                         |             |
+---------------|---------------------------|-------------------------|-------------+
                |                           |                         |
       (Moteur Binaire Dart)        (Passerelle OLEDB .NET)      (SharedPreferences)
                |                           |                         |
                v                           v                         v
       [ Fichier .DBF ]            [ Base Access .accdb ]       [ Configuration ]
```

### Gestion des Tables DBF à Fort Nombre de Colonnes
```
[ Table DBF : 30+ Colonnes ]
       │
       ├──► [ Grille Défilement 2D ]  ───► En-têtes fixes + Défilement vertical et horizontal fluide
       │
       ├──► [ Sélecteur de Colonnes ] ───► Choix dynamique des colonnes visibles (ex: 5 sur 30)
       │
       ├──► [ Inspecteur de Fiche ]   ───► Affichage vertical en cartes de tous les champs + Copie
       │
       └──► [ Exportateur CSV ]       ───► Export direct pour rapports Excel
```

---

## 3. Fonctionnalités Clés

* **Visualiseur DBF Haute Performance :** Analyse instantanée des types (`C`, `N`, `D`, `L`, `M`), défilement bidirectionnel, masquage/affichage de colonnes à la demande et export CSV.
* **Gestionnaire Access Complet (CRUD) :**
  * **Ajout (Create) :** Formulaires dynamiques respectant les types de données et protégeant les clés auto-incrémentées.
  * **Lecture (Read) :** Pagination fluide, filtres et indicateurs de types.
  * **Modification (Update) :** Boîte de dialogue pré-remplie et mise à jour ciblée par clé primaire.
  * **Suppression (Delete) :** Confirmation sécurisée de suppression.
  * **Console SQL Interactive :** Exécution directe de commandes SQL personnalisées.
* **Menu Paramètres Complet :** Sélecteurs de fichiers Windows, diagnostic d'accès en temps réel, choix des encodages (CP1252, UTF-8, Latin1) et création de bases de démonstration en un clic.

---

## 4. Démarrage Rapide

```cmd
# Télécharger les dépendances
flutter pub get

# Lancer l'application sous Windows
flutter run -d windows
```

---
---

<a name="-العربية"></a>
# 🇲🇦 العربية

## 1. نبذة عن المشروع وأهميته الاستراتيجية
تعتمد العديد من الشركات والمؤسسات على أنظمة أرشيفية قديمة لإدارة الوثائق الإلكترونية (**GED**) وقواعد بيانات legacy:
* **ملفات DBF (dBase / FoxPro):** تحتوي غالبًا على بيانات أرشيفية بالغة الأهمية وبها عدد ضخم من الأعمدة (30 إلى أكثر من 100 عمود)، مما يجعل تصفحها بالبرامج القديمة بطيئاً ومعقداً.
* **قواعد بيانات Microsoft Access (`.accdb` / `.mdb`):** مستخدمة بكثرة في العمليات الإدارية اليومية وتتطلب واجهة حديثة لإجراء كافة عمليات التعديل والإضافة والحذف (**CRUD**) بأمان تام.

يقدم تطبيق **DualBase Manager** حلاً احترافياً مبنياً بتقنية **Flutter Desktop (Windows)** للربط بين الأنظمة القديمة والحديثة:
1. **قراءة ملفات DBF بكفاءة فائقة (للقراءة فقط):** عبر محرك دارت ثنائي فائق السرعة ومصمم للتعامل مع الجداول الضخمة ذات الأعمدة الكثيرة.
2. **إدارة شاملة لقواعد Access (CRUD):** إضافة، تصفح، تعديل، وحذف السجلات باستخدام محرك Windows OLEDB/ACE الأصلي.
3. **مركز إعدادات متكامل:** لتحديد مسارات الملفات، فحص الاتصال التلقائي، واختيار تشفير النصوص، مع إمكانية توليد قواعد بيانات تجريبية بنقرة واحدة.

---

## 2. المخططات الهندسية ومسار البيانات

### مخطط البنية العامة للتطبيق
```
+-----------------------------------------------------------------------------------+
|                         DUALBASE MANAGER - FLUTTER DESKTOP                        |
|                                                                                   |
|   +-----------------------+   +-----------------------+   +-------------------+   |
|   |   📁 عارض ملفات DBF   |   |   🗄️ مدير قواعد ACCESS  |   |   ⚙️ الإعدادات     |   |
|   |   - قراءة فقط         |   |   - تحكم شامل (CRUD)  |   |   - اختيار المسارات|   |
|   |   - يدعم 100+ عمود    |   |   - استنتاج الحقول    |   |   - فحص الاتصال   |   |
|   |   - بطاقة فحص السجل   |   |   - موجه أوامر SQL    |   |   - التشفير        |   |
|   +-----------+-----------+   +-----------+-----------+   +---------+---------+   |
|               |                           |                         |             |
+---------------|---------------------------|-------------------------|-------------+
                |                           |                         |
       (محرك دارت الثنائي)         (جسر Windows OLEDB)            (حفظ الإعدادات)
                |                           |                         |
                v                           v                         v
       [ ملف DBF الأرشيفي ]         [ قاعدة بيانات Access ]        [ إعدادات النظام ]
```

### آلية التعامل مع الأعمدة الكثيرة في DBF
```
[ جدول DBF: أكثر من 30 عموداً ]
       │
       ├──► [ جدول بتمرير أفقي وعمودي ] ───► ثبات العناوين وتمرير سلس للغاية
       │
       ├──► [ نافذة اختيار وتصفية الأعمدة ] ──► إخفاء وإظهار أعمدة مخصصة بسهولة
       │
       ├──► [ عارض السجل التفصيلي ]       ──► بطاقة منسقة لكافة الحقول مع ميزة النسخ
       │
       └──► [ تصدير إلى ملف CSV ]          ──► استخراج فوري للتقارير وجداول Excel
```

---

## 3. المميزات الرئيسية

* **عارض DBF فائق السرعة:** قراءة مباشرة لملفات dBase III/IV و FoxPro، تحكم كامل في الأعمدة المرئية، بحث نصي شامل، وترقيم صفحات مرن (10، 25، 50، 100).
* **إدارة كاملة لقواعد بيانات Access (CRUD):**
  * **إضافة سجل جديد (Create):** نماذج ذكية تدعم النصوص، الأرقام، التواريخ، وخانات الاختيار.
  * **استعراض وتصفح (Read):** جداول بيانات واضحة مع إبراز المفتاح الأساسي.
  * **تعديل السجلات (Update):** واجهة مجهزة بالبيانات الحالية مع حفظ فوري وآمن.
  * **حذف السجلات (Delete):** رسالة تأكيد لحماية البيانات من الحذف غير المقصود.
  * **موجه أوامر SQL:** لتنفيذ الاستعلامات المباشرة وعرض النتائج فورياً.
* **شاشة الإعدادات:** اختيار الملفات بنوافذ Windows الأصلية، فحص حالة الاتصال المباشر، وتحديد ترميز الحروف (CP1252 / UTF-8 / Latin1).

---

## 4. التشغيل والتنصيب

```cmd
# تحميل الحزم والمكتبات
flutter pub get

# تشغيل التطبيق على نظام ويندوز
flutter run -d windows
```

---

## 🎖️ Credits / Crédits / حقوق العمل والقيادة
* **Concept, IT Architecture & Leadership:** **Aymen Hassouna**
* **Title:** **IT Manager**
* **Project:** *DualBase Manager — Dual Database Manager & Enterprise Migration Suite*
