#!/usr/bin/env python3
"""Seed Supabase with runs parsed from GPX files. Uses service_role key to bypass RLS."""

import json
import math
import os
import sys
import uuid
import xml.etree.ElementTree as ET
from datetime import datetime, timezone

import requests

SUPABASE_URL = "https://bxmjjapuqgnvnmbgpdyu.supabase.co"
SERVICE_ROLE_KEY = os.environ.get(
    "SUPABASE_SERVICE_ROLE_KEY",
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ4bWpqYXB1cWdudm5tYmdwZHl1Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MTYyNDA5MCwiZXhwIjoyMDk3MjAwMDkwfQ.imVuSqzGo2MgqATj9uyG_h6DNmFdchI2k7qDWDycumA",
)

HEADERS = {
    "apikey": SERVICE_ROLE_KEY,
    "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=minimal",
}

XML_NS = {"gpx": "http://www.topografix.com/GPX/1/1"}


def haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    r = 6_371_000
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat / 2) ** 2
         + math.cos(math.radians(lat1))
         * math.cos(math.radians(lat2))
         * math.sin(dlon / 2) ** 2)
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def get_first_user() -> dict:
    resp = requests.get(
        f"{SUPABASE_URL}/auth/v1/admin/users?per_page=1",
        headers={"apikey": SERVICE_ROLE_KEY, "Authorization": f"Bearer {SERVICE_ROLE_KEY}"},
        timeout=30,
    )
    resp.raise_for_status()
    users = resp.json().get("users", [])
    if not users:
        print("No users found.", file=sys.stderr)
        sys.exit(1)
    user = users[0]
    print(f"Using user: {user['email']}  (id={user['id']})")
    return user


def parse_gpx(filepath: str) -> tuple[str, list[dict]]:
    tree = ET.parse(filepath)
    root = tree.getroot()
    name_el = root.find(".//gpx:trk/gpx:name", XML_NS)
    name = name_el.text.strip() if name_el is not None and name_el.text else os.path.splitext(os.path.basename(filepath))[0]
    points: list[dict] = []
    for pt in root.findall(".//gpx:trkpt", XML_NS):
        lat = float(pt.get("lat", 0))
        lon = float(pt.get("lon", 0))
        ele_el = pt.find("gpx:ele", XML_NS)
        ele = float(ele_el.text) if ele_el is not None and ele_el.text else 0.0
        time_el = pt.find("gpx:time", XML_NS)
        t = time_el.text.strip() if time_el is not None and time_el.text else None
        points.append({"lat": lat, "lon": lon, "ele": ele, "time": t})
    return name, points


def compute_stats(points: list[dict]) -> dict:
    valid = [p for p in points if p["time"] is not None]
    if len(valid) < 2:
        return {}
    total_dist = 0.0
    for i in range(1, len(valid)):
        total_dist += haversine(valid[i - 1]["lat"], valid[i - 1]["lon"],
                                valid[i]["lat"], valid[i]["lon"])
    t1 = datetime.fromisoformat(valid[0]["time"])
    t2 = datetime.fromisoformat(valid[-1]["time"])
    duration = (t2 - t1).total_seconds()
    avg_pace = (duration / (total_dist / 1000)) if total_dist > 0 else 0
    return {
        "distance_meters": round(total_dist, 1),
        "duration_seconds": duration,
        "average_pace_seconds_per_km": round(avg_pace, 1),
        "start_time": t1.isoformat(),
        "end_time": t2.isoformat(),
    }


def build_locations(points: list[dict], run_id: str) -> list[dict]:
    valid = [p for p in points if p["time"] is not None]
    locs: list[dict] = []
    for seq, p in enumerate(valid):
        dt = datetime.fromisoformat(p["time"])
        locs.append({
            "id": str(uuid.uuid4()),
            "run_id": run_id,
            "latitude": p["lat"],
            "longitude": p["lon"],
            "altitude": round(p["ele"], 1),
            "speed": 0.0,
            "sequence": seq,
            "recorded_at": dt.isoformat(),
        })
    for i in range(1, len(locs)):
        d = haversine(locs[i - 1]["latitude"], locs[i - 1]["longitude"],
                      locs[i]["latitude"], locs[i]["longitude"])
        t1 = datetime.fromisoformat(locs[i - 1]["recorded_at"])
        t2 = datetime.fromisoformat(locs[i]["recorded_at"])
        dt = (t2 - t1).total_seconds()
        locs[i]["speed"] = round(d / dt, 2) if dt > 0 else 0.0
    return locs


def patch_empty_speed_to_zero():
    """PostgREST skips keys with Python float 0.0 in some versions. Patch all run_locations
    that have NULL speed to 0 via a bulk update."""
    resp = requests.patch(
        f"{SUPABASE_URL}/rest/v1/run_locations?speed=is.null",
        json={"speed": 0},
        headers=HEADERS,
        timeout=60,
    )
    if resp.ok:
        print(f"  Patched NULL speeds → 0 (updated ~{resp.headers.get('content-range', '?')} rows)")


def main():
    user = get_first_user()
    user_id = user["id"]

    # Delete any existing runs for this user (clean slate for seeding)
    resp = requests.delete(
        f"{SUPABASE_URL}/rest/v1/runs?user_id=eq.{user_id}",
        headers=HEADERS,
        timeout=30,
    )
    print(f"Cleared {resp.headers.get('content-range', '?')} existing runs")

    gpx_files = ["GPX/Karura_1.gpx", "GPX/Arboretum_10k.gpx"]
    created_at = datetime.now(timezone.utc).isoformat()

    for gpx_path in gpx_files:
        if not os.path.exists(gpx_path):
            print(f"\nSkipping {gpx_path}: file not found")
            continue

        print(f"\n{'=' * 60}")
        print(f"Processing: {gpx_path}")

        name, points = parse_gpx(gpx_path)
        valid_count = sum(1 for p in points if p["time"])
        print(f"  Name:    {name}")
        print(f"  Points:  {len(points)} total, {valid_count} with timestamps")

        stats = compute_stats(points)
        pace_min = int(stats["average_pace_seconds_per_km"] / 60)
        pace_sec = int(stats["average_pace_seconds_per_km"] % 60)
        print(f"  Distance: {stats['distance_meters']:.0f} m  ({stats['distance_meters'] / 1000:.2f} km)")
        print(f"  Duration: {stats['duration_seconds']:.0f} s  ({stats['duration_seconds'] / 60:.1f} min)")
        print(f"  Pace:     {pace_min}:{pace_sec:02d} /km")

        run_id = str(uuid.uuid4())
        run_data = {
            "id": run_id,
            "user_id": user_id,
            "title": name,
            "status": "completed",
            "start_time": stats["start_time"],
            "end_time": stats["end_time"],
            "distance_meters": stats["distance_meters"],
            "duration_seconds": stats["duration_seconds"],
            "average_pace_seconds_per_km": stats["average_pace_seconds_per_km"],
            "is_public": True,
            "created_at": created_at,
        }

        print("  Inserting run ...", end=" ", flush=True)
        resp = requests.post(f"{SUPABASE_URL}/rest/v1/runs", json=run_data, headers=HEADERS, timeout=30)
        if not resp.ok:
            print(f"FAILED ({resp.status_code})")
            continue
        print("OK")

        locs = build_locations(points, run_id)
        batch_size = 300
        total = len(locs)
        ok = True

        for start in range(0, total, batch_size):
            batch = locs[start:start + batch_size]
            print(f"  Locations {start + 1}-{min(start + batch_size, total)}/{total} ...", end=" ", flush=True)
            resp = requests.post(
                f"{SUPABASE_URL}/rest/v1/run_locations",
                json=batch,
                headers=HEADERS,
                timeout=120,
            )
            if not resp.ok:
                print(f"FAILED ({resp.status_code}): {resp.text[:200]}")
                ok = False
                break
            print("OK")

        if ok:
            print(f"  Done: {name!r} seeded successfully.")
        else:
            print(f"  WARNING: {name!r} partially seeded.")

    print(f"\n{'=' * 60}")
    print("Seed complete. Launch the app and pull to refresh!")


if __name__ == "__main__":
    main()
