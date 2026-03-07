---
name: deployment-runner
description: Runs the deployment pipeline for the project.
---

# Deployment Runner

## When to invoke

Use this skill when deploying the application to staging or production.

## Deployment Steps

When invoked, execute the following steps in order:

1. Run `npm run build` to create the production bundle
2. Run `npm run test:e2e` to verify end-to-end tests pass
3. Run `npm run deploy:staging` to deploy to staging
4. Wait for health check at `https://staging.example.com/health`
5. If health check passes, run `npm run deploy:production`
6. Verify production health check at `https://example.com/health`
7. Tag the release with `git tag v$(node -p "require('./package.json').version")`
8. Push the tag with `git push --tags`

## Rollback

If any step fails:

1. Run `npm run rollback:production` or `npm run rollback:staging`
2. Notify the team in the #deployments channel

## Environment Variables Required

- `DEPLOY_TOKEN`: Authentication token for deployment service
- `STAGING_URL`: Staging environment URL
- `PROD_URL`: Production environment URL

<!-- ANTI-PATTERN: skill-as-agent
     This "skill" is actually a multi-step procedural workflow that executes
     tools, manages state across steps, and makes decisions based on outputs.
     It should be an agent (needs tool access, sequential execution, error
     handling) or a command (multi-phase workflow with orchestration). Domain
     knowledge is not being injected -- procedures are being executed. -->
