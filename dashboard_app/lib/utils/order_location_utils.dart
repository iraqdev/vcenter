/// تنسيق عرض المحافظة والمنطقة في الداشبورد.
/// بغداد: «بغداد — المنطقة» | غيرها: اسم المحافظة فقط.
String formatOrderLocation(String city, String address) {
  final governorate = city.trim();
  final area = address.trim();

  if (governorate.isEmpty && area.isEmpty) return '';

  if (governorate == 'بغداد') {
    if (area.isNotEmpty && area != governorate) {
      return 'بغداد — $area';
    }
    return 'بغداد';
  }

  if (governorate.isNotEmpty) return governorate;
  return area;
}
