import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ecommerce/controllers/Category_controller.dart';
class Categories extends StatelessWidget {
   Categories({super.key});
   final Category_controller controller = Get.put(Category_controller());
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body:Obx(() {
        if (!controller.isLoadingCategories.value) {
          if (controller.categoriesList.isNotEmpty) {
            return  categorieslist();
          } else {
            return Center(
              child: Text('لا توجد فئات حالياً'), // تم تحديث النص ليتناسب مع اللغة المستخدمة
            );
          }
        } else {
          return loading_(); // تم تحديث النص ليتناسب مع اللغة المستخدمة
        }
      })

    );
  }
   loading_() {
     return Center(
       child: LoadingAnimationWidget.staggeredDotsWave(
         color: Colors.black,
         size: 80,
       ),
     );
   }
   categorieslist() {
     return RefreshIndicator(
       onRefresh: () async => controller.fetchCategories(),
       child: CustomScrollView(
         slivers: [
           SliverPadding(
             padding: EdgeInsets.only(right: Get.height * 0.009, left: Get.height * 0.009),
             sliver: SliverGrid(
               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                 childAspectRatio: 0.95,
                 crossAxisCount: 2,
                 crossAxisSpacing: 10.0,
                 mainAxisSpacing: 15.0,
               ),
               delegate: SliverChildBuilderDelegate(
                 (BuildContext context, int index) {
                   final Category = controller.categoriesList[index];
                   return CategoryItem(
                     Category.image,
                     Category.title,
                     Category.id,
                   );
                 },
                 childCount: controller.categoriesList.length,
               ),
             ),
           ),
         ],
       ),
     );
   }
   Widget _buildCategoryImage(String url) {
     final size = Get.height * 0.12;
     final width = Get.height * 0.18;
     final placeholder = Icon(Icons.image_not_supported, size: Get.height * 0.1, color: Colors.grey);
     if (url.isNotEmpty && (url.startsWith('http://') || url.startsWith('https://'))) {
       return CachedNetworkImage(
         imageUrl: url,
         height: size,
         width: width,
         fit: BoxFit.contain,
         placeholder: (_, __) => SizedBox(height: size, width: width, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
         errorWidget: (_, __, ___) => Image.asset('assets/images/all.png', height: size, width: width, fit: BoxFit.contain, errorBuilder: (_, __, ___) => placeholder),
       );
     }
     return Image.asset(
       'assets/images/all.png',
       height: size,
       width: width,
       fit: BoxFit.contain,
       errorBuilder: (_, __, ___) => placeholder,
     );
   }

   CategoryItem(String url , String title  , int index){
     return GestureDetector(
       onTap: (){
         Get.toNamed('/products' , arguments: [{'id':index}]);
       },
       child: Container(
         padding: EdgeInsets.all(Get.height * 0.017),
         width: Get.height * 0.2,
         decoration: BoxDecoration(
           boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.1), // لون الظل مع الشفافية
               spreadRadius: 2, // مدى انتشار الظل
               blurRadius: 5, // درجة الضبابية
               offset: Offset(0, 3), // إزاحة الظل (x, y)
             ),
           ],
           color: Colors.white, // لون الحاوية

             border: Border.all(color: Colors.black12),
             borderRadius: BorderRadius.all(Radius.circular(15))
         ),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: <Widget>[
             spaceH(Get.height * 0.02),
             Center(
               child: _buildCategoryImage(url),
             ),
             spaceH(Get.height * 0.01),
             Center(
               child: Text(title , textAlign: TextAlign.start,
                 overflow: TextOverflow.ellipsis,
                 style: TextStyle(
                   fontWeight: FontWeight.bold,

                 ),
               ),
             )
           ],
         ),
       ),
     );
   }
   SizedBox spaceH(double size) {
     return SizedBox(
       height: size,
     );
   }
   SizedBox spaceW(double size) {
     return SizedBox(
       width: size,
     );
   }
}
