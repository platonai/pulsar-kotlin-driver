## 🚀 Complete Release & Deployment Guide

### 1. **Prerequisites Setup**

#### A. **GPG Key Setup**
```bash
# Generate GPG key (if you don't have one)
gpg --gen-key

# List your keys
gpg --list-secret-keys --keyid-format LONG

# Export public key to keyserver
gpg --keyserver keyserver.ubuntu.com --send-keys YOUR_KEY_ID

# Export private key for backup
gpg --export-secret-keys YOUR_KEY_ID > private-key.asc
```

#### B. **Sonatype OSSRH Account**
1. Create account at: https://issues.sonatype.org/
2. Create a JIRA ticket to claim your `ai.platon.pulsar` namespace
3. Wait for approval (usually 2 business days)

#### C. **Maven Settings Configuration**
Create/update `~/.m2/settings.xml`:

```xml name=~/.m2/settings.xml
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 
          http://maven.apache.org/xsd/settings-1.0.0.xsd">

    <servers>
        <server>
            <id>ossrh</id>
            <username>your-sonatype-username</username>
            <password>your-sonatype-password</password>
        </server>
        <server>
            <id>gpg.passphrase</id>
            <passphrase>your-gpg-passphrase</passphrase>
        </server>
    </servers>

    <profiles>
        <profile>
            <id>ossrh</id>
            <activation>
                <activeByDefault>true</activeByDefault>
            </activation>
            <properties>
                <gpg.executable>gpg</gpg.executable>
                <gpg.keyname>YOUR_GPG_KEY_ID</gpg.keyname>
                <gpg.passphrase>your-gpg-passphrase</gpg.passphrase>
            </properties>
        </profile>
    </profiles>
</settings>
```

### 2. **Environment Variables Setup**

```bash
# Set environment variables (recommended for CI/CD)
export GPG_PASSPHRASE="your-gpg-passphrase"
export SONATYPE_USERNAME="your-sonatype-username"
export SONATYPE_PASSWORD="your-sonatype-password"

# Or add to your shell profile (.bashrc, .zshrc, etc.)
echo 'export GPG_PASSPHRASE="your-gpg-passphrase"' >> ~/.bashrc
```

### 3. **Pre-Release Checklist**

```bash
# 1. Ensure clean working directory
git status

# 2. Update version (remove SNAPSHOT)
# Edit pom.xml: 1.7.0-SNAPSHOT → 1.7.0

# 3. Run full build and tests
mvn clean verify

# 4. Check dependency updates
mvn versions:display-dependency-updates
mvn versions:display-plugin-updates

# 5. Run license check
mvn license:check

# 6. Generate and review documentation
mvn dokka:dokka

# 7. Verify GPG signing works
mvn clean package -Pdeploy -DskipTests
```

### 4. **Release Process Options**

#### **Option A: Manual Release (Recommended for First Release)**

```bash
# Step 1: Update version to release version
mvn versions:set -DnewVersion=1.7.0
mvn versions:commit

# Step 2: Build and test
mvn clean verify

# Step 3: Deploy to staging repository
mvn clean deploy -Pdeploy

# Step 4: Log into Sonatype Nexus
# Go to: https://s01.oss.sonatype.org/
# Navigate to "Staging Repositories"
# Find your repository, close it, then release it

# Step 5: Tag the release
git add .
git commit -m "Release version 1.7.0"
git tag -a v1.7.0 -m "Release version 1.7.0"

# Step 6: Update to next development version
mvn versions:set -DnewVersion=1.7.1-SNAPSHOT
mvn versions:commit
git add .
git commit -m "Bump version to 1.7.1-SNAPSHOT"

# Step 7: Push everything
git push origin main
git push origin v1.7.0
```

#### **Option B: Using Maven Release Plugin (Automated)**

```bash
# Configure Git (if not already done)
git config user.name "Vincent Zhang"
git config user.email "ivincent.zhang@gmail.com"

# Perform release (interactive)
mvn clean release:prepare release:perform -Prelease,deploy

# Or non-interactive with version specified
mvn clean release:prepare release:perform \
  -Prelease,deploy \
  -DreleaseVersion=1.7.0 \
  -DdevelopmentVersion=1.7.1-SNAPSHOT \
  -Dtag=v1.7.0 \
  -Darguments="-DskipTests=false"
```

### 5. **GitHub Actions Workflow for Automated Release**

Create `.github/workflows/release.yml`:

```yaml name=.github/workflows/release.yml
name: Release to Maven Central

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Set up JDK 11
        uses: actions/setup-java@v4
        with:
          java-version: '11'
          distribution: 'temurin'
          server-id: ossrh
          server-username: MAVEN_USERNAME
          server-password: MAVEN_PASSWORD

      - name: Cache Maven dependencies
        uses: actions/cache@v4
        with:
          path: ~/.m2
          key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
          restore-keys: ${{ runner.os }}-m2

      - name: Configure GPG Key
        env:
          GPG_SIGNING_KEY: ${{ secrets.GPG_SIGNING_KEY }}
          GPG_PASSPHRASE: ${{ secrets.GPG_PASSPHRASE }}
        run: |
          echo -n "$GPG_SIGNING_KEY" | base64 --decode | gpg --import
          echo "GPG key imported successfully"

      - name: Build and Test
        run: mvn clean verify -Pci

      - name: Deploy to Maven Central
        env:
          MAVEN_USERNAME: ${{ secrets.OSSRH_USERNAME }}
          MAVEN_PASSWORD: ${{ secrets.OSSRH_TOKEN }}
          GPG_PASSPHRASE: ${{ secrets.GPG_PASSPHRASE }}
        run: |
          mvn clean deploy -Pdeploy \
            -DskipTests=true \
            -Dgpg.passphrase="${GPG_PASSPHRASE}"

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            target/*.jar
          generate_release_notes: true
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### 6. **GitHub Secrets Configuration**

Add these secrets to your GitHub repository (`Settings` → `Secrets and variables` → `Actions`):

```
OSSRH_USERNAME: your-sonatype-username
OSSRH_TOKEN: your-sonatype-token
GPG_SIGNING_KEY: base64-encoded-private-key
GPG_PASSPHRASE: your-gpg-passphrase
```

To get the base64-encoded GPG key:
```bash
gpg --export-secret-keys YOUR_KEY_ID | base64 | tr -d '\n'
```

### 7. **Verification Steps**

After deployment, verify your release:

```bash
# Check if artifacts are available
curl -I "https://repo1.maven.org/maven2/ai/platon/pulsar/pulsar-kotlin-driver/1.7.0/pulsar-kotlin-driver-1.7.0.jar"

# Test dependency resolution
mvn dependency:get -Dartifact=ai.platon.pulsar:pulsar-kotlin-driver:1.7.0

# Check in search.maven.org
# Visit: https://search.maven.org/search?q=g:ai.platon.pulsar
```

### 8. **Troubleshooting Common Issues**

#### **GPG Issues**
```bash
# If GPG signing fails
export GPG_TTY=$(tty)
echo "use-agent" >> ~/.gnupg/gpg.conf
echo "pinentry-mode loopback" >> ~/.gnupg/gpg.conf

# Test GPG signing
echo "test" | gpg --clearsign
```

#### **Sonatype Issues**
```bash
# Check staging repository status
curl -u username:password \
  "https://s01.oss.sonatype.org/service/local/staging/profile_repositories"

# Close staging repository manually
mvn nexus-staging:close -DstagingRepositoryId=YOUR_REPO_ID

# Release staging repository
mvn nexus-staging:release -DstagingRepositoryId=YOUR_REPO_ID
```

#### **Version Issues**
```bash
# Reset version if release fails
mvn versions:set -DnewVersion=1.7.0-SNAPSHOT
mvn versions:commit

# Clean up failed release
mvn release:clean
git tag -d v1.7.0
git reset --hard HEAD~2
```

### 9. **Post-Release Tasks**

```bash
# Update documentation
# Update README.md with new version
# Update CHANGELOG.md

# Announce release
# Create GitHub release notes
# Update project website
# Send notifications
```

### 10. **Quick Release Script**

Create `scripts/release.sh`:

```bash name=scripts/release.sh
#!/bin/bash
set -e

RELEASE_VERSION=$1
NEXT_VERSION=$2

if [ -z "$RELEASE_VERSION" ] || [ -z "$NEXT_VERSION" ]; then
    echo "Usage: $0 <release-version> <next-version>"
    echo "Example: $0 1.7.0 1.7.1-SNAPSHOT"
    exit 1
fi

echo "🚀 Starting release process..."
echo "Release version: $RELEASE_VERSION"
echo "Next version: $NEXT_VERSION"

# Verify clean working directory
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ Working directory is not clean. Please commit or stash changes."
    exit 1
fi

# Update to release version
echo "📝 Updating version to $RELEASE_VERSION"
mvn versions:set -DnewVersion=$RELEASE_VERSION
mvn versions:commit

# Build and test
echo "🔨 Building and testing..."
mvn clean verify -Pci

# Deploy to staging
echo "📦 Deploying to Sonatype staging..."
mvn clean deploy -Pdeploy

# Commit and tag
echo "📋 Creating release commit and tag..."
git add .
git commit -m "Release version $RELEASE_VERSION"
git tag -a "v$RELEASE_VERSION" -m "Release version $RELEASE_VERSION"

# Update to next development version
echo "⏭️ Updating to next development version..."
mvn versions:set -DnewVersion=$NEXT_VERSION
mvn versions:commit
git add .
git commit -m "Bump version to $NEXT_VERSION"

# Push everything
echo "⬆️ Pushing to GitHub..."
git push origin main
git push origin "v$RELEASE_VERSION"

echo "✅ Release process completed!"
echo "Next steps:"
echo "1. Go to https://s01.oss.sonatype.org/"
echo "2. Log in and navigate to Staging Repositories"
echo "3. Find your repository, close it, then release it"
echo "4. Create GitHub release notes"
```

Make it executable and use it:
```bash
chmod +x scripts/release.sh
./scripts/release.sh 1.7.0 1.7.1-SNAPSHOT
```

This comprehensive guide covers all aspects of releasing your Kotlin driver to Maven Central. The process typically takes 15-30 minutes for the deployment, plus 2-4 hours for the artifacts to sync to Maven Central.
