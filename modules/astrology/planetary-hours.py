#!/usr/bin/env python3
"""
Planetary Hours Calculator for El Dorado, KS, USA
Outputs JSON for waybar custom module
"""

import json
import ephem
from datetime import datetime, timedelta
import math

# El Dorado, KS coordinates
LATITUDE = "37.8172"
LONGITUDE = "-96.8622"
ELEVATION = 402  # meters

# Planetary symbols and names
PLANETS = [
    ("Saturn", "♄"),
    ("Jupiter", "♃"),
    ("Mars", "♂"),
    ("Sun", "☉"),
    ("Venus", "♀"),
    ("Mercury", "☿"),
    ("Moon", "☽"),
]

# Day rulers (planet that rules the first hour of each day)
# 0=Monday, 6=Sunday in Python's weekday()
DAY_RULERS = {
    0: 6,  # Monday -> Moon (index 6)
    1: 2,  # Tuesday -> Mars (index 2)
    2: 5,  # Wednesday -> Mercury (index 5)
    3: 1,  # Thursday -> Jupiter (index 1)
    4: 4,  # Friday -> Venus (index 4)
    5: 0,  # Saturday -> Saturn (index 0)
    6: 3,  # Sunday -> Sun (index 3)
}


def get_sun_times(date):
    """Get sunrise and sunset for El Dorado, KS on given date."""
    observer = ephem.Observer()
    observer.lat = LATITUDE
    observer.lon = LONGITUDE
    observer.elevation = ELEVATION
    observer.pressure = 0  # Disable atmospheric refraction for consistency
    observer.horizon = "-0:34"  # Standard refraction

    sun = ephem.Sun()

    # Set to noon of the given date
    observer.date = ephem.Date(date.strftime("%Y/%m/%d 12:00:00"))

    try:
        sunrise = observer.previous_rising(sun)
        sunset = observer.next_setting(sun)

        # Convert to local datetime
        sunrise_dt = ephem.localtime(sunrise)
        sunset_dt = ephem.localtime(sunset)

        return sunrise_dt, sunset_dt
    except ephem.AlwaysUpError:
        # Midnight sun - use noon as midpoint
        noon = datetime(date.year, date.month, date.day, 12, 0, 0)
        return noon - timedelta(hours=12), noon + timedelta(hours=12)
    except ephem.NeverUpError:
        # Polar night
        noon = datetime(date.year, date.month, date.day, 12, 0, 0)
        return noon, noon


def get_planetary_hour(now=None):
    """Calculate the current planetary hour."""
    if now is None:
        now = datetime.now()

    today = now.date()
    yesterday = today - timedelta(days=1)
    tomorrow = today + timedelta(days=1)

    # Get sun times for today, yesterday, and tomorrow
    sunrise_today, sunset_today = get_sun_times(today)
    sunrise_yesterday, sunset_yesterday = get_sun_times(yesterday)
    sunrise_tomorrow, sunset_tomorrow = get_sun_times(tomorrow)

    # Determine if we're in day or night period
    if now >= sunrise_today and now < sunset_today:
        # Daytime hours (sunrise to sunset)
        is_day = True
        period_start = sunrise_today
        period_end = sunset_today
        day_for_ruler = today.weekday()
        hour_offset = 0  # Day hours are 1-12
    elif now >= sunset_today:
        # Night hours after sunset (sunset to next sunrise)
        is_day = False
        period_start = sunset_today
        period_end = sunrise_tomorrow
        day_for_ruler = today.weekday()
        hour_offset = 12  # Night hours are 13-24 (indexed as 12-23)
    else:
        # Night hours before sunrise (previous sunset to sunrise)
        is_day = False
        period_start = sunset_yesterday
        period_end = sunrise_today
        day_for_ruler = yesterday.weekday()
        hour_offset = 12

    # Calculate hour duration and current hour
    period_duration = (period_end - period_start).total_seconds()
    hour_duration = period_duration / 12

    elapsed = (now - period_start).total_seconds()
    hour_index = int(elapsed / hour_duration)
    hour_index = min(hour_index, 11)  # Clamp to 0-11

    # Calculate remaining time in this hour
    hour_start = period_start + timedelta(seconds=hour_index * hour_duration)
    hour_end = hour_start + timedelta(seconds=hour_duration)
    remaining = hour_end - now

    # Get planetary ruler
    # First hour of day starts with day ruler, then follows Chaldean order
    day_ruler_index = DAY_RULERS[day_for_ruler]
    planet_index = (day_ruler_index + hour_offset + hour_index) % 7

    planet_name, planet_symbol = PLANETS[planet_index]

    # Format remaining time
    remaining_mins = int(remaining.total_seconds() / 60)
    remaining_str = f"{remaining_mins}m"

    # Determine period name
    period = "Day" if is_day else "Night"
    hour_num = hour_index + 1  # 1-indexed display

    return {
        "planet": planet_name,
        "symbol": planet_symbol,
        "hour": hour_num,
        "period": period,
        "remaining": remaining_str,
        "is_day": is_day,
    }


def main():
    info = get_planetary_hour()

    # Format for waybar
    text = f"{info['symbol']} {info['planet']}"
    tooltip = (
        f"Planetary Hour of {info['planet']} {info['symbol']}\n"
        f"{info['period']} Hour {info['hour']}/12\n"
        f"Time remaining: {info['remaining']}\n"
        f"Location: El Dorado, KS"
    )

    # Add class for styling based on planet
    css_class = info["planet"].lower()

    output = {"text": text, "tooltip": tooltip, "class": css_class}

    print(json.dumps(output))


if __name__ == "__main__":
    main()
