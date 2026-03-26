Open a draft PR if one doesn't exist, or push to the existing PR's branch if one is already open.

Instructions:
1. Check if a PR already exists for the current branch using `gh pr list --head <branch-name>`
2. If a PR exists:
   - Push the current branch to remote with `git push`
   - Analyze the full commit history for the branch (from divergence point) to understand current changes
   - Draft an updated PR description with:
     - ## Summary (bullet points reflecting current state of all changes)
     - ## Test plan (how to verify the changes)
     - Include co-author footer: "🤖 Generated with [Claude Code](https://claude.com/claude-code)"
   - Update the PR description using `gh pr edit <pr-number> --body "..."`
   - Show the PR URL
3. If no PR exists:
   - Analyze the full commit history for the branch (from divergence point)
   - Draft a comprehensive PR title and description:
     - Title should be clear and concise (50-70 chars)
     - Description should have:
       - ## Summary (bullet points of main changes)
       - ## Test plan (how to verify the changes)
       - Include co-author footer: "🤖 Generated with [Claude Code](https://claude.com/claude-code)"
   - Push the branch to remote with `git push -u origin <branch-name>`
   - Create draft PR using `gh pr create --draft --title "..." --body "..."`
   - Show the PR URL

Always co-author the PR description and write detailed summaries.
