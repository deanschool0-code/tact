"""Verifies StoreKit 2 signed transactions with Apple's official app-store-server-library."""
import glob
import os
from datetime import datetime, timezone

from appstoreserverlibrary.models.Environment import Environment
from appstoreserverlibrary.signed_data_verifier import SignedDataVerifier, VerificationException

PRODUCT_IDS = {"tact.pro.monthly", "tact.pro.yearly"}


class EntitlementError(Exception):
    pass


class Verifier:
    def __init__(self, cfg):
        self.cfg = cfg
        roots = []
        for path in glob.glob(os.path.join(cfg.certs_dir, "*.cer")):
            with open(path, "rb") as fh:
                roots.append(fh.read())
        self.verifiers = []
        if roots:
            if cfg.app_apple_id:
                self.verifiers.append(SignedDataVerifier(roots, True, Environment.PRODUCTION, cfg.bundle_id, cfg.app_apple_id))
            self.verifiers.append(SignedDataVerifier(roots, True, Environment.SANDBOX, cfg.bundle_id))
        if cfg.allow_xcode_transactions:
            self.verifiers.append(SignedDataVerifier([], False, Environment.XCODE, cfg.bundle_id))

    def verify(self, jws: str) -> dict:
        if not self.verifiers:
            raise EntitlementError("no Apple root certificates installed (see server/README.md)")
        last = None
        for v in self.verifiers:
            try:
                t = v.verify_and_decode_signed_transaction(jws)
            except VerificationException as e:
                last = e
                continue
            if t.productId not in PRODUCT_IDS:
                raise EntitlementError("unknown product")
            if t.revocationDate:
                raise EntitlementError("transaction revoked")
            expires = None
            if t.expiresDate:
                expires = datetime.fromtimestamp(t.expiresDate / 1000, tz=timezone.utc).isoformat()
            env = t.rawEnvironment or (t.environment.value if t.environment else "Unknown")
            return {"original_transaction_id": str(t.originalTransactionId), "product_id": t.productId,
                    "expires_at": expires, "environment": env}
        raise EntitlementError(f"could not verify transaction: {getattr(last, 'status', last)}")
