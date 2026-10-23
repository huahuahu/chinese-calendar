# Scripts

Utility scripts for fetching, normalizing, generating app-ready data, and validating local/CI builds.

`validate_navigation_public_api.py` checks the public NavigationCore API against existing Simulator build products. It uses ordinary `import NavigationCore`: supported calls must compile, and each negative sample must fail with the expected access or missing-symbol diagnostic. Build the Debug Simulator modules first, then run:

```bash
python3 Scripts/validate_navigation_public_api.py \
  <Build/Products/Debug-iphonesimulator> \
  <iPhoneSimulator.sdk> \
  arm64-apple-ios26.0-simulator
```

Use the SDK and target that match the build. Reports and generated samples go to `.output/navigation-public-api/`; the script does not rebuild any target. Fixtures live in `Scripts/NavigationCoreAPI/`.

The former `validate_navigation_identity_types.py` was retired when Issue #165 made Core presentation identities internal and removed App session identities. Issue #166 evidence retains the historical verifier name; internal identity behavior remains covered by `NavigationIdentityTests.swift`.
