import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ecommerce/controllers/OrdersController.dart';
import 'package:ecommerce/models/Bill.dart';
import 'package:ecommerce/views/TrackOrderScreen.dart';

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with TickerProviderStateMixin {
  final OrdersController controller = Get.put(OrdersController());

  // متحكم الانيميشن
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // إعداد الانيميشن
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // بدء الانيميشن
    _pulseController.repeat(reverse: true);
    
    // تحديث الطلبات عند فتح الشاشة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchUserOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'طلباتي',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey[800]),
        automaticallyImplyLeading: false, // إخفاء سهم الرجوع
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
            ),
          );
        }

        if (controller.ordersList.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshOrders,
          color: Colors.deepPurple,
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: controller.ordersList.length,
            itemBuilder: (context, index) {
              final order = controller.ordersList[index];
              return _buildOrderCard(order);
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'لا توجد طلبات بعد',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'عندما تقوم بطلب منتجات، ستظهر هنا',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Bill order) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.withOpacity(0.1),
              Colors.deepPurple.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // أيقونة الطلب
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.deepPurple,
                      Colors.deepPurple.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              
              // تفاصيل الطلب
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'طلب #${order.id ?? 'غير محدد'}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      controller.formatDate(order.date),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      controller.formatTime(order.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    // حالة الطلب
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: controller.getStatusColor(order.orderstatus).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: controller.getStatusColor(order.orderstatus).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            controller.getStatusIcon(order.orderstatus),
                            size: 14,
                            color: controller.getStatusColor(order.orderstatus),
                          ),
                          SizedBox(width: 4),
                          Text(
                            order.orderstatus ?? 'جاري التجهيز',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: controller.getStatusColor(order.orderstatus),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // زر تتبع الطلب مع انيميشن (يخفى للطلبات الملغية)
              if (order.orderstatus != 'ملغي')
                _buildTrackOrderButton(order),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackOrderButton(Bill order) {
    return GestureDetector(
      onTap: () => _navigateToTrackOrder(order),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_pulseController.value * 0.05),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple,
                    Colors.deepPurple.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.track_changes,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'تتبع',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _navigateToTrackOrder(Bill order) {
    Get.to(() => TrackOrderScreen(order: order));
  }

  void _showOrderDetails(Bill order) {
    Get.bottomSheet(
      OrderDetailsBottomSheet(order: order, controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class OrderDetailsBottomSheet extends StatelessWidget {
  final Bill order;
  final OrdersController controller;

  OrderDetailsBottomSheet({required this.order, required this.controller});

  @override
  Widget build(BuildContext context) {
    final statusColor = controller.getStatusColor(order.orderstatus);
    final statusIcon = controller.getStatusIcon(order.orderstatus);
    final total = controller.calculateTotal(order);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // مقبض السحب
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // العنوان
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'تفاصيل الطلب',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: Icon(Icons.close),
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
          
          // المحتوى
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // معلومات الطلب الأساسية
                  _buildInfoCard(
                    'معلومات الطلب',
                    [
                      _buildInfoRow('رقم الطلب', '#${order.id ?? 'غير محدد'}'),
                      _buildInfoRow('التاريخ', controller.formatDate(order.date)),
                      _buildInfoRow('الوقت', controller.formatTime(order.date)),
                      _buildInfoRow('الحالة', order.orderstatus ?? 'جاري التجهيز'),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // معلومات العميل
                  _buildInfoCard(
                    'معلومات العميل',
                    [
                      _buildInfoRow('الاسم', order.name ?? 'غير محدد'),
                      _buildInfoRow('الهاتف', order.phone ?? 'غير محدد'),
                      _buildInfoRow('المدينة', order.city ?? 'غير محدد'),
                      if (order.address != null && order.address!.isNotEmpty)
                        _buildInfoRow('العنوان', order.address!),
                      if (order.nearpoint != null && order.nearpoint!.isNotEmpty)
                        _buildInfoRow('النقطة القريبة', order.nearpoint!),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // ملاحظات
                  if (order.note != null && order.note!.isNotEmpty)
                    _buildInfoCard(
                      'ملاحظات',
                      [
                        _buildInfoRow('الملاحظة', order.note!),
                      ],
                    ),
                  
                  SizedBox(height: 16),
                  
                  // تفاصيل المنتجات
                  if (order.items != null && order.items!.isNotEmpty)
                    _buildProductsCard(order.items!),
                  
                  SizedBox(height: 16),
                  
                  // تفاصيل المبلغ
                  _buildInfoCard(
                    'تفاصيل المبلغ',
                    [
                      _buildInfoRow('سعر المنتجات', '${order.price ?? 0} د.ع'),
                      _buildInfoRow('رسوم التوصيل', '${order.delivery ?? 0} د.ع'),
                      Divider(color: Colors.grey[300]),
                      _buildInfoRow(
                        'المبلغ الإجمالي',
                        '${total.toStringAsFixed(0)} د.ع',
                        isTotal: true,
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.blue[600] : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsCard(List<Map<String, dynamic>> items) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تفاصيل المنتجات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 12),
            ...items.map((item) => _buildProductItem(item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
    final productName = item['title'] ?? item['name'] ?? 'منتج غير محدد';
    final quantity = item['count'] ?? item['quantity'] ?? 1;
    final price = item['price'] ?? item['lastprice'] ?? 0;
    final totalPrice = (price * quantity).toDouble();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // صورة المنتج
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: item['image'] != null && item['image'].toString().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item['image'].toString(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.shopping_bag,
                          color: Colors.grey[400],
                          size: 24,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.shopping_bag,
                    color: Colors.grey[400],
                    size: 24,
                  ),
          ),
          SizedBox(width: 12),
          
          // تفاصيل المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'الكمية: $quantity',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 8),
                    if (item['size'] != null && item['size'].toString().isNotEmpty)
                      Text(
                        'الحجم: ${item['size']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // السعر
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${price.toStringAsFixed(0)} د.ع',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '${totalPrice.toStringAsFixed(0)} د.ع',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

