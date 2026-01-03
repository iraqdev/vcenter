class ImageUtils {
  // اسم سلة التخزين (bucket) من إعدادات Firebase
  static const String _bucket = 'v-center-5f74b.firebasestorage.app';

  static String getCorrectImageUrl(
    String currentUrl,
    String type,
    int originalId,
  ) {
    // إذا كان الرابط يبدأ بـ http فاعتبره صالحًا وأعده كما هو
    if (currentUrl.isNotEmpty && currentUrl.startsWith('http')) return currentUrl;

    // إذا كان currentUrl مسارًا داخل التخزين (مثال: products/product_123.jpg)
    if (currentUrl.isNotEmpty && !currentUrl.startsWith('http')) {
      final encodedPath = Uri.encodeComponent(currentUrl);
      return 'https://firebasestorage.googleapis.com/v0/b/$_bucket/o/$encodedPath?alt=media';
    }

    // في حالة عدم توفر رابط أو مسار، نبني رابطًا افتراضيًا وفق نمط موحّد
    final folder = type == 'product'
        ? 'products'
        : (type == 'category'
            ? 'categories'
            : 'sliders');
    final fileName = '${type}_${originalId}.jpg';
    final encoded = Uri.encodeComponent('$folder/$fileName');
    return 'https://firebasestorage.googleapis.com/v0/b/$_bucket/o/$encoded?alt=media';
  }
}
