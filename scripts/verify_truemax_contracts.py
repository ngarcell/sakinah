#!/usr/bin/env python3
"""Verify TrueMax release-critical identifiers, assets, and runtime boundaries.

This is a fast, Linux-runnable contract gate. It intentionally does not replace
an Xcode build, signing validation, physical-device camera testing, or
Apple/RevenueCat sandbox purchases.
"""

from __future__ import annotations

from collections import Counter, defaultdict
import hashlib
import json
from pathlib import Path
import plistlib
import re
import struct
import sys
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]

APP_BUNDLE_ID = "com.socialreporthq.sakinah"
UNIT_TEST_BUNDLE_ID = "com.socialreporthq.sakinah.tests"
UI_TEST_BUNDLE_ID = "com.socialreporthq.sakinah.uitests"

MONTHLY_PRODUCT_ID = "com.socialreporthq.sakinah.premium.monthly"
ANNUAL_PRODUCT_ID = "com.socialreporthq.sakinah.premium.annual"
LIFETIME_PRODUCT_ID = "com.socialreporthq.sakinah.premium.lifetimev2"
PRIMARY_ENTITLEMENT_ID = "Sakinah Premium"
FALLBACK_ENTITLEMENT_ID = "premium"

# RevenueCat mobile SDK keys are public app identifiers, not server secrets.
# Their full values are deliberately never printed in verifier diagnostics.
DEBUG_REVENUECAT_SDK_KEY = "test_uMjDbsOgwWFKjqUFhUDgiJAnBnj"
RELEASE_REVENUECAT_SDK_KEY = "appl_fbQPmfkwsuhasQyrthAyXiOhWxz"

APP_DISPLAY_NAME = "TrueMax"
CAMERA_USAGE_DESCRIPTION = (
    "TrueMax uses the camera to capture your face for private, on-device facial "
    "and style analysis. Your images are never uploaded."
)

SOURCE_DOCUMENT_HASHES = {
    "docs/01-PRD (1).md":
        "922919f6fc5dbc8a805796e621a9e80dd19b92850e719b49cbe8fd9a1351342b",
    "docs/02-UIUX-Specification.md":
        "34697197d3205a2f6ff9499808ca060991e571bf1adf5fe322f2038b04230184",
    "docs/03-App-Flow-Architecture.md":
        "e84b0a45c7085f4ff29aed4dc18368631ba15e1c599fe10cca9cf495be3dc6e9",
}

REFERENCE_IMAGE_HASHES = {
    "ChatGPT Image Jul 19, 2026, 02_37_22 PM (1).png":
        "f7726b85d8427e8783eb9b57d6d12b7d41dd0fdf4eab40d2c11d8b10a99224c8",
    "ChatGPT Image Jul 19, 2026, 02_37_22 PM (2).png":
        "134b8a93f5bfaf5c56d506262d11052de9d6c4a988bf7e9410034ef1cef89baf",
    "ChatGPT Image Jul 19, 2026, 02_37_23 PM (3).png":
        "911a0fb29b559296768ae74ac94fc15dbaaba7c2d351ff171f1ac671a949ab2e",
    "ChatGPT Image Jul 19, 2026, 02_37_23 PM (4).png":
        "bf3a36d6664efa1d3c6480613fda98fcf0dc65e0200711a64c83ed3ac328a40d",
    "ChatGPT Image Jul 19, 2026, 02_37_23 PM (5).png":
        "55ae73a8830cb96291f9004041500943c736ab1c0a55aacef7a2f4247be35415",
    "ChatGPT Image Jul 19, 2026, 02_37_24 PM (6).png":
        "82e1c7d9943e52edc65cc3098f506a45732aa977f56e5d449c9b45b2f89f6a03",
    "ChatGPT Image Jul 19, 2026, 02_37_24 PM (7).png":
        "02f0f2a2527f4005b92e609a350b811f794f9c02013eb691899b2f02fa2827bd",
    "ChatGPT Image Jul 19, 2026, 02_37_25 PM (8).png":
        "2f7ba658c423f9fc3601a07046f504e93d485188e8bfcd0d91ffa7a3055f9825",
    "ChatGPT Image Jul 19, 2026, 02_37_25 PM (9).png":
        "7da44759d83b0948b17a51f4bcbde1f1ab1f2843d34e3f96ab5e7fbec7754b50",
    "ChatGPT Image Jul 19, 2026, 02_37_26 PM (10).png":
        "7f76c7cb83dc58c13af258f76e2aa36b63ed25a460be6db2368900ea39b42cce",
    "ChatGPT Image Jul 19, 2026, 02_37_26 PM (11).png":
        "4cc32a43b8b6eea15482fa5a515691dd651db80820d280f86232c54d55e28748",
    "ChatGPT Image Jul 19, 2026, 02_37_27 PM (12).png":
        "f730b6f59360a068aee032d76747e6286e5e3c6ab6313167e1da335eaffdb10b",
    "ChatGPT Image Jul 19, 2026, 02_37_27 PM (13).png":
        "92ecd529982f7fb6f790a54e2196d864ee5a1b14b25bc48ab6b18284b371cb9f",
    "ChatGPT Image Jul 19, 2026, 02_37_28 PM (14).png":
        "c99c0e862d5caa7b8e6302b859994e30e0ac3d8aba16cd94146f883802f0565e",
    "ChatGPT Image Jul 19, 2026, 02_37_28 PM (15).png":
        "4aa946692a9f38c216fac7cf86ae962b97c62149321ceb4e6f00b9740a30e240",
    "ChatGPT Image Jul 19, 2026, 02_37_29 PM (16).png":
        "9bb38f68b191264b5fb1a6e0e01ba9fe442ca7a71aec22c33a2fae38e6f370e1",
    "ChatGPT Image Jul 19, 2026, 02_37_29 PM (17).png":
        "366cec97b87a0ef5d9aa980b9e030183cae7d8927a9682262dc145b1623f0839",
    "ChatGPT Image Jul 19, 2026, 02_37_29 PM (18).png":
        "e69638894c0043cb2ea41594746588af6e8c7e8135f06f0ba3fb470ece0ddede",
    "ChatGPT Image Jul 19, 2026, 02_37_30 PM (19).png":
        "4496ca07cadbc2b3537602e1a856ac3de3346f8a6a158f7e04cf121ad5bd6a12",
    "ChatGPT Image Jul 19, 2026, 02_37_30 PM (20).png":
        "d9f6127eecf905a2fc2f9bb37a26492f973ff2704db2a5d25e1ee1e889625c4f",
    "ChatGPT Image Jul 19, 2026, 02_37_31 PM (21).png":
        "4e03eac7781c6a2c834e45f501de90bcb202d7a5bf42f84b735212435ac2ba78",
    "ChatGPT Image Jul 19, 2026, 02_37_31 PM (22).png":
        "ca5587e6b0fabbe101d5420cfe5c367fb76e05fdd2b0a15dff8e16b56e938f67",
    "ChatGPT Image Jul 19, 2026, 02_37_31 PM (23).png":
        "69c66a2e83346843aa56061a5b4a129c3370c1591acec7398ec9ff7c556573e1",
}

SOURCE_APP_ICON_SHA256 = (
    "108b42da239ba4433adbb103e279e7c633ded672652aa3828ae6c9ded68656a1"
)
DEPLOYED_APP_ICON_SHA256 = (
    "dafdc39734e4deac0ef36588603a599d0128c3b0f32f1bc69d623581983fc9b4"
)


class ContractVerifier:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.passed: list[str] = []
        self.failures: list[str] = []

    def pass_contract(self, label: str) -> None:
        self.passed.append(label)

    def fail_contract(self, label: str, detail: str) -> None:
        self.failures.append(f"{label}: {detail}")

    def read_text(self, relative_path: str) -> str | None:
        path = self.root / relative_path
        try:
            return path.read_text(encoding="utf-8")
        except FileNotFoundError:
            self.fail_contract(relative_path, "required file is missing")
        except (OSError, UnicodeError) as error:
            self.fail_contract(relative_path, f"cannot read UTF-8 text ({error})")
        return None

    def read_bytes(self, relative_path: str) -> bytes | None:
        path = self.root / relative_path
        try:
            return path.read_bytes()
        except FileNotFoundError:
            self.fail_contract(relative_path, "required file is missing")
        except OSError as error:
            self.fail_contract(relative_path, f"cannot read file ({error})")
        return None

    def load_json(self, relative_path: str) -> Any | None:
        text = self.read_text(relative_path)
        if text is None:
            return None

        def reject_duplicate_keys(
            pairs: list[tuple[str, Any]],
        ) -> dict[str, Any]:
            result: dict[str, Any] = {}
            for key, value in pairs:
                if key in result:
                    raise ValueError(f"duplicate JSON key {key!r}")
                result[key] = value
            return result

        try:
            return json.loads(text, object_pairs_hook=reject_duplicate_keys)
        except (json.JSONDecodeError, ValueError) as error:
            self.fail_contract(relative_path, f"invalid JSON ({error})")
            return None

    def load_plist(self, relative_path: str) -> dict[str, Any] | None:
        raw = self.read_bytes(relative_path)
        if raw is None:
            return None
        try:
            document = plistlib.loads(raw)
        except Exception as error:
            self.fail_contract(relative_path, f"invalid plist ({error})")
            return None
        if not isinstance(document, dict):
            self.fail_contract(relative_path, "plist root must be a dictionary")
            return None
        return document

    @staticmethod
    def digest(data: bytes) -> str:
        return hashlib.sha256(data).hexdigest()

    @staticmethod
    def png_properties(data: bytes) -> tuple[int, int, int, int] | None:
        if (
            len(data) < 26
            or data[:8] != b"\x89PNG\r\n\x1a\n"
            or data[12:16] != b"IHDR"
        ):
            return None
        width, height = struct.unpack(">II", data[16:24])
        return width, height, data[24], data[25]

    def verify_source_materials(self) -> None:
        issues: list[str] = []

        for relative_path, expected_hash in SOURCE_DOCUMENT_HASHES.items():
            data = self.read_bytes(relative_path)
            if data is None:
                continue
            if self.digest(data) != expected_hash:
                issues.append(f"{relative_path} SHA-256 drifted")

        docs_dir = self.root / "docs"
        actual_reference_names = {
            path.name for path in docs_dir.glob("ChatGPT Image Jul 19, 2026, *.png")
        }
        expected_reference_names = set(REFERENCE_IMAGE_HASHES)
        if actual_reference_names != expected_reference_names:
            missing = sorted(expected_reference_names - actual_reference_names)
            unexpected = sorted(actual_reference_names - expected_reference_names)
            if missing:
                issues.append("missing reference images: " + ", ".join(missing))
            if unexpected:
                issues.append(
                    "unexpected matching reference images: " + ", ".join(unexpected)
                )

        for filename, expected_hash in REFERENCE_IMAGE_HASHES.items():
            relative_path = f"docs/{filename}"
            data = self.read_bytes(relative_path)
            if data is None:
                continue
            if self.digest(data) != expected_hash:
                issues.append(f"{filename} SHA-256 drifted")
                continue
            properties = self.png_properties(data)
            if properties is None:
                issues.append(f"{filename} is not a structurally valid PNG")
                continue
            width, height, bit_depth, color_type = properties
            expected_size = (852, 1846) if "(16)" in filename else (853, 1844)
            if (width, height) != expected_size:
                issues.append(
                    f"{filename} dimensions changed; expected "
                    f"{expected_size[0]}x{expected_size[1]}"
                )
            if (bit_depth, color_type) != (8, 2):
                issues.append(f"{filename} must remain an opaque 8-bit RGB PNG")

        source_icon = self.read_bytes("docs/ios app icon.png")
        if source_icon is not None:
            if self.digest(source_icon) != SOURCE_APP_ICON_SHA256:
                issues.append("supplied app-icon SHA-256 drifted")
            if self.png_properties(source_icon) != (1254, 1254, 8, 2):
                issues.append(
                    "supplied app icon must remain a 1254x1254 opaque 8-bit RGB PNG"
                )

        for deleted_legacy_doc in (
            "docs/brand-direction.md",
            "docs/competitor-audit.md",
        ):
            if (self.root / deleted_legacy_doc).exists():
                issues.append(
                    f"{deleted_legacy_doc} was intentionally deleted and must stay absent"
                )

        if issues:
            self.fail_contract("Source documents and supplied artwork", "; ".join(issues))
            return

        self.pass_contract("Three source-of-truth documents")
        self.pass_contract("All 23 supplied design-reference images")
        self.pass_contract("Supplied TrueMax app-icon master")
        self.pass_contract("Intentional legacy-document deletions")

    def verify_app_icon_catalog(self) -> None:
        catalog_path = "ios/Sakinah/Assets.xcassets/AppIcon.appiconset/Contents.json"
        document = self.load_json(catalog_path)
        icon = self.read_bytes(
            "ios/Sakinah/Assets.xcassets/AppIcon.appiconset/icon.png"
        )
        if document is None or icon is None:
            return

        expected = {
            "images": [
                {
                    "filename": "icon.png",
                    "idiom": "universal",
                    "platform": "ios",
                    "size": "1024x1024",
                }
            ],
            "info": {"author": "xcode", "version": 1},
        }
        issues: list[str] = []
        if document != expected:
            issues.append(
                "AppIcon Contents.json must reference one universal 1024x1024 icon.png"
            )
        if self.png_properties(icon) != (1024, 1024, 8, 2):
            issues.append("deployed icon must be a 1024x1024 opaque 8-bit RGB PNG")
        if self.digest(icon) != DEPLOYED_APP_ICON_SHA256:
            issues.append(
                "deployed TrueMax icon drifted from the exact 1024x1024 "
                "derivative of docs/ios app icon.png"
            )

        if issues:
            self.fail_contract("TrueMax app icon catalog", "; ".join(issues))
            return
        self.pass_contract("TrueMax app icon catalog and deployed asset")

    @staticmethod
    def _unquote_pbx_value(value: str) -> str:
        value = value.strip()
        if (
            len(value) >= 2
            and value[0] == value[-1]
            and value[0] in {'"', "'"}
        ):
            return value[1:-1]
        return value

    @classmethod
    def _parse_build_configurations(
        cls, project: str
    ) -> list[tuple[str, dict[str, str]]]:
        block_pattern = re.compile(
            r"""
            ^\s*[0-9A-F]+[ ]/\*[ ](?P<header>Debug|Release)[ ]\*/[ ]=[ ]\{
            \s*isa[ ]=[ ]XCBuildConfiguration;
            \s*buildSettings[ ]=[ ]\{
            (?P<settings>.*?)
            ^\s*\};
            \s*name[ ]=[ ](?P<name>Debug|Release);
            \s*\};
            """,
            re.MULTILINE | re.DOTALL | re.VERBOSE,
        )
        assignment_pattern = re.compile(
            r"^\s*([A-Za-z0-9_]+)\s*=\s*(.*?)\s*;\s*$",
            re.MULTILINE,
        )

        configurations: list[tuple[str, dict[str, str]]] = []
        for match in block_pattern.finditer(project):
            if match.group("header") != match.group("name"):
                continue
            settings = {
                key: cls._unquote_pbx_value(value)
                for key, value in assignment_pattern.findall(
                    match.group("settings")
                )
            }
            configurations.append((match.group("name"), settings))
        return configurations

    def verify_xcode_and_revenuecat_settings(self) -> None:
        project = self.read_text("ios/Sakinah.xcodeproj/project.pbxproj")
        if project is None:
            return
        configurations = self._parse_build_configurations(project)
        if not configurations:
            self.fail_contract(
                "Xcode protected settings",
                "could not parse Debug/Release XCBuildConfiguration blocks",
            )
            return

        by_bundle_id: dict[str, list[tuple[str, dict[str, str]]]] = defaultdict(list)
        for name, settings in configurations:
            bundle_id = settings.get("PRODUCT_BUNDLE_IDENTIFIER")
            if bundle_id:
                by_bundle_id[bundle_id].append((name, settings))

        expected_bundle_ids = {
            APP_BUNDLE_ID,
            UNIT_TEST_BUNDLE_ID,
            UI_TEST_BUNDLE_ID,
        }
        issues: list[str] = []
        if set(by_bundle_id) != expected_bundle_ids:
            missing = sorted(expected_bundle_ids - set(by_bundle_id))
            unexpected = sorted(set(by_bundle_id) - expected_bundle_ids)
            if missing:
                issues.append("missing protected bundle IDs: " + ", ".join(missing))
            if unexpected:
                issues.append("unexpected bundle IDs: " + ", ".join(unexpected))

        for bundle_id in sorted(expected_bundle_ids):
            names = Counter(name for name, _ in by_bundle_id.get(bundle_id, []))
            if names != Counter({"Debug": 1, "Release": 1}):
                issues.append(
                    f"{bundle_id} must occur once in Debug and once in Release"
                )

        app_configs = {
            name: settings for name, settings in by_bundle_id.get(APP_BUNDLE_ID, [])
        }
        expected_common = {
            "CFRevenueCatAppleAPIKey": RELEASE_REVENUECAT_SDK_KEY,
            "CFRevenueCatPremiumEntitlementID": PRIMARY_ENTITLEMENT_ID,
            "CFRevenueCatPremiumEntitlementFallbackIDs": FALLBACK_ENTITLEMENT_ID,
        }
        expected_per_configuration = {
            "Debug": {
                "CFRevenueCatAllowDebugOverrides": "YES",
                "CFRevenueCatDefaultAPIKey": DEBUG_REVENUECAT_SDK_KEY,
                "CFRevenueCatTestAPIKey": DEBUG_REVENUECAT_SDK_KEY,
                "CFRevenueCatRequireAppleKey": "NO",
            },
            "Release": {
                "CFRevenueCatAllowDebugOverrides": "NO",
                "CFRevenueCatDefaultAPIKey": RELEASE_REVENUECAT_SDK_KEY,
                "CFRevenueCatTestAPIKey": "",
                "CFRevenueCatRequireAppleKey": "YES",
            },
        }
        for name in ("Debug", "Release"):
            settings = app_configs.get(name)
            if settings is None:
                continue
            for key, expected_value in expected_common.items():
                if settings.get(key) != expected_value:
                    if "APIKey" in key:
                        issues.append(f"{name} RevenueCat Apple SDK key drifted")
                    else:
                        issues.append(f"{name} {key} drifted")
            for key, expected_value in expected_per_configuration[name].items():
                if settings.get(key) != expected_value:
                    if "APIKey" in key:
                        issues.append(f"{name} RevenueCat SDK key mapping drifted")
                    else:
                        issues.append(f"{name} {key} drifted")

        if issues:
            self.fail_contract(
                "Xcode bundle and RevenueCat settings",
                "; ".join(issues),
            )
            return

        self.pass_contract("App, unit-test, and UI-test bundle identifiers")
        self.pass_contract("RevenueCat Debug/Release public SDK key mapping")
        self.pass_contract("RevenueCat primary and fallback entitlements")

    def verify_product_catalog(self) -> None:
        relative_path = "ios/Sakinah/Services/SubscriptionService.swift"
        source = self.read_text(relative_path)
        if source is None:
            return

        expected_assignments = {
            "monthly": MONTHLY_PRODUCT_ID,
            "annual": ANNUAL_PRODUCT_ID,
            "lifetime": LIFETIME_PRODUCT_ID,
        }
        assignments = dict(
            re.findall(
                r'static\s+let\s+(monthly|annual|lifetime)\s*=\s*"([^"]+)"',
                source,
            )
        )
        issues: list[str] = []
        if assignments != expected_assignments:
            issues.append("monthly/annual/lifetime product constants drifted")

        full_ids = set(
            re.findall(
                r'"(com\.socialreporthq\.sakinah\.premium\.[^"]+)"',
                source,
            )
        )
        if full_ids != set(expected_assignments.values()):
            issues.append("unexpected or missing full RevenueCat product ID")

        if not re.search(
            r"sellablePlanProductIDs\s*:\s*Set<String>\s*=\s*\[\s*monthly\s*,\s*annual\s*\]",
            source,
        ):
            issues.append("only monthly and annual may be sellable")
        if (
            "customerInfo.nonSubscriptions" not in source
            or "ProductCatalog.lifetime" not in source
        ):
            issues.append("legacy lifetime ownership must remain restorable")

        if issues:
            self.fail_contract("RevenueCat product catalog", "; ".join(issues))
            return
        self.pass_contract("Monthly, annual, and legacy lifetime product IDs")
        self.pass_contract("Monthly/annual sellable plans and lifetime restoration")

    def verify_manifest_and_info(self) -> None:
        issues: list[str] = []

        rork = self.load_json("rork.json")
        expected_rork = {
            "$schema": "https://rork.com/schema/rork.json",
            "apps": [
                {"name": APP_DISPLAY_NAME, "path": "ios", "framework": "swift"}
            ],
        }
        if rork is not None and rork != expected_rork:
            issues.append("rork.json must describe exactly one TrueMax Swift app at ios")

        info = self.load_plist("ios/Sakinah/Info.plist")
        if info is not None:
            if info.get("CFBundleDisplayName") != APP_DISPLAY_NAME:
                issues.append("CFBundleDisplayName must be exactly TrueMax")
            if info.get("NSCameraUsageDescription") != CAMERA_USAGE_DESCRIPTION:
                issues.append(
                    "NSCameraUsageDescription must match the protected, "
                    "privacy-specific TrueMax copy"
                )

        if issues:
            self.fail_contract("TrueMax manifest and permission copy", "; ".join(issues))
            return
        self.pass_contract("TrueMax Rork manifest and display name")
        self.pass_contract("Protected TrueMax camera usage description")

    def discover_active_truemax_sources(self) -> dict[Path, str]:
        source_root = self.root / "ios/Sakinah"
        explicit_root = source_root / "TrueMax"
        paths: set[Path] = set(explicit_root.rglob("*.swift")) if explicit_root.is_dir() else set()

        for path in source_root.rglob("*.swift"):
            try:
                source = path.read_text(encoding="utf-8")
            except (OSError, UnicodeError):
                continue
            if "TrueMax" in source or "truemax" in source.lower():
                paths.add(path)

        sources: dict[Path, str] = {}
        for path in sorted(paths):
            try:
                sources[path] = path.read_text(encoding="utf-8")
            except (OSError, UnicodeError) as error:
                self.fail_contract(
                    "Active TrueMax source discovery",
                    f"cannot read {path.relative_to(self.root)} ({error})",
                )
        return sources

    def verify_custom_paywall(self, sources: dict[Path, str]) -> None:
        paywall_sources = {
            path: source
            for path, source in sources.items()
            if "paywall" in path.name.lower()
                or re.search(r"struct\s+\w*Paywall\w*\s*:\s*View", source)
        }
        if not paywall_sources:
            self.fail_contract(
                "Custom annual-default paywall",
                "no active TrueMax SwiftUI paywall source was found",
            )
            return

        joined = "\n".join(paywall_sources.values())
        issues: list[str] = []
        hosted_patterns = (
            r"\bRevenueCatUI\.PaywallView\s*\(",
            r"(?<!\w)PaywallView\s*\(\s*offering\s*:",
        )
        if any(re.search(pattern, joined) for pattern in hosted_patterns):
            issues.append("hosted RevenueCatUI.PaywallView usage remains")
        if not re.search(r"struct\s+\w*Paywall\w*\s*:\s*View", joined):
            issues.append("paywall must be custom SwiftUI")

        annual_default_patterns = (
            r"@State[^\n]*selected\w*[^\n]*=\s*\.annual\b",
            r"@State[^\n]*selected\w*[^\n]*=\s*SubscriptionService\.annualProductID\b",
            r"selected(?:Plan|Product|ProductID|Package)\s*=\s*\.annual\b",
            r"selected(?:Plan|Product|ProductID|Package)\s*=\s*SubscriptionService\.annualProductID\b",
        )
        if not any(
            re.search(pattern, joined, re.IGNORECASE)
            for pattern in annual_default_patterns
        ):
            issues.append("annual is not demonstrably the initial selected plan")

        if not (
            re.search(r"\bmonthly\b", joined, re.IGNORECASE)
            and re.search(r"\bannual\b", joined, re.IGNORECASE)
        ):
            issues.append("custom paywall must expose monthly and annual choices")
        if "Restore" not in joined:
            issues.append("custom paywall must expose Restore Purchases")

        if issues:
            self.fail_contract("Custom annual-default paywall", "; ".join(issues))
            return
        self.pass_contract("Custom SwiftUI paywall without hosted PaywallView")
        self.pass_contract("Monthly/annual choices with annual selected by default")

        eligibility_markers = (
            "case .eligible:",
            "return TrueMaxPaywallCopy.annualTrialCTA",
            "case .ineligible:",
            'return "Continue Pro — Annual"',
            'purchaseTerms: "Starts immediately at',
            "accessDetail: annualPlanAccessDetail",
            "trialEligibility(for: .annual)",
            "annualTrialEligibility == .unavailable",
            "annualTrialEligibility == .checking",
            "guard selectedPlan == .annual else",
        )
        missing_eligibility_markers = [
            marker for marker in eligibility_markers if marker not in joined
        ]
        if (
            missing_eligibility_markers
            or 'details.plan == .annual\n                    ? "3 days free' in joined
        ):
            detail = ", ".join(missing_eligibility_markers)
            if not detail:
                detail = "annual plan card still has unconditional free-trial copy"
            self.fail_contract(
                "Eligible-only annual trial presentation",
                detail,
            )
        else:
            self.pass_contract("Eligible-only annual trial presentation")

    def verify_local_runtime(self, sources: dict[Path, str]) -> None:
        if not sources:
            self.fail_contract(
                "Active TrueMax runtime",
                "no active TrueMax Swift source was found",
            )
            return

        joined = "\n".join(sources.values())
        issues: list[str] = []
        if "ModelConfiguration" not in joined:
            issues.append("active TrueMax source has no explicit ModelConfiguration")
        if not re.search(
            r"cloudKitDatabase\s*:\s*\.none\b",
            joined,
        ):
            issues.append("SwiftData must explicitly use cloudKitDatabase: .none")

        forbidden_patterns = {
            "CloudKit import/runtime": (
                r"\bimport\s+CloudKit\b",
                r"\bCKContainer\b",
                r"\bCKDatabase\b",
                r"\bCKRecord\b",
                r"\bCloudKitService\b",
            ),
            "authentication runtime": (
                r"\bimport\s+AuthenticationServices\b",
                r"\bASAuthorization\w*\b",
                r"\bSignInWithApple\w*\b",
                r"\bAuthService\b",
                r"\bAuthenticationService\b",
            ),
        }
        for label, patterns in forbidden_patterns.items():
            matches = [
                pattern for pattern in patterns if re.search(pattern, joined)
            ]
            if matches:
                issues.append(f"{label} found in active TrueMax source")

        if issues:
            self.fail_contract("Local-only TrueMax runtime", "; ".join(issues))
            return
        self.pass_contract("Explicit local-only SwiftData configuration")
        self.pass_contract("No CloudKit or authentication runtime")

        analytics_source = next(
            (
                source
                for path, source in sources.items()
                if path.name == "TrueMaxAnalytics.swift"
            ),
            "",
        )
        if (
            "import PostHog" in analytics_source
            or "PostHogSDK.shared.setup" in analytics_source
            or "PostHogSDK.shared.capture" in analytics_source
            or "func configure() {}" not in analytics_source
        ):
            self.fail_contract(
                "No product analytics runtime",
                "TrueMaxAnalytics must remain a no-op with no PostHog SDK calls",
            )
        else:
            self.pass_contract("No product analytics runtime")

        if not (
            re.search(
                r"enum\s+SubscriptionTier\s*:\s*String[^{]*\{",
                joined,
            )
            and re.search(r"\bcase\s+free\b", joined)
            and re.search(r"\bcase\s+premium\b", joined)
        ):
            self.fail_contract(
                "Subscription entitlement compatibility state",
                "SubscriptionTier must retain free/premium raw values used by SubscriptionService",
            )
        else:
            self.pass_contract("Subscription entitlement compatibility state")

        onboarding_source = next(
            (
                source
                for path, source in sources.items()
                if path.name == "TrueMaxOnboardingFlow.swift"
            ),
            "",
        )
        content_source = next(
            (
                source
                for path, source in sources.items()
                if path.name == "ContentView.swift"
            ),
            "",
        )
        bypass_markers = (
            "truemax.skipOnboarding",
            "skipToWalkthrough",
            'Button("Skip")',
        )
        bypasses = [
            marker
            for marker in bypass_markers
            if marker in onboarding_source or marker in content_source
        ]
        if bypasses:
            self.fail_contract(
                "Adult and reverse-trial gates cannot be skipped",
                f"shipping bypass markers found: {', '.join(bypasses)}",
            )
        else:
            self.pass_contract("Adult and reverse-trial gates cannot be skipped")

        app_state_source = next(
            (
                source
                for path, source in sources.items()
                if path.name == "TrueMaxAppState.swift"
            ),
            "",
        )
        scan_source = next(
            (
                source
                for path, source in sources.items()
                if path.name == "TrueMaxScanFlow.swift"
            ),
            "",
        )
        if (
            "func recordReverseTrialResult()" not in app_state_source
            or "appState.recordReverseTrialResult()" not in scan_source
        ):
            self.fail_contract(
                "Saved result consumes the one-result allowance",
                "the allowance must persist when the result is saved, before paywall presentation",
            )
        else:
            self.pass_contract("Saved result consumes the one-result allowance")

        if (
            "appState.requiresMedicalDisclaimer" not in content_source
            or "appState.acknowledgeDisclaimer()" not in content_source
        ):
            self.fail_contract(
                "Medical disclaimer acknowledgement is enforced",
                "the persisted disclaimer state must be presented and acknowledged",
            )
        else:
            self.pass_contract("Medical disclaimer acknowledgement is enforced")

        if (
            "else if !subscriptionService.isPremium" not in content_source
            or "showsCloseButton: false" not in content_source
        ):
            self.fail_contract(
                "Completed workspace is behind the hard paywall",
                "completed non-premium users must see a non-dismissible paywall",
            )
        else:
            self.pass_contract("Completed workspace is behind the hard paywall")

    def verify_metadata_document(self) -> None:
        source = self.read_text("docs/app-store-metadata.md")
        if source is None:
            return

        required_snippets = (
            "TrueMax",
            "RevenueCat",
            "facial images and measurements are never attached",
            "Monthly and annual plans are available, with annual selected by default.",
            "https://socialreporthq.com/sakinah/privacy",
            "https://socialreporthq.com/sakinah/terms",
            "https://socialreporthq.com/sakinah/support",
        )
        issues = [
            f"missing required metadata statement: {snippet}"
            for snippet in required_snippets
            if snippet not in source
        ]

        fenced_blocks = re.findall(r"```text\n(.*?)\n```", source, re.DOTALL)
        if len(fenced_blocks) < 6:
            issues.append("expected name, subtitle, promo, description, keywords, and What's New blocks")
        else:
            name, subtitle, promo, description, keywords, whats_new = fenced_blocks[:6]
            if len(name) > 30:
                issues.append("recommended name exceeds 30 characters")
            if len(subtitle) > 30:
                issues.append("recommended subtitle exceeds 30 characters")
            if len(promo) > 170:
                issues.append("Promotional Text exceeds 170 characters")
            if len(description) > 4000:
                issues.append("Description exceeds 4,000 characters")
            if len(keywords.encode("utf-8")) > 100:
                issues.append("Keywords exceed 100 UTF-8 bytes")
            if len(whats_new) > 4000:
                issues.append("What's New exceeds 4,000 characters")

        if issues:
            self.fail_contract("App Store metadata", "; ".join(issues))
            return
        self.pass_contract("ASO metadata field limits and subscription truthfulness")

    def run(self) -> int:
        self.verify_source_materials()
        self.verify_app_icon_catalog()
        self.verify_xcode_and_revenuecat_settings()
        self.verify_product_catalog()
        self.verify_manifest_and_info()

        active_sources = self.discover_active_truemax_sources()
        self.verify_custom_paywall(active_sources)
        self.verify_local_runtime(active_sources)
        self.verify_metadata_document()

        total = len(self.passed) + len(self.failures)
        print(
            f"TrueMax contract verification: {len(self.passed)}/{total} "
            "contract groups passed."
        )
        for label in self.passed:
            print(f"PASS: {label}")
        for failure in self.failures:
            print(f"FAIL: {failure}")

        if self.failures:
            print(
                "\nContract verification failed. Resolve every failure before "
                "shipping; this gate does not replace an Xcode build or device QA."
            )
            return 1

        print(
            "\nAll protected TrueMax contracts passed. Continue with Xcode, "
            "physical-device, accessibility, and RevenueCat sandbox validation."
        )
        return 0


if __name__ == "__main__":
    sys.exit(ContractVerifier(REPO_ROOT).run())
