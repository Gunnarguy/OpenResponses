# CI/CD Pipeline Documentation

This document explains the continuous integration and deployment setup for OpenResponses.

## Overview

The project uses **GitHub Actions** for automated testing, linting, and release preparation. The pipeline runs on every push and pull request to ensure code quality and catch issues early.

## Workflows

### 1. iOS CI (`ios-ci.yml`)

**Triggers:** Push to any branch, PRs to `main`

**Jobs:**

#### Build and Test
- Runs on macOS 14 (latest GitHub Actions runner)
- Uses Xcode 16.1
- Builds the project for iOS Simulator (iPhone 16 Pro)
- Runs all unit tests (`OpenResponsesTests`)
- Uploads test results as artifacts (retained for 30 days)
- Reports build warnings

**Key Commands:**
```bash
xcodebuild build-for-testing \
  -project OpenResponses.xcodeproj \
  -scheme OpenResponses \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.1'
```

#### Lint
- Installs and runs SwiftLint
- Checks code style and best practices
- Configuration: `.swiftlint.yml`
- Reports violations but doesn't fail the build

#### Security Scan
- Scans for exposed API keys (`sk-*` patterns)
- Checks for hardcoded secrets
- Verifies no `.env` files are committed
- Fails the build if secrets are found

#### Markdown Lint
- Validates all markdown documentation
- Ensures consistent formatting
- Continues on error (non-blocking)

### 2. Release Preparation (`release-check.yml`)

**Triggers:** Push to `release/*` branches, version tags (`v*`)

**Jobs:**

#### Version Consistency Check
- Extracts version from Xcode project
- Verifies release notes exist for the version
- Ensures `PRIVACY.md` is present
- Checks for TODO/FIXME comments

#### Archive Build
- Creates a production-like archive build
- Reports archive size
- Validates build configuration

#### Documentation Validation
- Checks for required documentation files:
  - `README.md`
  - `LICENSE`
  - `PRIVACY.md`
  - `docs/ROADMAP.md`
  - `docs/AppStoreMetadata.md`
  - `docs/AppStoreReleasePlan.md`
- Validates internal links in markdown files

#### App Store Readiness Check
- Verifies Info.plist privacy descriptions
- Checks for AppIcon (1024×1024)
- Validates bundle ID format
- Confirms deployment target (iOS 17.0)

## Local Development

### Running Tests Locally

```bash
# Build and test
xcodebuild test \
  -project OpenResponses.xcodeproj \
  -scheme OpenResponses \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'

# Or use Xcode: Cmd+U
```

### Running SwiftLint

```bash
# Install (if not already installed)
brew install swiftlint

# Lint all files
swiftlint

# Auto-fix issues where possible
swiftlint --fix

# Lint specific file
swiftlint lint --path OpenResponses/App/OpenResponsesApp.swift
```

### Security Scanning

```bash
# Check for exposed secrets
grep -r "sk-[a-zA-Z0-9]\{48\}" --include="*.swift" --include="*.json" .

# Verify .env files are gitignored
git check-ignore .env test.env
```

## Adding New Tests

When adding new test files:

1. Create test file in `OpenResponsesTests/`
2. Import `@testable import OpenResponses`
3. Inherit from `XCTestCase`
4. Name test methods with `test` prefix
5. CI will automatically run new tests

Example:
```swift
import XCTest
@testable import OpenResponses

final class MyNewTests: XCTestCase {
    func testSomething() {
        XCTAssertTrue(true)
    }
}
```

## Continuous Deployment (Future)

### TestFlight Deployment (Planned)

Future enhancement will add automatic TestFlight uploads:

```yaml
- name: Upload to TestFlight
  uses: apple-actions/upload-testflight-build@v1
  with:
    app-path: OpenResponses.ipa
    issuer-id: ${{ secrets.APPSTORE_ISSUER_ID }}
    api-key-id: ${{ secrets.APPSTORE_API_KEY_ID }}
    api-private-key: ${{ secrets.APPSTORE_API_PRIVATE_KEY }}
```

**Required Secrets:**
- `APPSTORE_ISSUER_ID` - App Store Connect API Issuer ID
- `APPSTORE_API_KEY_ID` - App Store Connect API Key ID
- `APPSTORE_API_PRIVATE_KEY` - App Store Connect API Private Key

### Fastlane Integration (Alternative)

Can use Fastlane for more advanced workflows:

```ruby
# fastlane/Fastfile
lane :beta do
  build_app(scheme: "OpenResponses")
  upload_to_testflight
  slack(message: "New TestFlight build available!")
end
```

## Troubleshooting

### Build Failures

**Issue:** Code signing errors
**Solution:** CI uses `CODE_SIGNING_REQUIRED=NO` for simulator builds

**Issue:** Test timeouts
**Solution:** Increase timeout or check for network dependencies

**Issue:** Missing simulator
**Solution:** Update destination to available simulator in workflow

### SwiftLint Errors

**Issue:** Too many violations
**Solution:** Run `swiftlint --fix` to auto-correct

**Issue:** Rule conflicts
**Solution:** Update `.swiftlint.yml` to disable conflicting rules

### Security Scan False Positives

**Issue:** Scanner flags non-secret patterns
**Solution:** Update regex in `ios-ci.yml` security-scan job

## Monitoring

### GitHub Actions Dashboard

View workflow runs at:
```
https://github.com/Gunnarguy/OpenResponses/actions
```

### Artifacts

Test results are uploaded as artifacts and retained for 30 days:
- Download `.xcresult` bundle
- Open in Xcode: `xcodebuild -resultBundlePath TestResults.xcresult`

### Notifications

Failed builds trigger:
- GitHub UI notifications
- Email to commit author (if configured)

## Best Practices

1. **Run tests locally before pushing**
   ```bash
   xcodebuild test -project OpenResponses.xcodeproj -scheme OpenResponses
   ```

2. **Fix SwiftLint warnings incrementally**
   - Don't disable all rules
   - Configure thresholds in `.swiftlint.yml`

3. **Keep CI fast**
   - Use cached dependencies
   - Parallelize independent jobs
   - Don't run tests on documentation-only changes

4. **Secure secrets**
   - Never commit API keys
   - Use GitHub Secrets for sensitive data
   - Verify with security scan job

5. **Document breaking changes**
   - Update this doc when changing workflows
   - Note required environment changes

## Performance

Current CI execution times (approximate):

- **Build and Test:** 8-12 minutes
- **Lint:** 2-3 minutes
- **Security Scan:** < 1 minute
- **Release Check:** 5-7 minutes

**Total for typical push:** ~15 minutes

## Future Enhancements

- [ ] Add code coverage reporting
- [ ] Integrate with Codecov or similar
- [ ] Add performance benchmarks
- [ ] Deploy to TestFlight automatically
- [ ] Add screenshot generation tests
- [ ] Implement UI regression testing
- [ ] Add static analysis (SwiftFormat)
- [ ] Create release notes automatically from commits

---

**Last Updated:** 2025-11-08  
**Maintained By:** Development Team  
**Questions?** Open an issue or check GitHub Actions logs
