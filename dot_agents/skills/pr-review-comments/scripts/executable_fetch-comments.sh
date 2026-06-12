#!/usr/bin/env bash

# Get the current PR info (number, owner, repo)
PR_INFO=$(gh pr view --json number,headRepositoryOwner,headRepository -q '{number: .number, owner: .headRepositoryOwner.login, repo: .headRepository.name}' 2>/dev/null)

if [ -z "$PR_INFO" ]; then
  echo "Error: Not on a branch with an associated PR"
  exit 1
fi

PR_NUMBER=$(echo "$PR_INFO" | jq -r '.number')
OWNER=$(echo "$PR_INFO" | jq -r '.owner')
REPO=$(echo "$PR_INFO" | jq -r '.repo')

# Use GraphQL API to fetch review threads with resolution status
# Filter to only unresolved and non-outdated threads
# Fetch all comments in each thread (up to 50 per thread)
gh api graphql -f query="
query {
  repository(owner: \"$OWNER\", name: \"$REPO\") {
    pullRequest(number: $PR_NUMBER) {
      reviewThreads(first: 100) {
        nodes {
          isResolved
          isOutdated
          comments(first: 50) {
            nodes {
              path
              line
              body
              author {
                login
              }
              url
              createdAt
            }
          }
        }
      }
    }
  }
}" | jq -r '
  .data.repository.pullRequest.reviewThreads.nodes |
  map(select(.isResolved == false and .isOutdated == false)) |
  if length == 0 then
    "No unresolved review comments found."
  else
    "Found \(length) unresolved review thread(s):\n\n" +
    (map(
      "## \(.comments.nodes[0].path // "General comment"):\(.comments.nodes[0].line // "N/A")\n\n" +
      (.comments.nodes | map(
        "**\(.author.login)** (\(.createdAt | split("T")[0])):\n\(.body)\n\nURL: \(.url)"
      ) | join("\n\n---\n\n")) +
      "\n"
    ) | join("\n"))
  end
'
