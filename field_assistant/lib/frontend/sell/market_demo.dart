import 'package:flutter/foundation.dart';

import '../../core/harvest.dart';

/// DEMO DATA for the Sell page. There is no marketplace backend yet (one phone,
/// no buyers), so these offers and sales are made up to show the idea: buyers
/// make offers, the farmer sees how each compares with a market reference, and
/// accepted offers become sale records. Buyer names are fictional. The page
/// shows a "Demo" tag so nobody mistakes this for live data.
///
/// Offers arrive in an inbox when the phone is online (the app works offline;
/// the market syncs whenever there is signal). The season starts unsold; each
/// accepted offer becomes a sale. Quantities are shares of the season's harvest
/// (the chat's forecast, or 1,000 kg before there is one), so sold + offered
/// never exceeds what grows, whatever the farmer's trees.

class BuyerOffer {
  const BuyerOffer({
    required this.id,
    required this.buyer,
    required this.share,
    required this.pricePerKg,
    required this.pickupInDays,
    required this.km,
    required this.rating,
    required this.sales,
    this.verified = false,
    this.expiresInHours,
  });
  final String id, buyer;

  /// Part of the season's harvest this buyer asks for (0.15 = 15%).
  final double share;
  final int pricePerKg, pickupInDays, km, sales;
  final double rating;
  final bool verified;
  final int? expiresInHours;
}

class SaleRecord {
  const SaleRecord({required this.buyer, required this.share, required this.pricePerKg, this.pickupInDays});
  final String buyer;
  final double share;
  final int pricePerKg;

  /// Null: picked up and paid. Otherwise the pickup is scheduled.
  final int? pickupInDays;

  bool get paid => pickupInDays == null;
}

/// The demo marketplace. One instance for the whole app so accepted offers stay
/// accepted while the farmer switches tabs during the demo.
class MarketDemo extends ChangeNotifier {
  MarketDemo();
  static final instance = MarketDemo();

  /// Coffee cherry, US cents per kg (demo value). Shown in US dollars so anyone
  /// watching the demo reads it at once; a real market would use the local currency.
  final int referencePrice = 73;

  final List<BuyerOffer> offers = [
    const BuyerOffer(
      id: 'o1',
      buyer: 'Highland Roasters',
      share: 0.35,
      pricePerKg: 80,
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
      share: 0.25,
      pricePerKg: 76,
      pickupInDays: 5,
      km: 6,
      rating: 4.9,
      sales: 118,
      verified: true,
    ),
    const BuyerOffer(
      id: 'o3',
      buyer: 'Mama Grace Traders',
      share: 0.15,
      pricePerKg: 66,
      pickupInDays: 2,
      km: 21,
      rating: 4.1,
      sales: 9,
    ),
  ];

  /// Sales agreed this season (starts empty: the whole harvest is unsold).
  final List<SaleRecord> sales = [];

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

  /// The harvest every share is taken from.
  int get seasonBase => forecast?.kgMid ?? 1000;

  /// A share of the season in kg: rounded to 10 kg on bigger farms, to 1 kg on
  /// small ones (so a 50 kg harvest still leaves something to sell).
  int kg(double share) {
    final step = seasonBase >= 500 ? 10 : 1;
    final v = (seasonBase * share / step).round() * step;
    return v < step ? step : v;
  }

  int offerKg(BuyerOffer o) => kg(o.share);
  int offerTotal(BuyerOffer o) => offerKg(o) * o.pricePerKg;
  int saleKg(SaleRecord r) => kg(r.share);
  int saleTotal(SaleRecord r) => saleKg(r) * r.pricePerKg;

  /// Sold or agreed (pickup scheduled), offers waiting in the inbox, and what
  /// is not sold yet.
  int get soldKg => sales.fold(0, (a, s) => a + saleKg(s));
  int get offeredKg => offers.fold(0, (a, o) => a + offerKg(o));
  int get toSellKg {
    final left = seasonBase - soldKg;
    return left < 0 ? 0 : left;
  }

  int get seasonTotal => sales.fold(0, (a, s) => a + saleTotal(s));

  /// How an offer compares with the market reference, in percent.
  int vsMarket(BuyerOffer o) => ((o.pricePerKg - referencePrice) * 100 / referencePrice).round();

  void accept(BuyerOffer o) {
    offers.remove(o);
    sales.insert(0, SaleRecord(buyer: o.buyer, share: o.share, pricePerKg: o.pricePerKg, pickupInDays: o.pickupInDays));
    notifyListeners();
  }

  void decline(BuyerOffer o) {
    offers.remove(o);
    notifyListeners();
  }
}

/// A price per kg from US cents: "$0.80".
String price(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

/// An amount from US cents, in whole dollars: "$1,234".
String money(int cents) {
  final dollars = (cents / 100).round();
  final grouped = dollars.abs().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  return '${dollars < 0 ? '-' : ''}\$$grouped';
}
