# bin\release\release.ps1
param(
    [Parameter(Mandatory = $true)]
    [string]$ReleaseVersion,
    [Parameter(Mandatory = $true)]
    [string]$NextVersion
)

Write-Host "🚀 Starting release process..."
Write-Host "Release version: $ReleaseVersion"
Write-Host "Next version: $NextVersion"

# 检查工作区是否干净
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "❌ Working directory is not clean. Please commit or stash changes."
    exit 1
}

# 更新为发布版本
Write-Host "📝 Updating version to $ReleaseVersion"
mvn versions:set -DnewVersion=$ReleaseVersion
mvn versions:commit

# 构建和测试
Write-Host "🔨 Building and testing..."
mvn clean verify -Pci

# 部署到 Sonatype staging
Write-Host "📦 Deploying to Sonatype staging..."
mvn clean deploy -Pdeploy

# 提交并打标签
Write-Host "📋 Creating release commit and tag..."
git add .
git commit -m "Release version $ReleaseVersion"
git tag -a "v$ReleaseVersion" -m "Release version $ReleaseVersion"

# 更新为下一个开发版本
Write-Host "⏭️ Updating to next development version..."
mvn versions:set -DnewVersion=$NextVersion
mvn versions:commit
git add .
git commit -m "Bump version to $NextVersion"

# 推送到 GitHub
Write-Host "⬆️ Pushing to GitHub..."
git push origin main
git push origin "v$ReleaseVersion"

Write-Host "✅ Release process completed!"
Write-Host "Next steps:"
Write-Host "1. Go to https://s01.oss.sonatype.org/"
Write-Host "2. Log in and navigate to Staging Repositories"
Write-Host "3. Find your repository, close it, then release it"
Write-Host "4. Create GitHub release notes"