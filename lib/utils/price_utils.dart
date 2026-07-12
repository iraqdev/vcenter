import 'package:ecommerce/main.dart';

/// زيادة سعر الزبون على السعر الأساسي (دينار عراقي) — تُطبَّق فقط إن لم يُحدَّد سعر زبون مخصص.
const int kCustomerPriceMarkup = 4000;

const String kCustomerUserType = 'زبون';

bool get isUserLoggedIn => sharedPreferences?.getInt('active') == 1;

bool get isCustomerUser =>
    (sharedPreferences?.getString('userType') ?? '') == kCustomerUserType;

/// سعر العرض للمستخدم.
/// للزبون: إن وُجد [customerPrice] يُعرض كما هو بدون +4000، وإلا السعر الأساسي + 4000.
int priceForUser(int basePrice, {int? customerPrice}) {
  if (!isUserLoggedIn) return basePrice;
  if (isCustomerUser) {
    if (customerPrice != null) return customerPrice;
    return basePrice + kCustomerPriceMarkup;
  }
  return basePrice;
}

/// السعر الافتراضي للزبون (أساسي + 4000) قبل أي تخصيص من الداش.
int defaultCustomerPrice(int basePrice) => basePrice + kCustomerPriceMarkup;

String formatUserPriceLabel(
  int basePrice, {
  String suffix = '',
  int? customerPrice,
}) {
  if (!isUserLoggedIn) return '...';
  return '${formatter.format(priceForUser(basePrice, customerPrice: customerPrice))}$suffix';
}
