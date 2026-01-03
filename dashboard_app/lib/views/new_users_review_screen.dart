import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/user_controller.dart';
import '../models/user_model.dart';
import '../widgets/new_user_card.dart';

class NewUsersReviewScreen extends StatelessWidget {
  NewUsersReviewScreen({super.key});

  final UserController userController = Get.find<UserController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'مراجعة الحسابات الجديدة',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () => userController.loadNewUsers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // معلومات الحسابات الجديدة
          _buildNewUsersInfo(),
          
          // قائمة الحسابات الجديدة
          Expanded(
            child: Obx(() {
              if (userController.isLoadingNewUsers.value) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.orange,
                  ),
                );
              }

              if (userController.newUsers.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () => userController.loadNewUsers(),
                color: Colors.orange,
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: userController.newUsers.length,
                  itemBuilder: (context, index) {
                    final user = userController.newUsers[index];
                    return NewUserCard(
                      user: user,
                      onApprove: () => _approveUser(user),
                      onReject: () => _rejectUser(user),
                      onViewDetails: () => _viewUserDetails(user),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNewUsersInfo() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange, Colors.orange.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.new_releases, color: Colors.white, size: 30),
              SizedBox(width: 10),
              Text(
                'الحسابات الجديدة تحتاج مراجعة',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'عدد الحسابات',
                  '${userController.newUsers.length}',
                  Icons.people,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'في انتظار المراجعة',
                  '${userController.newUsers.length}',
                  Icons.schedule,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'يرجى مراجعة كل حساب جديد قبل الموافقة عليه',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 80,
              color: Colors.green,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'لا توجد حسابات جديدة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'جميع الحسابات تمت مراجعتها',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => userController.loadNewUsers(),
            icon: Icon(Icons.refresh),
            label: Text('تحديث'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _approveUser(UserModel user) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('الموافقة على الحساب'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من الموافقة على حساب:'),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الاسم: ${user.name}'),
                  Text('الهاتف: ${user.phone}'),
                  Text('المدينة: ${user.city}'),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text('سيتم تفعيل الحساب وإزالته من قائمة المراجعة.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              userController.markAsReviewed(user.id);
              userController.updateUserStatus(user.id, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('موافقة'),
          ),
        ],
      ),
    );
  }

  void _rejectUser(UserModel user) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 10),
            Text('رفض الحساب'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('هل أنت متأكد من رفض حساب:'),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الاسم: ${user.name}'),
                  Text('الهاتف: ${user.phone}'),
                  Text('المدينة: ${user.city}'),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text('سيتم حظر الحساب وإزالته من قائمة المراجعة.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              userController.markAsReviewed(user.id);
              userController.updateUserStatus(user.id, false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('رفض'),
          ),
        ],
      ),
    );
  }

  void _viewUserDetails(UserModel user) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text('تفاصيل المستخدم'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('الاسم', user.name),
              _buildDetailRow('الهاتف', user.phone),
              _buildDetailRow('المدينة', user.city),
              _buildDetailRow('العنوان', user.address),
              _buildDetailRow('المنطقة القريبة', user.near),
              _buildDetailRow('النقاط', '${user.points}'),
              _buildDetailRow('تاريخ التسجيل', 
                '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
              if (user.shopLocation != null) ...[
                _buildDetailRow('موقع المحل', 
                  '${user.shopLocation!['lat']?.toStringAsFixed(6)}, ${user.shopLocation!['lng']?.toStringAsFixed(6)}'),
                SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openLocationOnMaps(user),
                    icon: Icon(Icons.location_on),
                    label: Text('عرض على خرائط جوجل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // فتح الموقع على خرائط جوجل
  Future<void> _openLocationOnMaps(UserModel user) async {
    if (user.shopLocation == null) return;
    
    final lat = user.shopLocation!['lat'];
    final lng = user.shopLocation!['lng'];
    
    if (lat == null || lng == null) return;
    
    // عرض خيارات الخرائط للمستخدم
    _showMapOptionsDialog(lat, lng);
  }

  void _showMapOptionsDialog(double lat, double lng) {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.location_on, color: Colors.blue),
              SizedBox(width: 8),
              Text('اختر تطبيق الخرائط'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'اختر التطبيق الذي تريد فتح الموقع به:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              
              // زر خرائط جوجل
              _buildMapOptionButton(
                title: 'خرائط جوجل',
                subtitle: 'Google Maps',
                icon: Icons.map,
                color: Colors.blue,
                onTap: () {
                  Get.back();
                  _openGoogleMaps(lat, lng);
                },
              ),
              
              SizedBox(height: 12),
              
              // زر خرائط آبل
              _buildMapOptionButton(
                title: 'خرائط آبل',
                subtitle: 'Apple Maps',
                icon: Icons.location_on,
                color: Colors.green,
                onTap: () {
                  Get.back();
                  _openAppleMaps(lat, lng);
                },
              ),
              
              SizedBox(height: 12),
              
              // زر Waze
              _buildMapOptionButton(
                title: 'Waze',
                subtitle: 'ملاحة واتجاهات',
                icon: Icons.navigation,
                color: Colors.purple,
                onTap: () {
                  Get.back();
                  _openWaze(lat, lng);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: Text('إلغاء'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMapOptionButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _openGoogleMaps(double lat, double lng) async {
    try {
      // محاولة فتح تطبيق خرائط جوجل مباشرة
      final googleMapsAppUrl = 'comgooglemaps://?q=$lat,$lng&center=$lat,$lng&zoom=14';
      final googleMapsWebUrl = 'https://www.google.com/maps?q=$lat,$lng';
      
      print('🗺️ محاولة فتح خرائط جوجل للموقع: $lat, $lng');
      
      // محاولة فتح التطبيق أولاً
      if (await canLaunchUrl(Uri.parse(googleMapsAppUrl))) {
        print('✅ فتح تطبيق خرائط جوجل');
        await launchUrl(Uri.parse(googleMapsAppUrl));
      } else if (await canLaunchUrl(Uri.parse(googleMapsWebUrl))) {
        print('✅ فتح خرائط جوجل في المتصفح');
        await launchUrl(
          Uri.parse(googleMapsWebUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('لا يمكن فتح خرائط جوجل');
      }
    } catch (e) {
      print('❌ خطأ في فتح خرائط جوجل: $e');
      Get.snackbar('خطأ', 'لا يمكن فتح خرائط جوجل: ${e.toString()}');
    }
  }

  Future<void> _openAppleMaps(double lat, double lng) async {
    try {
      // محاولة فتح تطبيق خرائط آبل مباشرة
      final appleMapsAppUrl = 'maps://?q=$lat,$lng';
      final appleMapsWebUrl = 'https://maps.apple.com/?q=$lat,$lng';
      
      print('🍎 محاولة فتح خرائط آبل للموقع: $lat, $lng');
      
      // محاولة فتح التطبيق أولاً
      if (await canLaunchUrl(Uri.parse(appleMapsAppUrl))) {
        print('✅ فتح تطبيق خرائط آبل');
        await launchUrl(Uri.parse(appleMapsAppUrl));
      } else if (await canLaunchUrl(Uri.parse(appleMapsWebUrl))) {
        print('✅ فتح خرائط آبل في المتصفح');
        await launchUrl(
          Uri.parse(appleMapsWebUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('لا يمكن فتح خرائط آبل');
      }
    } catch (e) {
      print('❌ خطأ في فتح خرائط آبل: $e');
      Get.snackbar('خطأ', 'لا يمكن فتح خرائط آبل: ${e.toString()}');
    }
  }

  Future<void> _openWaze(double lat, double lng) async {
    try {
      // رابط Waze للتطبيق
      final wazeAppUrl = 'waze://?ll=$lat,$lng&navigate=yes';
      // رابط Waze للويب كبديل
      final wazeWebUrl = 'https://waze.com/ul?ll=$lat,$lng&navigate=yes';
      
      print('🚗 محاولة فتح Waze للموقع: $lat, $lng');
      
      // محاولة فتح تطبيق Waze أولاً
      if (await canLaunchUrl(Uri.parse(wazeAppUrl))) {
        print('✅ فتح تطبيق Waze');
        await launchUrl(Uri.parse(wazeAppUrl));
      } else if (await canLaunchUrl(Uri.parse(wazeWebUrl))) {
        print('✅ فتح Waze في المتصفح');
        // إذا فشل التطبيق، افتح الموقع
        await launchUrl(
          Uri.parse(wazeWebUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('لا يمكن فتح Waze');
      }
    } catch (e) {
      print('❌ خطأ في فتح Waze: $e');
      Get.snackbar('خطأ', 'لا يمكن فتح Waze: ${e.toString()}');
    }
  }
}
