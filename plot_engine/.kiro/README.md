# Kiro Configuration for PlotEngine

This directory contains Kiro IDE configuration and steering rules for the PlotEngine project.

## What is Kiro?

Kiro is an AI-powered IDE that uses steering rules to provide context-aware assistance during development. These rules help maintain consistency, follow best practices, and speed up common tasks.

## Directory Structure

```
.kiro/
├── README.md                           # This file
├── steering/                           # Steering rules (always included)
│   ├── flutter-best-practices.md      # Flutter/Dart coding standards
│   ├── project-context.md             # PlotEngine architecture overview
│   ├── code-review-checklist.md       # Pre-commit checklist
│   ├── ai-features-guide.md           # AI service implementation guide
│   ├── common-tasks.md                # Quick reference for frequent tasks
│   └── troubleshooting.md             # Common issues and solutions
└── settings/                           # IDE settings (optional)
    └── mcp.json                        # Model Context Protocol config
```

## Steering Rules

### Always Included Rules

These rules are automatically included in every Kiro session:

#### 1. **flutter-best-practices.md**
- Code style guidelines (const, final, naming)
- State management patterns (Riverpod)
- Platform-aware service architecture
- Performance optimization tips
- Error handling standards
- Localization requirements
- Theme usage guidelines

#### 2. **project-context.md**
- Project overview and core features
- Technology stack details
- Project structure explanation
- Key architectural patterns
- Important providers reference
- Development workflow
- Testing strategy
- Deployment instructions

#### 3. **code-review-checklist.md**
- Pre-commit checklist items
- Common pitfalls to avoid
- Code quality standards
- Platform compatibility checks
- UI/UX requirements
- Security considerations
- Git commit message format

#### 4. **ai-features-guide.md**
- AI service architecture
- Credit system integration
- Entity extraction implementation
- AI writing features (Ask, Continue, Modify)
- Consistency checking
- Timeline validation
- Foreshadowing suggestions
- State management for AI features
- Error handling patterns
- Performance optimization
- Testing AI features

#### 5. **common-tasks.md**
- Adding new features (step-by-step)
- Adding new themes
- Platform-specific code patterns
- Creating dialogs
- Adding API endpoints
- Debugging techniques
- Performance optimization
- Testing templates
- Quick command reference

#### 6. **troubleshooting.md**
- Build issues and solutions
- State management problems
- Platform-specific issues
- Performance debugging
- API/Network troubleshooting
- Theme issues
- Localization problems
- AI features debugging
- Testing issues
- Emergency fixes

## How Steering Rules Work

### Inclusion Types

Steering rules can be included in three ways:

1. **Always** (default): Included in every Kiro session
   ```yaml
   ---
   inclusion: always
   ---
   ```

2. **Conditional**: Included when specific files are opened
   ```yaml
   ---
   inclusion: fileMatch
   fileMatchPattern: 'lib/services/**/*.dart'
   ---
   ```

3. **Manual**: Included only when explicitly referenced with `#`
   ```yaml
   ---
   inclusion: manual
   ---
   ```

### File References

Steering files can reference other files using:
```markdown
#[[file:path/to/file.dart]]
```

This is useful for including API specs, schemas, or example code.

## Using Kiro Effectively

### In Chat

Reference context with `#`:
- `#File` - Include specific file
- `#Folder` - Include entire folder
- `#Problems` - Show current diagnostics
- `#Terminal` - Include terminal output
- `#Git Diff` - Show uncommitted changes
- `#Codebase` - Search entire codebase (after indexing)

### Agent Hooks

Create automated workflows triggered by events:
- On file save → Run tests
- On message send → Check code style
- On session start → Load project context
- Manual trigger → Spell check README

Access via: Command Palette → "Open Kiro Hook UI"

### Steering Best Practices

1. **Keep rules focused**: Each file covers one topic
2. **Use examples**: Show code snippets, not just descriptions
3. **Update regularly**: Keep rules in sync with codebase
4. **Be specific**: Reference actual file paths and provider names
5. **Include context**: Explain why, not just what

## Customizing for Your Workflow

### Add Project-Specific Rules

Create new steering files for your needs:

```bash
# Add a new steering rule
touch .kiro/steering/my-custom-rule.md
```

Example custom rule:
```markdown
---
inclusion: always
---

# My Custom Rule

## When Working on Feature X

Always remember to:
1. Update the changelog
2. Add tests
3. Update documentation

## Code Pattern

\`\`\`dart
// Your custom pattern here
\`\`\`
```

### Conditional Rules

Create rules that only apply to specific files:

```markdown
---
inclusion: fileMatch
fileMatchPattern: 'lib/ui/**/*.dart'
---

# UI Component Guidelines

- Always use `ref.tr()` for text
- Use theme colors, not hardcoded
- Test in all three themes
```

### Manual Rules

Create reference documentation:

```markdown
---
inclusion: manual
---

# API Documentation

Reference this with #api-docs in chat.

## Endpoints
...
```

## MCP Configuration

Model Context Protocol (MCP) allows Kiro to use external tools and services.

### Example: AWS Documentation

```json
{
  "mcpServers": {
    "aws-docs": {
      "command": "uvx",
      "args": ["awslabs.aws-documentation-mcp-server@latest"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

### Adding MCP Servers

1. Create `.kiro/settings/mcp.json`
2. Add server configuration
3. Restart Kiro or reconnect from MCP Server view
4. Test with sample calls

## Tips for PlotEngine Development

### Quick Wins

1. **Use steering rules**: They're loaded automatically
2. **Reference files**: Use `#File` to include context
3. **Check problems**: Use `#Problems` before asking for help
4. **Search codebase**: Use `#Codebase` for project-wide searches

### Common Workflows

**Adding a feature:**
1. Reference `#common-tasks.md` for template
2. Follow the 5-step process
3. Use code-review-checklist before committing

**Debugging:**
1. Check `#troubleshooting.md` for known issues
2. Use `#Problems` to see diagnostics
3. Check `#Terminal` for error messages

**AI features:**
1. Reference `#ai-features-guide.md`
2. Always check credits first
3. Handle errors gracefully

## Maintenance

### Updating Rules

When the project evolves:

1. Update relevant steering files
2. Add new patterns to common-tasks.md
3. Document new issues in troubleshooting.md
4. Keep project-context.md in sync with architecture

### Version Control

- ✅ Commit `.kiro/steering/` files
- ✅ Commit `.kiro/README.md`
- ❌ Don't commit `.kiro/settings/` (user-specific)
- ❌ Don't commit `.kiro/.cache/` (generated)

Add to `.gitignore`:
```
.kiro/settings/
.kiro/.cache/
```

## Resources

- [Kiro Documentation](https://kiro.ai/docs)
- [Steering Rules Guide](https://kiro.ai/docs/steering)
- [MCP Protocol](https://modelcontextprotocol.io)
- [PlotEngine CLAUDE.md](../CLAUDE.md)

## Contributing

When adding new steering rules:

1. Follow the existing format
2. Include practical examples
3. Keep it concise and actionable
4. Test that rules load correctly
5. Update this README if needed

---

**Last Updated**: December 2024  
**Maintained By**: PlotEngine Development Team
