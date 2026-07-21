"""Generate a complete 2000-2010 KOSPI/KOSDAQ snapshot.

The importer requires a KRX Data Marketplace account through KRX_ID and KRX_PW.
It takes the union of daily weekday listing snapshots so delisted and merged companies
are not silently removed. Do not redistribute the output before checking the KRX
licence for the intended use.
"""

from __future__ import annotations

import json
import os
import sys
import time
from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

try:
    from pykrx import stock
except ImportError as exc:
    raise SystemExit(
        "Install dependencies: python -m pip install -r scripts/requirements-market.txt"
    ) from exc

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / ".cache" / "krx-market"
OUTPUTS = (
    ROOT / "app" / "data" / "market-history.json",
    ROOT / "flutter_app" / "assets" / "market" / "market-history.json",
)
START = "20000101"
END = "20101231"
MARKETS = ("KOSPI", "KOSDAQ")


@dataclass(frozen=True)
class Listing:
    ticker: str
    market: str
    first_seen: str
    last_seen: str


def require_credentials() -> None:
    if not os.getenv("KRX_ID") or not os.getenv("KRX_PW"):
        raise SystemExit(
            "KRX_ID and KRX_PW are required. Set them locally and never commit them."
        )


def checkpoints():
    cursor = date(2000, 1, 1)
    end = date(2010, 12, 31)
    while cursor <= end:
        if cursor.weekday() < 5:
            yield cursor.strftime("%Y%m%d")
        cursor += timedelta(days=1)


def collect_listings() -> dict[str, Listing]:
    found: dict[str, Listing] = {}
    for checkpoint in checkpoints():
        for market in MARKETS:
            for ticker in stock.get_market_ticker_list(checkpoint, market=market):
                previous = found.get(ticker)
                found[ticker] = Listing(
                    ticker=ticker,
                    market=market,
                    first_seen=previous.first_seen if previous else checkpoint,
                    last_seen=checkpoint,
                )
        print(f"catalogued {checkpoint}: {len(found)} tickers", flush=True)
        time.sleep(0.08)
    return found


def cache_path(ticker: str) -> Path:
    return CACHE / f"{ticker}.json"


def load_or_fetch_prices(listing: Listing) -> dict[str, float]:
    path = cache_path(listing.ticker)
    if path.exists():
        return json.loads(path.read_text(encoding="utf-8"))

    frame = stock.get_market_ohlcv_by_date(
        START,
        END,
        listing.ticker,
        adjusted=False,
    )
    prices = {
        index.strftime("%Y-%m-%d"): float(row["종가"])
        for index, row in frame.iterrows()
        if float(row["종가"]) > 0
    }
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(prices, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    time.sleep(0.12)
    return prices


def validate_asset(asset: dict) -> None:
    dates = sorted(asset["prices"])
    if not dates:
        raise ValueError(f"{asset['symbol']}: no prices")
    if len(dates) != len(set(dates)):
        raise ValueError(f"{asset['symbol']}: duplicate dates")
    if any(value <= 0 for value in asset["prices"].values()):
        raise ValueError(f"{asset['symbol']}: non-positive close")


def load_preserved_overseas() -> list[dict]:
    current_path = OUTPUTS[0]
    if not current_path.exists():
        raise RuntimeError("Run npm run data:fetch before the full KRX importer.")
    current = json.loads(current_path.read_text(encoding="utf-8"))
    overseas = [
        asset for asset in current.get("assets", []) if asset.get("country") != "KR"
    ]
    if len(overseas) != 6:
        raise RuntimeError(
            f"Expected 6 preserved overseas assets, found {len(overseas)}."
        )
    return overseas


def main() -> int:
    require_credentials()
    listings = collect_listings()
    assets = []
    failures = []
    for index, listing in enumerate(sorted(listings.values(), key=lambda item: item.ticker), 1):
        try:
            prices = load_or_fetch_prices(listing)
            if not prices:
                continue
            name = stock.get_market_ticker_name(listing.ticker) or listing.ticker
            asset = {
                "id": listing.ticker,
                "symbol": f"{listing.ticker}.{'KS' if listing.market == 'KOSPI' else 'KQ'}",
                "name": name,
                "market": listing.market,
                "country": "KR",
                "sector": "미분류",
                "color": "#607D8B",
                "currency": "KRW",
                "firstTradeDate": min(prices),
                "lastTradeDate": max(prices),
                "prices": prices,
            }
            validate_asset(asset)
            assets.append(asset)
        except Exception as exc:  # preserve an auditable failure list
            failures.append({"ticker": listing.ticker, "error": str(exc)})
        print(f"prices {index}/{len(listings)}: {listing.ticker}", flush=True)

    overseas = load_preserved_overseas()
    combined_assets = assets + overseas
    output = {
        "schemaVersion": 3,
        "generatedAt": datetime.now(timezone.utc).isoformat(),
        "period": {"start": "2000-01-01", "end": "2010-12-31"},
        "methodology": (
            "KRX 원시 일별 종가. 모든 평일 상장목록 합집합으로 상장폐지·합병 종목을 "
            "보존하고 휴장일은 앱에서 직전 거래일 종가를 유지한다. 장중 틱은 게임용이다."
        ),
        "source": {
            "name": "KRX Data Marketplace + preserved overseas snapshot",
            "url": "https://data.krx.co.kr/",
            "note": "국내는 KRX 원장, 해외 6개는 기존 개발용 스냅샷입니다. 재배포 전 각 데이터 라이선스를 확인해야 합니다.",
        },
        "audit": {
            "listingCount": len(listings),
            "domesticAssetCount": len(assets),
            "preservedOverseasCount": len(overseas),
            "assetCount": len(combined_assets),
            "failureCount": len(failures),
            "failures": failures,
        },
        "assets": combined_assets,
    }

    CACHE.mkdir(parents=True, exist_ok=True)
    if failures:
        (CACHE / "failures.json").write_text(
            json.dumps(failures, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        print(
            f"refusing final output: {len(failures)} unresolved tickers",
            file=sys.stderr,
        )
        return 2

    serialized = json.dumps(output, ensure_ascii=False, separators=(",", ":"))
    for path in OUTPUTS:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(serialized, encoding="utf-8")
        print(f"wrote {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
