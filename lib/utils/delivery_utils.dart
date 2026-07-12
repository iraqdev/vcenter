/// رسوم التوصيل لفرع العراق فقط.
const int kIraqBranchDeliveryFee = 5000;
const String kIraqBranchName = 'العراق';

const Set<String> kIraqBranchBaghdadAreas = {
  'زيونة',
  'شارع فلسطين',
  'كرادة',
  'الأمين',
  'المشتل',
  'بلديات',
};

bool qualifiesForIraqDelivery({
  required String? userType,
  required String? closestBranch,
  required String? city,
  required String? address,
}) {
  if (userType == 'زبون') return true;
  if (closestBranch == kIraqBranchName) return true;
  final area = (address ?? '').trim();
  if (city == 'بغداد' && kIraqBranchBaghdadAreas.contains(area)) return true;
  return false;
}

int deliveryFeeForUser({
  required String? userType,
  required String? closestBranch,
  required String? city,
  required String? address,
}) {
  if (qualifiesForIraqDelivery(
    userType: userType,
    closestBranch: closestBranch,
    city: city,
    address: address,
  )) {
    return kIraqBranchDeliveryFee;
  }
  return 0;
}
