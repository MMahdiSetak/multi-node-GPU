#!/bin/bash
set -e

# Configuration - replace these with your values
NEW_HARBOR_URL="https://172.16.30.202"  # New Harbor URL
OLD_HARBOR_IP="172.16.30.202"
NEW_HARBOR_IP="172.16.30.202"                    # New Harbor IP if needed for image names (e.g., for insecure access)
NEW_USERNAME="admin"                             # New Harbor username with admin access (to create projects)
NEW_PASSWORD="Harbor12345"                      # New Harbor password
BACKUP_DIR="harbor-backups"                      # Directory containing backups (with project subdirs)
PROJECTS=("docker-hub-cache" "ecr-public-cache" "gcr-cache" "ghcr-cache" "k8s-registry-cache" "nvcr-cache" "quay-cache")  # List of projects to restore

# Login to new Harbor
nerdctl login --insecure-registry -u "$NEW_USERNAME" -p "$NEW_PASSWORD" "$NEW_HARBOR_URL"

cd "$BACKUP_DIR"

for PROJECT in "${PROJECTS[@]}"; do
  echo "Restoring project: $PROJECT"

  # Check if project exists, create if not
  PROJECT_CHECK=$(curl -sk -u "$NEW_USERNAME:$NEW_PASSWORD" -X GET "$NEW_HARBOR_URL/api/v2.0/projects?name=$PROJECT-backup" | jq 'length')
  if [ "$PROJECT_CHECK" -eq 0 ]; then
    echo "Creating project $PROJECT-backup"
    curl -sk -u "$NEW_USERNAME:$NEW_PASSWORD" -X POST -H "Content-Type: application/json" "$NEW_HARBOR_URL/api/v2.0/projects" -d "{\"project_name\": \"$PROJECT-backup\", \"public\": true}"
  else
    echo "Project $PROJECT-backup already exists"
  fi

  if [ ! -d "$PROJECT" ]; then
    echo "No backup directory for $PROJECT, skipping"
    continue
  fi

  cd "$PROJECT"

  for TAR_FILE in *.tar; do
    if [ ! -f "$TAR_FILE" ]; then
      echo "No tar files in $PROJECT, skipping"
      continue
    fi

    # Parse filename to get REPO_FULL and TAG
    FILENAME="${TAR_FILE%.tar}"  # Remove .tar
    TAG="${FILENAME##*_}"        # Last part after _
    BASE64_REPO="${FILENAME%_*}" # Everything before last _
    REPO_FULL=$(echo "$BASE64_REPO" | base64 -d)

    echo "Loading $TAR_FILE"
    nerdctl load -i "$TAR_FILE"

    # Original image name (from backup, using IP or URL; adjust if needed)
    ORIGINAL_IMAGE="$OLD_HARBOR_IP/$REPO_FULL:$TAG"  # If backup used IP; else use HARBOR_URL

    # Adjust REPO_FULL for new project name
    REPO_FULL=$(echo "$REPO_FULL" | sed "s/^$PROJECT\//$PROJECT-backup\//")
    # New image name
    NEW_IMAGE="$NEW_HARBOR_IP/$REPO_FULL:$TAG"  # Or $NEW_HARBOR_URL if using domain

    echo "Tagging $ORIGINAL_IMAGE to $NEW_IMAGE"
    nerdctl tag "$ORIGINAL_IMAGE" "$NEW_IMAGE"

    echo "Pushing $NEW_IMAGE"
    # nerdctl push --insecure-registry --all-platforms "$NEW_IMAGE"
    nerdctl push --insecure-registry --platform linux/amd64 "$NEW_IMAGE"

    # Optional: Clean up local images
    # nerdctl rmi "$ORIGINAL_IMAGE" "$NEW_IMAGE"
  done

  cd ..
done

echo "Restore complete."