#!/bin/bash
set -e

# Configuration - replace these with your values
HARBOR_URL="https://172.16.30.202"  # e.g., https://harbor.example.com
HARBOR_IP="172.16.30.202"
USERNAME="admin"                    # Harbor username with project access
PASSWORD="Harbor12345"                    # Harbor password
PROJECTS=("docker-hub-cache" "ecr-public-cache" "gcr-cache" "ghcr-cache" "k8s-registry-cache" "nvcr-cache" "quay-cache") # List of projects to back up

mkdir -p "harbor-backups"
cd "harbor-backups"

for PROJECT in "${PROJECTS[@]}"; do
  echo "Backing up project: $PROJECT"
  # Create a directory for each project
  mkdir -p "$PROJECT"
  cd "$PROJECT"

  # Get list of repositories in the project
  REPOS=$(curl -sk -u "$USERNAME:$PASSWORD" "$HARBOR_URL/api/v2.0/projects/$PROJECT/repositories" | jq -r '.[].name')

  if [ -z "$REPOS" ]; then
    echo "No repositories found in project $PROJECT or access denied."
    cd ..
    continue
  fi

  for REPO_FULL in $REPOS; do
    REPO_NAME="${REPO_FULL#"$PROJECT/"}"
    echo "Processing repository: $REPO_NAME"
    # Encode repo name for API (replace / with %2F)
    REPO_ENCODED=$(echo "$REPO_NAME" | sed 's|/|%252F|g')

    # Get list of tags for the repository (artifacts may have multiple, but we pull by tag)
    TAGS=$(curl -sk -u "$USERNAME:$PASSWORD" "$HARBOR_URL/api/v2.0/projects/$PROJECT/repositories/$REPO_ENCODED/artifacts?with_tag=true" | jq -r '.[].tags | if . then .[].name else empty end')

    if [ -z "$TAGS" ]; then
      echo "No tags found for $REPO_FULL"
      continue
    fi

    for TAG in $TAGS; do
      IMAGE="$HARBOR_IP/$REPO_FULL:$TAG"
      SAVE_FILE=$(echo "$REPO_FULL" | base64 -w 0)_${TAG}.tar

      echo "Pulling $IMAGE"
      # nerdctl pull --insecure-registry --all-platforms "$IMAGE"
      nerdctl pull --insecure-registry "$IMAGE"

      if [ $? -eq 0 ]; then
        echo "Saving $IMAGE to $SAVE_FILE"
        nerdctl save --insecure-registry -o "$SAVE_FILE" "$IMAGE"
      else
        echo "Failed to pull $IMAGE"
      fi
    done
  done
  cd ..
done

echo "Backup complete. Tar files are in the 'harbor-backups' directory."