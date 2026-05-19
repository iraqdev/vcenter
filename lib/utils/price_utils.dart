import 'package:ecommerce/main.dart';

/// زيادة سعر الزبون على السعر الأساسي (دينار عراقي).
const int kCustomerPriceMarkup = 4000;

const String kCustomerUserType = 'زبون';

bool get isUserLoggedIn => sharedPreferences?.getInt('active') == 1;

bool get isCustomerUser =>
    (sharedPreferences?.getString('userType') ?? '') == kCustomerUserType;

int priceForUser(int basePrice) {
  if (!isUserLoggedIn) return basePrice;
  if (isCustomerUser) return basePrice + kCustomerPriceMarkup;
  return basePrice;
}

String formatUserPriceLabel(int basePrice, {String suffix = ''}) {
  if (!isUserLoggedIn) return '...';
  return '${formatter.format(priceForUser(basePrice))}$suffix';
}
