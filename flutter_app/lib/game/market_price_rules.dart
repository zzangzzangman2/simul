double sharedMarketTickSize(double price, {String market = '미래시장'}) {
  if (!price.isFinite || price <= 0) return 1;
  if (price < 1000) return 1;
  if (price < 5000) return 5;
  if (price < 10000) return 10;
  if (price < 50000) return 50;
  if (price < 100000) return 100;
  if (price < 500000) return market == '도전시장' ? 100 : 500;
  return market == '도전시장' ? 100 : 1000;
}
