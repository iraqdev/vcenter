import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class BranchCalculatorTest {
  // إحداثيات الفروع
  static final LatLng _adhamya = LatLng(33.36961, 44.36373); // الاعظمية
  static final LatLng _algazaly = LatLng(33.344803, 44.280755); // الغزالية
  static final LatLng _zafrania = LatLng(33.26082, 44.49870); // الزعفرانية

  // دالة لحساب المسافة بين نقطتين باستخدام صيغة Haversine
  static double calculateDistanceBetweenPoints(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // نصف قطر الأرض بالمتر
    
    double lat1Rad = point1.latitude * (3.14159265359 / 180);
    double lat2Rad = point2.latitude * (3.14159265359 / 180);
    double deltaLatRad = (point2.latitude - point1.latitude) * (3.14159265359 / 180);
    double deltaLngRad = (point2.longitude - point1.longitude) * (3.14159265359 / 180);

    double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    double c = 2 * asin(sqrt(a));

    return earthRadius * c; // المسافة بالمتر
  }

  // دالة لتحديد أقرب فرع للموقع المختار
  static String findClosestBranch(LatLng userLocation) {
    Map<String, LatLng> branches = {
      'الاعظمية': _adhamya,
      'الغزالية': _algazaly,
      'الزعفرانية': _zafrania,
    };

    String closestBranch = '';
    double minDistance = double.infinity;

    branches.forEach((branchName, branchLocation) {
      double distance = calculateDistanceBetweenPoints(userLocation, branchLocation);
      print('المسافة إلى $branchName: ${(distance / 1000).toStringAsFixed(2)} كم');
      
      if (distance < minDistance) {
        minDistance = distance;
        closestBranch = branchName;
      }
    });

    print('أقرب فرع: $closestBranch - المسافة: ${(minDistance / 1000).toStringAsFixed(2)} كم');
    return closestBranch;
  }

  // دالة لاختبار النظام مع مواقع مختلفة
  static void testBranchCalculation() {
    print('🧪 اختبار نظام حساب أقرب فرع...\n');

    // مواقع اختبار مختلفة
    List<Map<String, dynamic>> testLocations = [
      {
        'name': 'جامعة بغداد - الجادرية',
        'location': LatLng(33.3100, 44.3661),
        'expectedBranch': 'الاعظمية'
      },
      {
        'name': 'مطار بغداد الدولي',
        'location': LatLng(33.2625, 44.2344),
        'expectedBranch': 'الغزالية'
      },
      {
        'name': 'مدينة الصدر',
        'location': LatLng(33.3500, 44.4500),
        'expectedBranch': 'الاعظمية'
      },
      {
        'name': 'الكرادة',
        'location': LatLng(33.3000, 44.4000),
        'expectedBranch': 'الزعفرانية'
      },
      {
        'name': 'المنصور',
        'location': LatLng(33.3200, 44.3500),
        'expectedBranch': 'الاعظمية'
      },
    ];

    for (var test in testLocations) {
      print('📍 اختبار موقع: ${test['name']}');
      print('   الإحداثيات: ${test['location'].latitude}, ${test['location'].longitude}');
      
      String result = findClosestBranch(test['location']);
      String expected = test['expectedBranch'];
      
      if (result == expected) {
        print('   ✅ النتيجة صحيحة: $result');
      } else {
        print('   ❌ النتيجة خاطئة: $result (متوقع: $expected)');
      }
      print('');
    }
  }

  // دالة لعرض معلومات الفروع
  static void displayBranchInfo() {
    print('🏢 معلومات الفروع:');
    print('الاعظمية: ${_adhamya.latitude}, ${_adhamya.longitude}');
    print('الغزالية: ${_algazaly.latitude}, ${_algazaly.longitude}');
    print('الزعفرانية: ${_zafrania.latitude}, ${_zafrania.longitude}');
    print('');
  }
}
