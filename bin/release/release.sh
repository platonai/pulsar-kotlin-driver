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