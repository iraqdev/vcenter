import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:ecommerce/controllers/Cart_controller.dart';
import 'package:ecommerce/controllers/Favorite_controller.dart';
import 'package:ecommerce/controllers/Product_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../utils/whatsapp_helper.dart';

class ProductPage extends StatefulWidget {
  ProductPage({super.key});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final Product_controller controller = Get.find();
  final Cart_controller cart_controller = Get.put(Cart_controller());
  final Favorite_controller fav_controller = Get.put(Favorite_controller());
  final RxBool isDescriptionExpanded = false.obs;
  final RxString userBranch = ''.obs;

  @override
  void initState() {
    super.initState();
    _getUserBranch();
  }

  // الحصول على الفرع الأقرب للمستخدم
  Future<void> _getUserBranch() async {
    try {
      final phone = sharedPreferences?.getString('phone');
      print('🔍 ProductPage - البحث عن فرع المستخدم برقم الهاتف: $phone');
      
      if (phone == null) {
        print('⚠️ ProductPage - رقم الهاتف غير موجود في SharedPreferences');
        return;
      }

      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      print('📊 ProductPage - عدد المستخدمين المطابقين: ${usersSnapshot.docs.length}');

      if (usersSnapshot.docs.isNotEmpty) {
        final userData = usersSnapshot.docs.first.data();
        final closestBranch = userData['closestBranch'] ?? '';
        userBranch.value = closestBranch;
        print('✅ ProductPage - فرع المستخدم: "$closestBranch"');
      } else {
        print('❌ ProductPage - المستخدم غير موجود في قاعدة البيانات');
      }
    } catch (e) {
      print('❌ ProductPage - خطأ في الحصول على فرع المستخدم: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: GetBuilder<Product_controller>(
          builder: (c) {
            if (c.isLoadingItem.value) {
              return _buildLoadingScreen();
            } else {
              if (c.productItemList.isNotEmpty) {
                return _buildProductContent();
              } else {
                return _buildEmptyState();
              }
            }
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.deepPurple,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.deepPurple.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        ),
        onPressed: () => Get.back(),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 16),
          child: InkWell(
            onTap: openWhatsapp,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: FaIcon(
                FontAwesomeIcons.whatsapp,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
      title: GetBuilder<Product_controller>(
        builder: (c) {
          if (c.isLoadingItem.value) {
            return Text('');
          } else {
            if (c.productItemList.isNotEmpty) {
              return _buildTitle();
            } else {
              return Text('');
            }
          }
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingAnimationWidget.staggeredDotsWave(
            color: Colors.deepPurple,
            size: 60,
          ),
          SizedBox(height: 20),
          Text(
            'جاري تحميل المنتج...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
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
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 20),
          Text(
            '20'.tr,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductContent() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // صورة المنتج
          SliverToBoxAdapter(child: _buildProductImages()),

          // معلومات المنتج
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان المنتج
                  _buildProductTitle(),
                  SizedBox(height: 12),

                  // رسالة الفرع (إذا وجدت)
                  Obx(() => _buildBranchMessage()),
                  SizedBox(height: 12),

                  // السعر
                  _buildProductPrice(),
                  SizedBox(height: 16),

                  // الوصف
                  _buildProductDescription(),
                  SizedBox(height: 24),

                  // عداد الكمية
                  _buildQuantityCounter(),
                  SizedBox(height: 24),

                  // زر الإضافة للسلة
                  _buildAddToCartButton(),
                ],
              ),
            ),
          ),

          // مساحة إضافية
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildProductImages() {
    return Container(
      height: Get.height * 0.4,
      child: Stack(
        children: [
          // صورة المنتج الرئيسية
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.grey[50]!, Colors.white],
              ),
            ),
            child: CarouselSlider(
              options: CarouselOptions(
                autoPlay: true,
                viewportFraction: 1,
                height: Get.height * 0.4,
                enlargeCenterPage: true,
                onPageChanged: (index, reason) {
                  controller.changeindex(index);
                },
              ),
              items:
                  controller.productItemList[0].images.map((item) {
                    return Container(
                      margin: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: item,
                              fit: BoxFit.contain,
                              placeholder:
                                  (context, url) => Container(
                                    color: Colors.grey[200],
                                    child: Center(
                                      child:
                                          LoadingAnimationWidget.staggeredDotsWave(
                                            color: Colors.deepPurple,
                                            size: 40,
                                          ),
                                    ),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    color: Colors.grey[200],
                                    child: Icon(
                                      Icons.error_outline,
                                      color: Colors.grey[400],
                                      size: 50,
                                    ),
                                  ),
                            ),
                            // زر التحميل
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.download_rounded,
                                    color: Colors.deepPurple,
                                  ),
                                  onPressed:
                                      () => controller.saveNetworkImage(item),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),

          // مؤشر الصور
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: GetBuilder<Product_controller>(
              builder: (c) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    controller.productItemList[0].images.length,
                    (index) => Container(
                      margin: EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            c.index == index
                                ? Colors.deepPurple
                                : Colors.grey[300],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchMessage() {
    if (controller.productItemList.isEmpty) {
      print('🔍 ProductPage - لا توجد منتجات في القائمة');
      return SizedBox.shrink();
    }
    
    final product = controller.productItemList[0];
    final branch = userBranch.value;
    
    print('🔍 ProductPage - فحص الرسالة:');
    print('   - اسم المنتج: ${product.title}');
    print('   - فرع المستخدم: "$branch"');
    print('   - رسائل المنتج: ${product.branchMessages}');
    print('   - هل يوجد رسالة للفرع: ${product.hasBranchMessage(branch)}');
    
    if (branch.isEmpty) {
      print('⚠️ ProductPage - فرع المستخدم فارغ');
      return SizedBox.shrink();
    }
    
    if (!product.hasBranchMessage(branch)) {
      print('⚠️ ProductPage - لا توجد رسالة للفرع "$branch"');
      return SizedBox.shrink();
    }
    
    final message = product.getBranchMessage(branch);
    if (message == null || message.isEmpty) {
      print('⚠️ ProductPage - الرسالة فارغة للفرع "$branch"');
      return SizedBox.shrink();
    }
    
    print('✅ ProductPage - عرض الرسالة: "$message" للفرع "$branch"');
    
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange[600],
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTitle() {
    return Text(
      controller.productItemList[0].title,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        height: 1.3,
      ),
    );
  }

  Widget _buildProductPrice() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.deepPurple.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Text(
        '${(sharedPreferences?.getInt('active') == 1) ? formatter.format(controller.productItemList[0].price) + ' ' + '18'.tr : '...'}',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProductDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الوصف',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.productItemList[0].description,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: isDescriptionExpanded.value ? null : 3,
                overflow:
                    isDescriptionExpanded.value ? null : TextOverflow.ellipsis,
              ),
              if (controller.productItemList[0].description.length > 100)
                GestureDetector(
                  onTap: () {
                    isDescriptionExpanded.value = !isDescriptionExpanded.value;
                  },
                  child: Container(
                    margin: EdgeInsets.only(top: 8),
                    child: Text(
                      isDescriptionExpanded.value ? 'عرض أقل' : 'عرض المزيد',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityCounter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الكمية',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        GetBuilder<Product_controller>(
          builder: (c) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, color: Colors.deepPurple),
                    onPressed: controller.outCounter,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      '${c.count}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.deepPurple),
                    onPressed: controller.inCounter,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddToCartButton() {
    return GetBuilder<Cart_controller>(
      builder: (builder) {
        if (builder.isLoadingAdded.value) {
          return Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: Colors.deepPurple,
                size: 30,
              ),
            ),
          );
        } else {
          if (sharedPreferences?.getInt('active') == 1) {
            return Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple,
                    Colors.deepPurple.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () {
                    builder.putDate(
                      controller.productItemList[0].title,
                      controller.productItemList[0].price,
                      controller.count,
                      controller.productItemList[0].id,
                      controller.productItemList[0].image,
                      controller.productItemList[0].category,
                      controller.selectedColorText.value,
                      controller.selectedSize.value,
                    );
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart,
                          color: Colors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'أضف إلى السلة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else {
            return Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  'يجب تفعيل الحساب لاكمال عملية التسوق',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }
        }
      },
    );
  }

  Widget _buildTitle() {
    return Text(
      controller.productItemList[0].title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  void openWhatsapp() async {
    WhatsAppHelper.openWhatsappForUserBranch();
  }

  void msgAdded(String title, String msg) {
    Get.snackbar(title, msg);
  }
}
