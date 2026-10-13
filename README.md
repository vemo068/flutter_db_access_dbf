# DualBase Manager
### Simple & Modern Business Database Explorer (DBF & Microsoft Access)

---

### Language Navigation / Navigation par Langue / تصفح اللغات
* [English](#english)
* [Français](#francais)
* [العربية](#arabic)

---

## Project Credits & Leadership / Crédits du Projet / بطاقة المشروع
* **English:** Project Leadership & Architecture: **Aymen Hassouna — IT Manager**
* **Français :** Direction du Projet & Conception : **Aymen Hassouna — Responsable Informatique (IT Manager)**
* **العربية:** قيادة وتصميم المشروع: **أيمن حسونة — مدير نظم المعلومات (IT Manager)**

---

<a name="english"></a>
# English

## 1. What is DualBase Manager?
**DualBase Manager** is an easy-to-use desktop program designed for business teams and managers. It allows you to open, search, and update company databases that were created in older systems without needing specialized technical tools.

In many companies, important records (such as document archives, client files, and invoices) are stored in two common formats:
1. **DBF files:** Older archive files that often have a large number of columns (30 to 100+ columns), making them difficult to view on standard screens.
2. **Microsoft Access files (.accdb / .mdb):** Everyday business files used to store active company records.

DualBase Manager brings both types into one clean, modern application.

---

## 2. Why is this Tool Important?
* **No Technical Skills Required:** You do not need to know programming or database languages. Everything works through buttons, search bars, and clear forms.
* **Solves the "Too Many Columns" Problem:** If an archive table has dozens of columns, you can choose to view only the columns you care about and inspect any record in an easy-to-read summary card.
* **Full Arabic Text Support:** Reads and writes Arabic names, addresses, and notes clearly without corrupted symbols or strange characters.
* **Safe and Reliable:** Protects your files from accidental changes or corruption.

---

## 3. How It Works (Simple Overview)

```
[ Your Computer ]
        │
        ├──► DBF Archive File  ───►  [ DBF Screen ]       ──► Search, view columns & export to Excel/CSV
        │
        └──► Access File (.accdb) ──►  [ Access Screen ]    ──► View, add, edit, or delete records
```

---

## 4. What Can You Do in the App?

### 1. View Archive Records (DBF) — Read-Only
* **Scroll Comfortably:** Move left, right, up, and down smoothly.
* **Choose Your Columns:** Open the column selector to hide columns you don't need so you can focus on key information.
* **One-Click Record Summary:** Click on any row to open a clean card displaying all details for that single record.
* **Instant Search:** Type any word or number to find matching rows instantly.
* **Export to Excel / CSV:** Save your filtered records to a spreadsheet file with one click.

```
[ Archive Table (50+ Columns) ]
             │
             ├──► Pick 5 key columns to show on screen
             ├──► Search by client name or document number
             ├──► Click any row to see full record details
             └──► Download as Excel-friendly CSV file
```

### 2. Manage Daily Records (Microsoft Access) — Full Control
* **View Tables:** Automatically lists all tables in your Access file.
* **Add New Records:** Click "Add Record" to open a simple pop-up form.
* **Edit Records:** Click the pencil icon on any row to update values.
* **Delete Records:** Click the trash icon with an automatic safety confirmation before anything is removed.
* **Search & Filter:** Find records quickly across the table.

```
[ Access Database ] ──► [ View Records ] ──► [ Add New ] ──► [ Edit Existing ] ──► [ Safe Delete ]
```

### 3. Settings Screen — Easy File Selection
* Click **Browse** to select your files from your computer, just like attaching a document to an email.
* Test your connection with a single click to ensure the file is ready to use.
* Includes a **Quick Setup** button that loads ready-to-test sample databases immediately.

---

## 5. How to Start the Application
1. Double-click the application icon, or run:
   ```cmd
   flutter run -d windows
   ```
2. Open the **Settings** tab to choose your files, or click **Quick Setup** to test with sample data right away.

---
---

<a name="francais"></a>
# Français

## 1. Qu'est-ce que DualBase Manager ?
**DualBase Manager** est un logiciel de bureau simple et moderne conçu pour les équipes administratives, les gestionnaires et les professionnels. Il permet de consulter, rechercher et mettre à jour facilement les bases de données d'entreprise issues d'anciens systèmes, sans aucune compétence informatique particulière.

Dans de nombreuses entreprises, les données importantes (archives de GED, factures, dossiers clients) se trouvent sous deux formats fréquents :
1. **Les fichiers DBF :** Fichiers d'archives historiques contenant souvent un très grand nombre de colonnes (30 à plus de 100 colonnes), difficiles à lire sur des écrans classiques.
2. **Les fichiers Microsoft Access (.accdb / .mdb) :** Fichiers couramment utilisés pour le suivi des opérations quotidiennes.

DualBase Manager réunit ces deux sources au sein d'une interface unique, fluide et conviviale.

---

## 2. Pourquoi ce logiciel est-il utile ?
* **Accessible à tous :** Aucune connaissance technique ou en programmation n'est requise. Tout se fait par boutons, barres de recherche et formulaires clairs.
* **Adapté aux tableaux larges :** Si un tableau contient des dizaines de colonnes, vous pouvez sélectionner uniquement celles qui vous intéressent ou ouvrir une fiche détaillée pour chaque ligne.
* **Prise en charge complète de la langue arabe :** Affiche et enregistre les noms, adresses et notes en arabe de manière parfaitement lisible, sans caractères déformés.
* **Sécurité des données :** Empêche les suppressions accidentelles grâce à des messages de confirmation.

---

## 3. Schéma Simplifié du Fonctionnement

```
[ Votre Ordinateur ]
        │
        ├──► Fichier d'archive DBF  ───►  [ Écran DBF ]     ──► Rechercher, choisir les colonnes, exporter
        │
        └──► Fichier Access (.accdb) ──►  [ Écran Access ]  ──► Consulter, ajouter, modifier, supprimer
```

---

## 4. Fonctionnalités Principales

### 1. Consultation des Archives (DBF) — Lecture Sécurisée
* **Navigation fluide :** Défilement aisé horizontalement et verticalement.
* **Sélection des colonnes :** Masquez les colonnes secondaires pour vous concentrer sur l'essentiel.
* **Fiche détaillée en un clic :** Cliquez sur une ligne pour voir l'ensemble des informations dans une carte lisible.
* **Recherche instantanée :** Trouvez un dossier en tapant un nom, une référence ou une date.
* **Export CSV :** Téléchargez les données filtrées au format tableur (compatible Excel).

```
[ Tableau DBF volumineux ]
             │
             ├──► Afficher uniquement les colonnes utiles
             ├──► Filtrer par mot-clé
             ├──► Consulter la fiche complète d'une ligne
             └──► Exporter vers Excel
```

### 2. Gestion Quotidienne (Microsoft Access) — Contrôle Total
* **Sélection des tables :** Accédez directement aux tables de votre base.
* **Ajouter une ligne :** Remplissez un formulaire clair adapté à chaque champ (texte, montant, date, case à cocher).
* **Modifier :** Cliquez sur l'icône de crayon pour corriger une information existante.
* **Supprimer :** Cliquez sur l'icône de corbeille avec demande systématique de confirmation.
* **Recherche rapide :** Retrouvez n'importe quelle ligne en quelques secondes.

```
[ Base Access ] ──► [ Consulter ] ──► [ Ajouter ] ──► [ Modifier ] ──► [ Supprimer en sécurité ]
```

### 3. Écran Paramètres — Configuration en toute simplicité
* Bouton **Parcourir** pour choisir vos fichiers sur votre disque dur, aussi simplement que pour joindre un fichier à un e-mail.
* Bouton de **Test de connexion** pour vérifier immédiatement que le fichier est valide.
* Bouton **Configuration Rapide** pour créer et tester des données d'exemple en un seul clic.

---

## 5. Lancement du Logiciel
1. Lancez l'application en double-cliquant sur son icône ou avec la commande :
   ```cmd
   flutter run -d windows
   ```
2. Rendez-vous dans l'onglet **Paramètres** pour sélectionner vos fichiers, ou cliquez sur **Configuration Rapide** pour démarrer immédiatement.

---
---

<a name="arabic"></a>
# العربية

## 1. ما هو برنامج DualBase Manager؟
برنامج **DualBase Manager** هو تطبيق مكتبي سهل وعصري مصمم للمدراء والموظفين في مختلف الأقسام. يتيح لك فتح قواعد بيانات الشركة القديمة، والبحث فيها، وتحديثها بكل سهولة وبدون الحاجة إلى أي خبرة برمجية أو تقنية.

في كثير من المؤسسات، توجد وثائق وسجلات أرشيفية هامة مخزنة في نوعين رئيسيين من الملفات:
1. **ملفات DBF:** ملفات أرشيفية قديمة (مثل أرشيف الوثائق والفواتير)، وغالباً ما تحتوي على عدد كبير جداً من الأعمدة (من 30 إلى أكثر من 100 عمود)، مما يجعل قراءتها في البرامج العادية أمراً صعباً.
2. **ملفات Microsoft Access (.accdb / .mdb):** ملفات إدارة الأعمال اليومية الشائعة.

يقوم برنامج DualBase Manager بجمع كلا النوعين في شاشة واحدة واضحة وحديثة.

---

## 2. ما أهمية هذا البرنامج لعملك؟
* **سهل الاستخدام للجميع:** لا تحتاج إلى معرفة أي لغة برمجية؛ كل العمليات تتم عبر أزرار واضحة، وخانات بحث، ونوافذ إدخال بسيطة.
* **حل مشكلة الجداول العريضة والأعمدة الكثيرة:** إذا كان الجدول يحتوي على عشرات الأعمدة، يمكنك اختيار الأعمدة المهمة فقط لعرضها، أو فتح بطاقة تفصيلية تقرأ لك بيانات السطر بالكامل بضغطة زر.
* **دعم كامل للغة العربية:** يعرض ويحفظ النصوص العربية (الأسماء، الأقسام، الملاحظات) بدقة تامة وبدون أي رموز مشوهة أو أحرف غير مفهومة.
* **حماية وأمان البيانات:** يضمن عدم حذف أي سجل بالخطأ من خلال طلب تأكيد قبل أي عملية حذف.

---

## 3. كيف يعمل البرنامج؟ (مخطط مبسط)

```
[ جهاز الكمبيوتر ]
        │
        ├──► ملف الأرشيف (DBF)       ───►  [ شاشة عارض الأرشيف ]  ──► بحث، اختيار الأعمدة، وتصدير لإكسيل
        │
        └──► ملف أكسس (Access DB)    ───►  [ شاشة إدارة أكسس ]    ──► استعراض، إضافة، تعديل، وحذف السجلات
```

---

## 4. ماذا يمكنك أن تفعل داخل البرنامج؟

### 1. استعراض الأرشيف (DBF) — قراءة آمنة
* **تمرير مريح:** تحرك أفقياً وعمودياً في الجدول بكل مرونة وبدون بطء.
* **اختيار الأعمدة المفضلة:** يمكنك إخفاء الأعمدة غير المهمة مؤقتاً لتسهيل قراءة الجدول.
* **بطاقة السجل الشاملة:** اضغط على أي سطر لعرض جميع بياناته في بطاقة منظمة مع إمكانية نسخ أي معلومة.
* **بحث فوري:** ابحث عن أي اسم، رقم وثيقة، أو تاريخ وسيعرض لك البرنامج النتائج فوراً.
* **تصدير إلى Excel / CSV:** استخرج السجلات المعروضة في ملف إكسيل بضغطة زر واحدة.

```
[ جدول أرشيف عريض (أكثر من 50 عموداً) ]
                    │
                    ├──► إظهار 5 أعمدة رئيسية فقط للتركيز
                    ├──► البحث الفوري عن أي عميل أو وثيقة
                    ├──► فتح بطاقة تفصيلية للسجل بالكامل
                    └──► تنزيل البيانات في ملف إكسيل
```

### 2. إدارة البيانات اليومية (Microsoft Access) — تحكم كامل
* **التنقل بين الجداول:** يعرض البرنامج جميع جداول ملف أكسس تلقائياً.
* **إضافة سجل جديد:** اضغط على زر "إضافة سجل" لتفتح لك نافذة إدخال سهلة ومرتبة.
* **تعديل السجلات:** اضغط على رمز القلم بجانب أي سطر لتعديل البيانات وحفظها فوراً.
* **حذف السجلات بأمان:** اضغط على رمز سلة المحذوفات مع نافذة تأكيد لحمايتك من الحذف غير المقصود.
* **بحث وتصفية سريعة:** الوصول إلى أي معلومة في ثوانٍ معدودة.

```
[ قاعدة بيانات أكسس ] ──► [ استعراض ] ──► [ إضافة جديد ] ──► [ تعديل سطر ] ──► [ حذف آمن ]
```

### 3. شاشة الإعدادات — تحديد الملفات بسهولة
* اضغط على زر **استعراض (Browse)** لاختيار ملفاتك من جهازك بنفس طريقة إرفاق ملف في البريد الإلكتروني.
* زر **فحص الاتصال** للتأكد فوراً من أن الملف يعمل وبحالة جيدة.
* زر **الإعداد السريع** لتوليد ملفات تجريبية واستكشاف البرنامج في لحظات.

---

## 5. طريقة تشغيل البرنامج
1. شغل البرنامج بالنقر المزدوج على أيقونة التطبيق، أو عبر الأمر:
   ```cmd
   flutter run -d windows
   ```
2. توجه إلى قائمة **الإعدادات** لاختيار ملفاتك، أو اضغط على **الإعداد السريع** للبدء مباشرة ببيانات تجريبية.

---

## بطاقة المشروع وفريق القيادة / Project Credits
* **English:** Project Leadership & Architecture: **Aymen Hassouna — IT Manager**
* **Français :** Direction du Projet & Conception : **Aymen Hassouna — Responsable Informatique (IT Manager)**
* **العربية:** قيادة وتصميم المشروع: **أيمن حسونة — مدير نظم المعلومات (IT Manager)**
