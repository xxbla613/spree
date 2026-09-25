# Agent Instructions

See [CLAUDE.md](./CLAUDE.md) for the project layout and where each part is
documented. Each application carries its own instructions — read the one for
the directory you are working in before changing anything there.

## Spree-specific agent skills

For deeper Spree-specific guidance (API conventions, the data model, event system,
testing patterns, security, deployment, the React dashboard, the Next.js
storefront, etc.), install the official skill set:

```bash
npx skills add spree/agent-skills
```

Works for Claude Code, Codex, Cursor, GitHub Copilot, Cline, Aider, Zed, Windsurf,
and 60+ other agentic CLIs. See https://github.com/spree/agent-skills for the
full skill list.
