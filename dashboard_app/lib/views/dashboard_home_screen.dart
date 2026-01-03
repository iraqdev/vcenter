import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/user_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/order_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/branch_controller.dart';
import 'users_management_screen.dart';

class DashboardHomeScreen extends StatelessWidget {
  DashboardHomeScreen({super.key});

  final UserController userController = Get.find<UserController>();
  final ProductController productController = Get.find<ProductController>();
  final OrderController orderController = Get.find<OrderController>();
  final NotificationController notificationController = Get.find<NotificationController>();
  final BranchController branchController = Get.find<BranchController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'لوحة التحكم',
                style: TextStyle(fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    branchController.getBranchIcon(branchController.selectedBranch.value),
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(width: 4),
                  Text(
                    branchController.selectedBranch.value,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        )),
        backgroundColor: Get.theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // زر تغيير الفرع
          IconButton(
            onPressed: () => _showBranchSelectionDialog(context),
            icon: Icon(Icons.location_on),
            tooltip: 'تغيير الفرع',
          ),
          // مؤشر المستخدمين الجدد
          Obx(() {
            if (userController.newUsersCount.value > 0) {
              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      userController.clearNewUsersCount();
                      Get.toNamed('/new-users');
                    },
                    icon: Icon(Icons.person_add),
                    tooltip: 'مستخدمين جدد',
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '${userController.newUsersCount.value}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              );
            }
            return SizedBox.shrink();
          }),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              userController.refresh();
              productController.refresh();
              orderController.refresh();
              notificationController.refresh();
            },
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: UsersManagementScreen(), // شاشة المستخدمين كرئيسية
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // رأس القائمة الجانبية
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple,
                  Colors.deepPurple.shade700,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // شعار التطبيق
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.dashboard,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // عنوان التطبيق
                    Text(
                      'لوحة التحكم',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'VCenter',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // قائمة التنقل
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // إدارة المستخدمين (الرئيسية)
                  _buildDrawerItem(
                    icon: Icons.people,
                    title: 'إدارة المستخدمين',
                    subtitle: 'إدارة جميع المستخدمين',
                    isSelected: true,
                    onTap: () {
                      Get.back();
                      Get.offNamed('/');
                    },
                  ),
                  
                  Divider(),
                  
                  // إدارة المنتجات
                  _buildDrawerItem(
                    icon: Icons.inventory_2,
                    title: 'إدارة المنتجات',
                    subtitle: 'إدارة جميع المنتجات',
                    onTap: () {
                      Get.back();
                      Get.toNamed('/products');
                    },
                  ),
                  
                  // إدارة الطلبات
                  _buildDrawerItem(
                    icon: Icons.shopping_cart,
                    title: 'إدارة الطلبات',
                    subtitle: 'إدارة جميع الطلبات',
                    onTap: () {
                      Get.back();
                      Get.toNamed('/orders');
                    },
                  ),
                  
                  // إدارة الإشعارات
                  _buildDrawerItem(
                    icon: Icons.notifications,
                    title: 'إدارة الإشعارات',
                    subtitle: 'إرسال وإدارة الإشعارات',
                    onTap: () {
                      Get.back();
                      Get.toNamed('/notifications');
                    },
                  ),
                  
                  // إدارة العروض الترويجية
                  _buildDrawerItem(
                    icon: Icons.image,
                    title: 'إدارة العروض',
                    subtitle: 'إدارة العروض الترويجية',
                    onTap: () {
                      Get.back();
                      Get.toNamed('/sliders');
                    },
                  ),
                  
                  Divider(),
                  
                  // مراجعة الحسابات الجديدة
                  _buildDrawerItem(
                    icon: Icons.person_add,
                    title: 'الحسابات الجديدة',
                    subtitle: 'مراجعة المستخدمين الجدد',
                    onTap: () {
                      Get.back();
                      Get.toNamed('/new_users');
                    },
                  ),
                  
                  Divider(),
                  
                  // الإحصائيات
                  _buildDrawerItem(
                    icon: Icons.analytics,
                    title: 'الإحصائيات',
                    subtitle: 'إحصائيات شاملة',
                    onTap: () {
                      Get.back();
                      _showStatsDialog();
                    },
                  ),
                  
                  Divider(),
                  
                  // الإعدادات
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'الإعدادات',
                    subtitle: 'إعدادات النظام',
                    onTap: () {
                      Get.back();
                      _showSettingsDialog();
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // معلومات النسخة
          Container(
            padding: EdgeInsets.all(16),
            child: Text(
              'الإصدار 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Colors.deepPurple.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected 
              ? Colors.deepPurple
              : Colors.grey[600],
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.deepPurple : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.deepPurple.withOpacity(0.1),
      onTap: onTap,
    );
  }

  // نافذة الإحصائيات
  void _showStatsDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.8,
            maxWidth: MediaQuery.of(Get.context!).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // العنوان
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.analytics, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'الإحصائيات',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // المحتوى
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
              // إحصائيات المستخدمين
              Obx(() {
                final userStats = userController.userStats;
                return _buildStatsSection(
                  'المستخدمين',
                  [
                    _buildStatItem('إجمالي المستخدمين', '${userStats['total'] ?? 0}', Icons.people),
                    _buildStatItem('المستخدمين النشطين', '${userStats['active'] ?? 0}', Icons.check_circle),
                    _buildStatItem('المستخدمين غير النشطين', '${userStats['inactive'] ?? 0}', Icons.person_off),
                    _buildStatItem('الحسابات الجديدة', '${userStats['new'] ?? 0}', Icons.person_add),
                  ],
                );
              }),
              
              SizedBox(height: 20),
              
              // إحصائيات المنتجات
              Obx(() {
                final productStats = productController.stats;
                return _buildStatsSection(
                  'المنتجات',
                  [
                    _buildStatItem('إجمالي المنتجات', '${productStats['total'] ?? 0}', Icons.inventory_2),
                    _buildStatItem('المنتجات النشطة', '${productStats['active'] ?? 0}', Icons.check_circle),
                    _buildStatItem('نفد المخزون', '${productStats['outOfStock'] ?? 0}', Icons.warning),
                    _buildStatItem('مخزون منخفض', '${productStats['lowStock'] ?? 0}', Icons.info),
                  ],
                );
              }),
              
              SizedBox(height: 20),
              
              // إحصائيات الطلبات
              Obx(() {
                final orderStats = orderController.stats;
                return _buildStatsSection(
                  'الطلبات',
                  [
                    _buildStatItem('إجمالي الطلبات', '${orderStats['total'] ?? 0}', Icons.shopping_cart),
                    _buildStatItem('جاري التجهيز', '${orderStats['preparing'] ?? 0}', Icons.access_time),
                    _buildStatItem('جاري التوصيل', '${orderStats['delivering'] ?? 0}', Icons.delivery_dining),
                    _buildStatItem('تم الاستلام', '${orderStats['delivered'] ?? 0}', Icons.check_circle),
                    _buildStatItem('ملغي', '${orderStats['cancelled'] ?? 0}', Icons.cancel),
                  ],
                );
              }),
              
              SizedBox(height: 20),
              
              // إحصائيات الإشعارات
              Obx(() {
                final notificationStats = notificationController.stats;
                return _buildStatsSection(
                  'الإشعارات',
                  [
                    _buildStatItem('إجمالي الإشعارات', '${notificationStats['total'] ?? 0}', Icons.notifications),
                    _buildStatItem('مرسلة', '${notificationStats['sent'] ?? 0}', Icons.check_circle),
                    _buildStatItem('فاشلة', '${notificationStats['failed'] ?? 0}', Icons.error),
                    _buildStatItem('مجدولة', '${notificationStats['scheduled'] ?? 0}', Icons.schedule),
                    _buildStatItem('مسودة', '${notificationStats['draft'] ?? 0}', Icons.edit),
                  ],
                );
              }),
              
              SizedBox(height: 20),
              
              // إحصائيات مالية
              Obx(() {
                return _buildStatsSection(
                  'الإيرادات',
                  [
                    _buildStatItem('إجمالي الإيرادات', '${orderController.totalRevenue.toStringAsFixed(0)} د.ع', Icons.attach_money),
                    _buildStatItem('متوسط قيمة الطلب', '${orderController.averageOrderValue.toStringAsFixed(0)} د.ع', Icons.trending_up),
                    _buildStatItem('طلبات اليوم', '${orderController.todayOrdersCount}', Icons.today),
                    _buildStatItem('إيرادات اليوم', '${orderController.todayRevenue.toStringAsFixed(0)} د.ع', Icons.monetization_on),
                  ],
                );
              }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Get.theme.primaryColor,
          ),
        ),
        SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Get.theme.primaryColor, size: 20),
          SizedBox(width: 12),
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Get.theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // نافذة الإعدادات
  void _showSettingsDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.6,
            maxWidth: MediaQuery.of(Get.context!).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // العنوان
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'الإعدادات',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // المحتوى
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('الإشعارات'),
              trailing: Switch(value: true, onChanged: (value) {}),
            ),
            ListTile(
              leading: Icon(Icons.dark_mode),
              title: Text('الوضع المظلم'),
              trailing: Switch(value: false, onChanged: (value) {}),
            ),
            ListTile(
              leading: Icon(Icons.language),
              title: Text('اللغة'),
              trailing: Text('العربية'),
            ),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('حول التطبيق'),
              onTap: () {
                Get.back();
                _showAboutDialog();
              },
            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // حوار اختيار الفرع
  void _showBranchSelectionDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.location_on, color: Get.theme.primaryColor),
            SizedBox(width: 10),
            Text('اختر الفرع'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Obx(() => Column(
            mainAxisSize: MainAxisSize.min,
            children: BranchController.branches.map((branch) {
              final isSelected = branchController.selectedBranch.value == branch;
              return Card(
                elevation: isSelected ? 4 : 1,
                color: isSelected ? Get.theme.primaryColor.withOpacity(0.1) : null,
                margin: EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Get.theme.primaryColor 
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      branchController.getBranchIcon(branch),
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  title: Text(
                    branch,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Get.theme.primaryColor : null,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: Get.theme.primaryColor)
                      : null,
                  onTap: () async {
                    await branchController.changeBranch(branch);
                    // إعادة تحميل الطلبات للفرع الجديد
                    await orderController.fetchOrders(branch: branch);
                    Get.back();
                  },
                ),
              );
            }).toList(),
          )),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(Get.context!).size.height * 0.5,
            maxWidth: MediaQuery.of(Get.context!).size.width * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // العنوان
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.white, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'حول التطبيق',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              // المحتوى
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Get.theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.dashboard,
                color: Get.theme.primaryColor,
                size: 40,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'لوحة التحكم - VCenter',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'إصدار 1.0.0',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'تطبيق إدارة شامل للمستخدمين والمنتجات',
              style: TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}