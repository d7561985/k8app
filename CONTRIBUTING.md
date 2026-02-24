# Contributing to k8app

Welcome to k8app! This document outlines our development practices and guidelines.

## Architectural Principles

### DRY (Don't Repeat Yourself)
- Use named templates in `_helpers.tpl` for repeated code blocks
- Extract common patterns like envFrom, volumes, and volumeMounts
- Reuse templates across deployment, worker, cronjob, and job resources

### KISS (Keep It Simple, Stupid)
- Prefer simple, readable templates over complex logic
- Use clear variable names and consistent patterns
- Document complex template logic with comments

### Convention Over Configuration
- Provide sensible defaults for all values
- Follow Kubernetes naming conventions
- Use consistent label and annotation patterns

### Zero-Config Defaults
- Charts should work with minimal configuration
- Essential features should have reasonable defaults
- Optional features should gracefully degrade when not configured

## Release Process

### Semantic Versioning (semver)
We follow [semantic versioning](https://semver.org/):
- **MAJOR** (X.0.0): Breaking changes, incompatible API changes
- **MINOR** (x.Y.0): New features, backward-compatible additions
- **PATCH** (x.y.Z): Bug fixes, backward-compatible fixes

### CHANGELOG
- Update `CHANGELOG.md` for every release
- Follow [Keep a Changelog](https://keepachangelog.com/) format
- Categories: Added, Changed, Deprecated, Removed, Fixed, Security

### Release Steps
1. Update version in `Chart.yaml`
2. Update `CHANGELOG.md` with new version and changes
3. Create release tag: `git tag vX.Y.Z`
4. Push tag: `git push origin vX.Y.Z`

## Backward Compatibility Policy

### Breaking Changes
- Avoid breaking existing deployments
- Deprecate old features before removing them
- Provide migration guides for major version updates
- Test against multiple Kubernetes versions

### Template Changes
- Never remove existing template logic without deprecation
- Add new features as optional (with default disabled/empty)
- Preserve existing value paths and behavior
- Use feature flags for experimental features

## Adding New Features

Follow this workflow for new features:

### 1. Template Development
- Add template logic to appropriate files (deployment.yaml, worker.yaml, etc.)
- Use conditional blocks to make features optional
- Follow existing naming and structure patterns
- Add comments explaining complex logic

### 2. Values Configuration
- Add new values to `values.yaml` with sensible defaults
- Document all new options with inline comments
- Group related values logically
- Use consistent naming conventions

### 3. Documentation
- Update `charts/app/README.md` with new feature section
- Add examples to demonstrate usage
- Document all new values and their purpose
- Include common use cases and best practices

### 4. Examples
- Add examples to `values.example.yaml`
- Create specific example files if needed (e.g., `values.example.efs.yaml`)
- Show realistic, working configurations
- Test examples with `helm template`

## Code Style

### Named Templates
- Use descriptive names: `k8app.envFrom`, not `envfrom`
- Include input parameter documentation in comments
- Handle edge cases gracefully
- Use consistent parameter passing patterns

### Template Structure
```yaml
{{/*
Template description
Input: dict with "param1" (description), "param2" (description)
*/}}
{{- define "template.name" -}}
{{- if .param1 }}
# template logic here
{{- end }}
{{- end -}}
```

### Indentation and Formatting
- Use 2 spaces for indentation (YAML standard)
- Align template calls consistently
- Use `nindent` for proper indentation in includes
- Keep line length reasonable (< 120 characters)

### Comments
- Comment complex template logic
- Explain non-obvious conditionals
- Document template parameters
- Add architectural notes where helpful

### Testing
- Test templates with various value combinations
- Verify backward compatibility
- Run `helm template` with example values
- Test on multiple Kubernetes versions

## Development Workflow

### Before Making Changes
1. Read existing templates completely
2. Understand the current architecture
3. Check for similar existing functionality
4. Plan backward-compatible approach

### Making Changes
1. Create feature branch: `feature/description`
2. Make incremental commits
3. Test each change with `helm template`
4. Update documentation as you go
5. Add examples for new features

### Quality Checklist
- [ ] Templates render without errors
- [ ] Backward compatibility maintained
- [ ] Documentation updated
- [ ] Examples added/updated
- [ ] Named templates used for repeated code
- [ ] Values have sensible defaults
- [ ] Feature is optional/configurable

## Getting Help

- Check existing issues and discussions
- Look at similar implementations in the codebase
- Review Kubernetes documentation for best practices
- Ask questions in project discussions

Thank you for contributing to k8app! 🚀