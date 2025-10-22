#!/usr/bin/env bash
set -euo pipefail

# Configuration - EDIT THESE
GITHUB_USER_OR_ORG="your-username-or-org"
GITHUB_TOKEN="ghp_xxx"         # or export GITHUB_TOKEN in environment and set empty here
BACKUP_DIR="$HOME/github-backups"
STATE_DIR="$BACKUP_DIR/.state"
TMP_DIR="$BACKUP_DIR/.tmp"
GPG_PASSPHRASE="change-this-to-strong-passphrase"   # prefer using GPG agent or file with restricted perms
COMPRESS_CMD="zstd -T0 -19 -c"  # uses zstd multithreaded; change to gzip if needed: "gzip -c"
# Archive name pattern: repo-mirror-<yyyy-mm-dd>-<shortsha>.tar.zst.gpg
DATE_CMD="$(date +%F-%H%M%S)"
# Choose API: repos for user/org; this script handles both users and orgs by calling the repos endpoint.
API_BASE="https://api.github.com"

# Helpers
mkdir -p "$BACKUP_DIR" "$STATE_DIR" "$TMP_DIR"
[ -n "${GITHUB_TOKEN:-}" ] || { echo "GITHUB_TOKEN not set; set it in script or env"; exit 1; }

auth_header="Authorization: token ${GITHUB_TOKEN}"

# Fetch repository list (handles pagination)
fetch_repos() {
  page=1
  per_page=100
  repos=()
  while :; do
    resp=$(curl -sS -H "$auth_header" "$API_BASE/users/$GITHUB_USER_OR_ORG/repos?per_page=$per_page&page=$page" )
    # If org, try org endpoint
    if [[ $(echo "$resp" | jq -r '.[0].full_name // empty') == "" && $page -eq 1 ]]; then
      resp=$(curl -sS -H "$auth_header" "$API_BASE/orgs/$GITHUB_USER_OR_ORG/repos?per_page=$per_page&page=$page")
    fi
    count=$(echo "$resp" | jq 'length')
    if [ "$count" -eq 0 ]; then
      break
    fi
    # append clone_url and name
    while IFS= read -r row; do
      repos+=("$row")
    done < <(echo "$resp" | jq -r '.[] | "\(.name) \(.mirror_url // empty) \(.clone_url)"')
    ((page++))
  done
  printf "%s\n" "${repos[@]}"
}

# Get latest commit SHA of default branch (remote)
get_remote_latest_sha() {
  repo_fullname="$1"   # owner/name
  # Use commits API for default branch
  curl -sS -H "$auth_header" "$API_BASE/repos/$repo_fullname/commits" | jq -r '.[0].sha' 2>/dev/null || echo ""
}

# Main loop
while IFS= read -r line; do
  # line format: "name mirror_url clone_url"
  repo_name=$(echo "$line" | awk '{print $1}')
  mirror_url=$(echo "$line" | awk '{print $2}')
  clone_url=$(echo "$line" | awk '{print $3}')
  # Build owner/name for API queries
  # If input was "repo-name", derive owner from GITHUB_USER_OR_ORG
  repo_fullname="$GITHUB_USER_OR_ORG/$repo_name"
  echo "Processing $repo_fullname"

  state_file="$STATE_DIR/${repo_fullname//\//__}.lastsha"
  repo_dir="$BACKUP_DIR/mirrors/${repo_fullname//\//__}.git"
  mkdir -p "$(dirname "$repo_dir")"

  # Get remote latest sha via GitHub API
  latest_sha=$(curl -sS -H "$auth_header" "$API_BASE/repos/$repo_fullname/commits" | jq -r '.[0].sha' 2>/dev/null || echo "")
  if [ -z "$latest_sha" ]; then
    echo "  Warning: could not fetch latest commit SHA for $repo_fullname; skipping"
    continue
  fi

  prev_sha=""
  [ -f "$state_file" ] && prev_sha=$(cat "$state_file")
  if [ "$prev_sha" = "$latest_sha" ]; then
    echo "  No changes since last backup (sha $latest_sha); skipping"
    continue
  fi

  # Ensure we have a mirror clone
  if [ ! -d "$repo_dir" ]; then
    echo "  Creating mirror clone"
    # attempt mirror clone using token-authenticated clone URL to avoid rate limits
    # Build token-authenticated URL from clone_url (https)
    if [[ "$clone_url" =~ ^https:// ]]; then
      auth_clone_url="${clone_url/https:\/\//https://$GITHUB_TOKEN@}"
      git clone --mirror "$auth_clone_url" "$repo_dir"
    else
      git clone --mirror "$clone_url" "$repo_dir"
    fi
  else
    echo "  Fetching updates in mirror"
    (cd "$repo_dir" && git remote update --prune)
  fi

  # After fetching, confirm the new local HEAD (mirror) sha of default branch
  # Determine default branch name from GitHub API
  default_branch=$(curl -sS -H "$auth_header" "$API_BASE/repos/$repo_fullname" | jq -r '.default_branch' 2>/dev/null || echo "main")
  # In a bare mirror, the refs are refs/heads/<branch> in the mirror
  mirror_sha=$(git --git-dir="$repo_dir" rev-parse "refs/heads/$default_branch" 2>/dev/null || true)
  if [ -z "$mirror_sha" ]; then
    # Fallback: use the API latest_sha
    mirror_sha="$latest_sha"
  fi

  # Archive creation
  archive_base="${repo_fullname//\//-}-$DATE_CMD-${mirror_sha:0:8}"
  archive_tar="$TMP_DIR/$archive_base.tar"
  archive_comp="$BACKUP_DIR/$archive_base.tar.zst"
  archive_enc="$archive_comp.gpg"

  echo "  Creating tar of mirror"
  # create tar of the bare repo directory
  tar -cf "$archive_tar" -C "$(dirname "$repo_dir")" "$(basename "$repo_dir")"

  echo "  Compressing with zstd"
  $COMPRESS_CMD "$archive_tar" > "$archive_comp"
  rm -f "$archive_tar"

  echo "  Encrypting with GPG"
  # Symmetric encryption (-c). Use --batch to avoid interactive prompts; passphrase from env variable
  printf "%s" "$GPG_PASSPHRASE" | gpg --batch --yes --passphrase-fd 0 --cipher-algo AES256 -c --output "$archive_enc" "$archive_comp"
  rm -f "$archive_comp"

  # Update state file atomically
  echo "$mirror_sha" > "$state_file"
  echo "  Backup stored: $archive_enc"
done < <(fetch_repos)

echo "All done."
