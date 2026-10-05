#!/usr/bin/env python3
"""
ForexFactory Gold News Alert
Scrapes USD High/Medium impact news that affects Gold (XAU/USD)
Sends push notifications via Firebase Cloud Messaging (FCM)
"""

import os
import sys
import json
import time
import logging
from datetime import datetime, timedelta
from typing import List, Dict, Optional, Tuple
import requests
from bs4 import BeautifulSoup
import pytz

# ============== CONFIG ==============
FCM_SERVER_KEY = os.getenv("FCM_SERVER_KEY", "")  # Firebase Cloud Messaging Server Key
FCM_TOPIC = "gold_alerts"  # Topic to subscribe in Flutter app
TIMEZONE = "Asia/Bangkok"
FOREX_FACTORY_URL = "https://www.forexfactory.com/calendar"

# News that STRONGLY affects Gold (XAU/USD)
GOLD_KEYWORDS = [
    # USD Core
    "non-farm", "nfp", "unemployment", "jobless", "payroll", "employment",
    "cpi", "inflation", "core cpi", "pce", "core pce", "price index",
    "fomc", "fed funds", "interest rate", "rate decision", "fed chair",
    "powell", "federal reserve", "monetary policy", "fomc minutes",
    "gdp", "retail sales", "core retail", "consumer spending",
    "ism", "pmi", "manufacturing", "services", "business activity",
    "durable goods", "factory orders", "construction spending",
    "housing starts", "building permits", "existing home sales",
    "consumer confidence", "consumer sentiment", "michigan",
    "trade balance", "current account", "budget deficit",
    "wages", "average hourly earnings", "labor cost", "productivity",
    
    # Direct Gold movers
    "gold", "xau", "precious metal", "bullion",
    "dollar index", "dxy", "usd index",
    "treasury yield", "bond yield", "10-year", "2-year",
]

# Impact levels to watch
WATCH_IMPACTS = ["High", "Medium"]  # Red + Orange

# ============== LOGGING ==============
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

# ============== HELPERS ==============
def get_bangkok_time() -> datetime:
    """Get current time in Bangkok timezone"""
    tz = pytz.timezone(TIMEZONE)
    return datetime.now(tz)

def is_market_hours() -> bool:
    """Check if it'"'"'s reasonable trading hours (06:00-02:00 Bangkok)"""
    now = get_bangkok_time()
    return 6 <= now.hour < 26  # 6 AM to 2 AM next day

def should_suppress_notification() -> bool:
    """Check if we should suppress notifications (Do Not Disturb)"""
    now = get_bangkok_time()
    # Suppress 02:00-06:00 Bangkok time
    return 2 <= now.hour < 6

def parse_forexfactory_date(date_str: str, time_str: str) -> Optional[datetime]:
    """Parse ForexFactory date/time to Bangkok datetime"""
    try:
        tz = pytz.timezone(TIMEZONE)
        now = get_bangkok_time()
        
        # ForexFactory format: "Mon Oct 5" + "8:30am"
        # Assume current year
        dt_str = f"{now.year} {date_str} {time_str}"
        dt = datetime.strptime(dt_str, "%Y %a %b %d %I:%M%p")
        return tz.localize(dt)
    except Exception as e:
        logger.warning(f"Failed to parse date: {date_str} {time_str} - {e}")
        return None

def is_gold_relevant(title: str) -> bool:
    """Check if news title is relevant to Gold trading"""
    title_lower = title.lower()
    return any(keyword.lower() in title_lower for keyword in GOLD_KEYWORDS)

def get_impact_class(impact_cell) -> str:
    """Extract impact level from ForexFactory calendar cell"""
    # High = red, Medium = orange, Low = yellow, Non-economic = gray
    classes = impact_cell.get("class", [])
    class_str = " ".join(classes).lower()
    
    if "high" in class_str or "red" in class_str:
        return "High"
    elif "medium" in class_str or "orange" in class_str:
        return "Medium"
    elif "low" in class_str or "yellow" in class_str:
        return "Low"
    return "None"

def scrape_forexfactory() -> List[Dict]:
    """Scrape ForexFactory calendar for today'"'"'s USD events"""
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        "Accept-Language": "en-US,en;q=0.5",
    }
    
    try:
        resp = requests.get(FOREX_FACTORY_URL, headers=headers, timeout=30)
        resp.raise_for_status()
    except Exception as e:
        logger.error(f"Failed to fetch ForexFactory: {e}")
        return []
    
    soup = BeautifulSoup(resp.text, "html.parser")
    events = []
    
    # Find calendar table rows
    table = soup.find("table", class_="calendar__table")
    if not table:
        table = soup.find("table", {"class": lambda x: x and "calendar" in x})
    
    if not table:
        logger.error("Could not find calendar table")
        return []
    
    current_date = None
    rows = table.find_all("tr", class_="calendar__row")
    
    for row in rows:
        # Check for date row
        date_cell = row.find("td", class_="calendar__date")
        if date_cell and date_cell.get_text(strip=True):
            current_date = date_cell.get_text(strip=True)
            continue
        
        # Parse event row
        currency_cell = row.find("td", class_="calendar__currency")
        if not currency_cell:
            continue
        
        currency = currency_cell.get_text(strip=True)
        if currency != "USD":
            continue  # Only USD events
        
        impact_cell = row.find("td", class_="calendar__impact")
        impact = get_impact_class(impact_cell) if impact_cell else "None"
        if impact not in WATCH_IMPACTS:
            continue
        
        time_cell = row.find("td", class_="calendar__time")
        time_str = time_cell.get_text(strip=True) if time_cell else ""
        
        event_cell = row.find("td", class_="calendar__event")
        if not event_cell:
            continue
        title = event_cell.get_text(strip=True)
        
        # Check if gold-relevant
        if not is_gold_relevant(title):
            continue
        
        actual_cell = row.find("td", class_="calendar__actual")
        actual = actual_cell.get_text(strip=True) if actual_cell else ""
        
        forecast_cell = row.find("td", class_="calendar__forecast")
        forecast = forecast_cell.get_text(strip=True) if forecast_cell else ""
        
        previous_cell = row.find("td", class_="calendar__previous")
        previous = previous_cell.get_text(strip=True) if previous_cell else ""
        
        # Parse datetime
        event_dt = parse_forexfactory_date(current_date, time_str) if current_date else None
        
        events.append({
            "title": title,
            "currency": currency,
            "impact": impact,
            "time": time_str,
            "datetime": event_dt.isoformat() if event_dt else None,
            "actual": actual,
            "forecast": forecast,
            "previous": previous,
            "date": current_date,
        })
    
    logger.info(f"Found {len(events)} relevant USD events")
    return events

def send_fcm_notification(title: str, body: str, data: Dict = None) -> bool:
    """Send push notification via FCM HTTP v1 API"""
    if not FCM_SERVER_KEY:
        logger.error("FCM_SERVER_KEY not set")
        return False
    
    url = "https://fcm.googleapis.com/fcm/send"
    headers = {
        "Authorization": f"key={FCM_SERVER_KEY}",
        "Content-Type": "application/json",
    }
    
    payload = {
        "to": f"/topics/{FCM_TOPIC}",
        "notification": {
            "title": title,
            "body": body,
            "sound": "default",
            "priority": "high",
        },
        "data": data or {},
        "android": {
            "priority": "high",
            "notification": {
                "channel_id": "gold_alerts",
                "priority": "high",
                "default_sound": True,
                "default_vibrate_timings": True,
            }
        },
        "apns": {
            "payload": {
                "aps": {
                    "sound": "default",
                    "badge": 1,
                }
            }
        }
    }
    
    try:
        resp = requests.post(url, headers=headers, json=payload, timeout=10)
        if resp.status_code == 200:
            result = resp.json()
            if result.get("success", 0) > 0:
                logger.info(f"FCM sent successfully: {title}")
                return True
            else:
                logger.error(f"FCM failed: {result}")
        else:
            logger.error(f"FCM HTTP {resp.status_code}: {resp.text}")
    except Exception as e:
        logger.error(f"FCM error: {e}")
    
    return False

def format_daily_digest(events: List[Dict]) -> Tuple[str, str]:
    """Format daily digest message"""
    now = get_bangkok_time()
    date_str = now.strftime("%d/%m/%Y")
    
    if not events:
        title = f"📅 ข่าวทองวันนี้ ({date_str})"
        body = "วันนี้ไม่มีข่าว USD แดง/ส้ม ที่เกี่ยวข้องทองคำครับ\n✅ เทรดสบายใจได้เลย"
        return title, body
    
    high_events = [e for e in events if e["impact"] == "High"]
    med_events = [e for e in events if e["impact"] == "Medium"]
    
    title = f"📅 ข่าวทองวันนี้ ({date_str}) - {len(events)} รายการ"
    
    lines = []
    if high_events:
        lines.append("🔴 <b>ผลกระทบแรง (High):</b>")
        for e in high_events:
            t = e["time"] or "??:??"
            lines.append(f"  {t} - {e['title']}")
    
    if med_events:
        lines.append("\n🟠 <b>ผลกระทบปานกลาง (Medium):</b>")
        for e in med_events:
            t = e["time"] or "??:??"
            lines.append(f"  {t} - {e['title']}")
    
    lines.append("\n⚠️ <b>ช่วงเวลาระวัง:</b>")
    warning_times = set()
    for e in events:
        if e["datetime"]:
            dt = datetime.fromisoformat(e["datetime"])
            start = dt - timedelta(minutes=30)
            end = dt + timedelta(minutes=60)
            warning_times.add(f"{start.strftime('%H:%M')}-{end.strftime('%H:%M')}")
    
    for wt in sorted(warning_times):
        lines.append(f"  ⏰ {wt} น.")
    
    body = "\n".join(lines)
    return title, body

def format_breaking_alert(event: Dict) -> Tuple[str, str]:
    """Format breaking news alert"""
    impact_emoji = "🔴" if event["impact"] == "High" else "🟠"
    time_str = event["time"] or "N/A"
    
    title = f"{impact_emoji} {event['impact']} Impact: {event['title']}"
    
    lines = [
        f"⏰ เวลา: {time_str} น.",
        f"📊 ผลกระทบ: {event['impact']}",
    ]
    
    if event["forecast"]:
        lines.append(f"🎯 คาดการณ์: {event['forecast']}")
    if event["previous"]:
        lines.append(f"📈 ก่อนหน้า: {event['previous']}")
    if event["actual"]:
        lines.append(f"✅ ผลจริง: {event['actual']}")
    
    lines.append("\n⚡ ทองคำอาจเคลื่อนไหวได้รวดเร็ว!")
    
    body = "\n".join(lines)
    return title, body

def run_daily_digest():
    """Run daily digest - send at 06:00 Bangkok"""
    logger.info("Running Daily Digest...")
    
    if should_suppress_notification():
        logger.info("Do Not Disturb period - skipping")
        return
    
    events = scrape_forexfactory()
    title, body = format_daily_digest(events)
    
    data = {
        "type": "daily_digest",
        "event_count": str(len(events)),
        "timestamp": get_bangkok_time().isoformat(),
    }
    
    send_fcm_notification(title, body, data)

def run_breaking_check():
    """Run breaking news check - every 15 minutes"""
    logger.info("Running Breaking News Check...")
    
    if should_suppress_notification():
        logger.info("Do Not Disturb period - skipping")
        return
    
    events = scrape_forexfactory()
    
    now = get_bangkok_time()
    recent_events = []
    
    for e in events:
        if e["datetime"]:
            dt = datetime.fromisoformat(e["datetime"])
            if -30 <= (now - dt).total_seconds() / 60 <= 15:
                recent_events.append(e)
    
    for event in recent_events:
        title, body = format_breaking_alert(event)
        data = {
            "type": "breaking",
            "impact": event["impact"],
            "title": event["title"],
            "time": event["time"],
            "timestamp": get_bangkok_time().isoformat(),
        }
        send_fcm_notification(title, body, data)
        time.sleep(1)

def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=["daily", "breaking"], required=True)
    args = parser.parse_args()
    
    logger.info(f"Starting Gold News Alert - Mode: {args.mode}")
    logger.info(f"Timezone: {TIMEZONE}, Current: {get_bangkok_time()}")
    
    if args.mode == "daily":
        run_daily_digest()
    elif args.mode == "breaking":
        run_breaking_check()
    
    logger.info("Done")

if __name__ == "__main__":
    main()
