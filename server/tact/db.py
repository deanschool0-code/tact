"""SQLite storage: daily usage counters and verified subscriptions. No chat text is ever stored."""
import sqlite3
import threading
from datetime import datetime, timezone

SCHEMA = """
create table if not exists usage (
  device_id text not null,
  day text not null,
  count integer not null default 0,
  primary key (device_id, day)
);
create table if not exists entitlements (
  original_transaction_id text primary key,
  device_id text not null,
  product_id text not null,
  expires_at text,
  environment text not null,
  updated_at text not null
);
create index if not exists entitlements_device on entitlements(device_id);
"""


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


def today() -> str:
    return utc_now().strftime("%Y-%m-%d")


class DB:
    def __init__(self, path: str):
        self._lock = threading.Lock()
        self._conn = sqlite3.connect(path, check_same_thread=False)
        self._conn.executescript(SCHEMA)
        self._conn.commit()

    def used_today(self, device_id: str) -> int:
        with self._lock:
            row = self._conn.execute(
                "select count from usage where device_id=? and day=?", (device_id, today())
            ).fetchone()
        return row[0] if row else 0

    def try_consume(self, device_id: str, limit: int) -> bool:
        """Atomically use one free generation. False if the daily limit is reached."""
        with self._lock:
            cur = self._conn.execute(
                "insert into usage(device_id, day, count) values (?, ?, 1) "
                "on conflict(device_id, day) do update set count = count + 1 where count < ?",
                (device_id, today(), limit),
            )
            self._conn.commit()
            return cur.rowcount == 1

    def refund(self, device_id: str) -> None:
        with self._lock:
            self._conn.execute(
                "update usage set count = max(count - 1, 0) where device_id=? and day=?",
                (device_id, today()),
            )
            self._conn.commit()

    def save_entitlement(self, otid: str, device_id: str, product_id: str, expires_at, env: str):
        with self._lock:
            self._conn.execute(
                "insert into entitlements values (?,?,?,?,?,?) on conflict(original_transaction_id) do update set "
                "device_id=excluded.device_id, product_id=excluded.product_id, expires_at=excluded.expires_at, "
                "environment=excluded.environment, updated_at=excluded.updated_at",
                (otid, device_id, product_id, expires_at, env, utc_now().isoformat()),
            )
            self._conn.commit()

    def is_pro(self, device_id: str) -> bool:
        now = utc_now().isoformat()
        with self._lock:
            row = self._conn.execute(
                "select 1 from entitlements where device_id=? and (expires_at is null or expires_at > ?) limit 1",
                (device_id, now),
            ).fetchone()
        return row is not None

    def delete_device(self, device_id: str) -> int:
        with self._lock:
            a = self._conn.execute("delete from usage where device_id=?", (device_id,)).rowcount
            b = self._conn.execute("delete from entitlements where device_id=?", (device_id,)).rowcount
            self._conn.commit()
        return a + b
