import 'package:flutter/foundation.dart';

import '../../core/harvest.dart';

/// DEMO DATA for the Sell page. There is no marketplace backend yet (one phone,
/// no buyers), so these offers and sales are made up to show the idea: buyers
/// make offers, the farmer sees how each compares with a market reference, and
/// accepted offers become sale records. Buyer names are fictional. The page
/// shows a "Demo" tag so nobody mistakes this for live data.

class BuyerOffer {
  const BuyerOffer({
    required this.id,
    required this.buyer,
    required this.kg,
    required this.pricePerKg,
    required this.pickupInDays,
    required this.km,
    required this.rating,
    required this.sales,
    this.verified = false,
    this.expiresInHours,
  });
  final String id, buyer;
  final int kg, pricePerKg, pickupInDays, km, sales;
  final double rating;
  final bool verified;
  final int? expiresInHours;

  int get total => kg * pricePerKg;
}

class SaleRecord {
  const SaleRecord({required this.buyer, required this.kg, required this.pricePerKg, this.pickupInDays});
  final String buyer;
  final int kg, pricePerKg;

  /// Null: picked up and paid. Otherwise the pickup is scheduled.
  final int? pickupInDays;

  bool get paid => pickupInDays == null;
  int get total => kg * pricePerKg;
}

/// The demo marketplace. One instance for the whole app so accepted offers stay
/// accepted while the farmer switches tabs during the demo.
class MarketDemo extends ChangeNotifier {
  MarketDemo();
  static final instance = MarketDemo();

  /// Coffee cherry, KES per kg (demo value).
  final int referencePrice = 95;
  static const currency = 'KES';

  final List<BuyerOffer> offers = [
    const BuyerOffer(
      id: 'o1',
      buyer: 'Highland Roasters',
      kg: 150,
      pricePerKg: 104,
      pickupInDays: 3,
      km: 12,
      rating: 4.8,
      sales: 32,
      verified: true,
      expiresInHours: 2,
    ),
    const BuyerOffer(
      id: 'o2',
      buyer: 'Kahawa Bora Co-op',
      kg: 120,
      pricePerKg: 98,
      pickupInDays: 5,
      km: 6,
      rating: 4.9,
      sales: 118,
      verified: true,
    ),
    const BuyerOffer(
      id: 'o3',
      buyer: 'Mama Grace Traders',
      kg: 80,
      pricePerKg: 86,
      pickupInDays: 2,
      km: 21,
      rating: 4.1,
      sales: 9,
    ),
  ];

  final List<SaleRecord> sales = [
    const SaleRecord(buyer: 'Kahawa Bora Co-op', kg: 180, pricePerKg: 92),
    const SaleRecord(buyer: 'Highland Roasters', kg: 120, pricePerKg: 99),
  ];

  /// The slide-in "new offer" card is shown once per app run.
  bool offerAlertSeen = false;

  /// This season's harvest, worked out in the chat (null until the farmer asks).
  HarvestForecast? forecast;

  /// The forecast arrived since the farmer last opened Sell.
  bool forecastNew = false;

  void setForecast(HarvestForecast f) {
    if (identical(f, forecast)) return;
    forecast = f;
    forecastNew = true;
    notifyListeners();
  }

  void forecastSeen() => forecastNew = false;

  /// Sold or agreed (pickup scheduled), open offers, and what is left to sell.
  int get soldKg => sales.fold(0, (a, s) => a + s.kg);
  int get offeredKg => offers.fold(0, (a, o) => a + o.kg);
  int get toSellKg {
    final f = forecast;
    if (f == null) return 0;
    final left = f.kgMid - soldKg - offeredKg;
    return left < 0 ? 0 : left;
  }

  int get seasonKg => sales.fold(0, (a, s) => a + s.kg);
  int get seasonTotal => sales.fold(0, (a, s) => a + s.total);

  /// How an offer compares with the market reference, in percent.
  int vsMarket(BuyerOffer o) => ((o.pricePerKg - referencePrice) * 100 / referencePrice).round();

  void accept(BuyerOffer o) {
    offers.remove(o);
    sales.insert(0, SaleRecord(buyer: o.buyer, kg: o.kg, pricePerKg: o.pricePerKg, pickupInDays: o.pickupInDays));
    notifyListeners();
  }

  void decline(BuyerOffer o) {
    offers.remove(o);
    notifyListeners();
  }
}

/// "KES 20,800".
String money(int amount) {
  final digits = amount.abs().toString();
  final grouped = digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '${MarketDemo.currency} ${amount < 0 ? '-' : ''}$grouped';
}
