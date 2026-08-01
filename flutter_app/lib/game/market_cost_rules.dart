double marketTradingFeeRate(DateTime date) {
  if (date.isBefore(DateTime(2003))) return 0.0050;
  if (date.isBefore(DateTime(2007))) return 0.0040;
  if (date.isBefore(DateTime(2011))) return 0.0030;
  return 0.0025;
}

double marketSecuritiesTransactionTaxRate(DateTime date) {
  if (date.isBefore(DateTime(2019))) return 0.0030;
  if (date.isBefore(DateTime(2021))) return 0.0025;
  if (date.isBefore(DateTime(2023))) return 0.0023;
  if (date.isBefore(DateTime(2024))) return 0.0020;
  if (date.isBefore(DateTime(2025))) return 0.0018;
  return 0.0015;
}
