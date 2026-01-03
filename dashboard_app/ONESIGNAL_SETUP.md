# إعداد OneSignal للإشعارات

## الخطوات المطلوبة لإعداد OneSignal

### 1. الحصول على مفتاح API من OneSignal

1. اذهب إلى [OneSignal Dashboard](https://app.onesignal.com/)
2. اختر التطبيق الخاص بك
3. اذهب إلى **Settings** > **Keys & IDs**
4. انسخ **REST API Key**

### 2. تحديث مفتاح API في الكود

افتح ملف `dashboard_app/lib/services/notification_service.dart` وحدّث السطر التالي:

```dart
// استبدل هذا السطر
static const String _oneSignalApiKey = 'YOUR_ONESIGNAL_REST_API_KEY';

// بهذا (ضع مفتاح API الحقيقي)
static const String _oneSignalApiKey = 'YOUR_ACTUAL_REST_API_KEY_HERE';
```

### 3. إعداد Firebase للمستخدمين

تأكد من أن كل مستخدم في Firebase يحتوي على `playerId`:

```javascript
// في Firebase Firestore، كل مستخدم يجب أن يحتوي على:
{
  "name": "اسم المستخدم",
  "phone": "رقم الهاتف",
  "playerId": "player_id_from_onesignal", // هذا مهم جداً
  "isActive": true,
  // ... باقي البيانات
}
```

### 4. إعداد OneSignal في التطبيق الرئيسي

في التطبيق الرئيسي (`akelapp`)، تأكد من:

1. **تهيئة OneSignal** في `main.dart`:
```dart
OneSignal.initialize('806c1a69-cd15-41b1-8f83-d8a8b3f218f6');
```

2. **حفظ playerId** عند تسجيل الدخول:
```dart
// في ProfileController أو أي مكان مناسب
OneSignal.User.addTag("phone", userPhone);
OneSignal.User.addTag("user_id", userId);

// الحصول على playerId وحفظه في Firebase
OneSignal.User.pushSubscription.addObserver((state) {
  if (state.current.jsonRepresentation()['id'] != null) {
    String playerId = state.current.jsonRepresentation()['id'];
    // حفظ playerId في Firebase للمستخدم الحالي
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .update({'playerId': playerId});
  }
});
```

### 5. أنواع الإشعارات المدعومة

#### أ) إشعار لجميع المستخدمين
- يرسل لجميع المستخدمين النشطين
- يتطلب `playerId` صالح لكل مستخدم

#### ب) إشعار لمستخدم محدد
- يرسل لمستخدم واحد فقط
- يتطلب رقم الهاتف الصحيح

#### ج) إشعارات ترويجية
- عروض خاصة
- ترويج للمنتجات
- يمكن إرسالها لجميع المستخدمين أو مستخدم محدد

### 6. ميزات الإشعارات

- **عنوان ورسالة** مخصصة
- **صورة** اختيارية
- **رابط عمل** (Deep Link)
- **بيانات إضافية** (Custom Data)
- **تتبع الإحصائيات** (عدد المرسل/الفاشل)
- **حفظ سجل** في Firebase

### 7. استكشاف الأخطاء

#### مشكلة: الإشعارات لا تصل
- تأكد من صحة `playerId` في Firebase
- تأكد من صحة مفتاح API
- تأكد من أن المستخدم نشط (`isActive: true`)

#### مشكلة: خطأ في API
- تحقق من صحة مفتاح REST API
- تأكد من أن التطبيق مسجل في OneSignal
- تحقق من صحة App ID

### 8. اختبار الإشعارات

1. **اختبار إرسال لجميع المستخدمين:**
   - اذهب إلى شاشة الإشعارات
   - اضغط "إرسال إشعار"
   - اختر "جميع المستخدمين"
   - أدخل العنوان والرسالة
   - اضغط "إرسال"

2. **اختبار إرسال لمستخدم محدد:**
   - اختر "مستخدم محدد"
   - أدخل رقم الهاتف
   - أدخل العنوان والرسالة
   - اضغط "إرسال"

### 9. مراقبة الإحصائيات

- **إجمالي الإشعارات:** عدد الإشعارات المرسلة
- **مرسلة:** الإشعارات التي تم إرسالها بنجاح
- **فاشلة:** الإشعارات التي فشل إرسالها
- **مجدولة:** الإشعارات المجدولة للمستقبل
- **مسودة:** الإشعارات المحفوظة كمسودة

### 10. نصائح مهمة

1. **احتفظ بنسخة احتياطية** من مفتاح API
2. **اختبر الإشعارات** قبل الإرسال للمستخدمين
3. **راقب الإحصائيات** بانتظام
4. **تأكد من صحة البيانات** قبل الإرسال
5. **استخدم العروض بحكمة** لتجنب إزعاج المستخدمين

---

## ملاحظة مهمة

هذا النظام يتطلب إعداد صحيح لـ OneSignal و Firebase. تأكد من اتباع جميع الخطوات بعناية للحصول على أفضل النتائج.
