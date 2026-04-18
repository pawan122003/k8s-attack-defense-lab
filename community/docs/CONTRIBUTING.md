# Contributing to Kubernetes Attack-Defense Lab

Thank you for your interest in contributing to the Kubernetes Attack-Defense Lab! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Types of Contributions](#types-of-contributions)
- [Development Workflow](#development-workflow)
- [Plugin Development](#plugin-development)
- [Testing](#testing)
- [Documentation](#documentation)
- [Review Process](#review-process)

## Code of Conduct

This project follows a code of conduct to ensure a welcoming environment for all contributors. By participating, you agree to:

- Be respectful and inclusive
- Focus on constructive feedback
- Accept responsibility for mistakes
- Show empathy towards other contributors
- Help create a positive community

## Getting Started

### Prerequisites

- Go 1.19+ for plugin development
- Docker and Kubernetes (Kind, minikube, or similar)
- kubectl configured
- Git

### Development Environment Setup

1. Fork and clone the repository:
   ```bash
   git clone https://github.com/your-username/k8s-attack-defense-lab.git
   cd k8s-attack-defense-lab
   ```

2. Set up development cluster:
   ```bash
   ./scripts/setup-dev-environment.sh
   ```

3. Install dependencies:
   ```bash
   go mod download
   npm install  # for web components
   ```

## Types of Contributions

### 🐛 Bug Reports

- Use the bug report template
- Include detailed steps to reproduce
- Provide environment information
- Include relevant logs and error messages

### ✨ Feature Requests

- Use the feature request template
- Clearly describe the proposed feature
- Explain the use case and benefits
- Consider backward compatibility

### 🔌 Plugin Contributions

- New attack or defense scenarios
- Monitoring enhancements
- Utility tools

### 📚 Documentation

- User guides and tutorials
- API documentation
- Code comments and examples

### 🧪 Testing

- Unit tests for new code
- Integration tests for scenarios
- Performance benchmarks

## Development Workflow

### 1. Choose an Issue

- Check the [issue tracker](https://github.com/your-org/k8s-attack-defense-lab/issues)
- Look for issues labeled `good first issue` or `help wanted`
- Comment on the issue to indicate you're working on it

### 2. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-number-description
```

### 3. Make Changes

- Follow the coding standards
- Write tests for new functionality
- Update documentation as needed
- Ensure all tests pass

### 4. Commit Changes

```bash
git add .
git commit -m "feat: add new attack scenario

- Implements XYZ attack technique
- Includes comprehensive testing
- Updates documentation

Closes #123"
```

### 5. Push and Create PR

```bash
git push origin feature/your-feature-name
```

Create a pull request with:
- Clear title and description
- Reference to related issues
- Screenshots/videos for UI changes
- Test results

## Plugin Development

### Plugin Structure

```
plugins/
├── your-plugin/
│   ├── plugin.go          # Main plugin implementation
│   ├── plugin_test.go     # Unit tests
│   ├── README.md          # Plugin documentation
│   ├── metadata.yaml      # Plugin metadata
│   └── examples/          # Usage examples
```

### Plugin Interface

All plugins must implement the `PluginInterface`:

```go
type PluginInterface interface {
    GetMetadata() PluginMetadata
    Init(config map[string]interface{}) error
    Execute(ctx context.Context, params map[string]interface{}) (interface{}, error)
    Cleanup() error
    Validate() error
}
```

### Example Plugin

```go
package main

import (
    "context"
    "fmt"
    "time"

    "github.com/your-org/k8s-lab/plugins"
)

type ExampleAttackPlugin struct{}

func (p *ExampleAttackPlugin) GetMetadata() plugins.PluginMetadata {
    return plugins.PluginMetadata{
        Name:        "example-attack",
        Version:     "1.0.0",
        Type:        plugins.AttackPlugin,
        Description: "Example attack plugin",
        Author:      "Your Name",
        Tags:        []string{"example", "demo"},
    }
}

func (p *ExampleAttackPlugin) Init(config map[string]interface{}) error {
    // Initialize plugin
    return nil
}

func (p *ExampleAttackPlugin) Execute(ctx context.Context, params map[string]interface{}) (interface{}, error) {
    // Execute attack logic
    fmt.Println("Executing example attack...")
    time.Sleep(2 * time.Second)
    return "Attack completed successfully", nil
}

func (p *ExampleAttackPlugin) Cleanup() error {
    // Cleanup resources
    return nil
}

func (p *ExampleAttackPlugin) Validate() error {
    // Validate environment
    return nil
}

// Export plugin
var Plugin ExampleAttackPlugin
```

### Building Plugins

```bash
cd plugins/your-plugin
go build -buildmode=plugin -o plugin.so plugin.go
```

## Testing

### Unit Tests

```bash
go test ./plugins/...
```

### Integration Tests

```bash
./scripts/run-integration-tests.sh
```

### Performance Tests

```bash
./performance/benchmarking/benchmark-runner.sh
```

## Documentation

### Code Documentation

- Use Go doc comments for public functions
- Include examples in doc comments
- Keep comments up to date

### User Documentation

- Update README files for new features
- Add examples and tutorials
- Include troubleshooting guides

## Review Process

### Automated Checks

All PRs must pass:
- Code formatting (gofmt)
- Linting (golint)
- Unit tests
- Integration tests
- Security scanning

### Manual Review

- At least one maintainer review required
- Review focuses on:
  - Code quality and style
  - Security implications
  - Documentation completeness
  - Test coverage
  - Backward compatibility

### Approval and Merge

- Maintainers will approve PRs that meet requirements
- Squash and merge is preferred
- Release notes updated for significant changes

## Recognition

Contributors are recognized through:
- GitHub contributor statistics
- Mention in release notes
- Contributor spotlight in documentation
- Community recognition

## Getting Help

- 📧 [Discussions](https://github.com/your-org/k8s-attack-defense-lab/discussions)
- 💬 [Slack Community](https://slack.k8s-lab.community)
- 📖 [Documentation](https://docs.k8s-lab.community)
- 🐛 [Issue Tracker](https://github.com/your-org/k8s-attack-defense-lab/issues)

Thank you for contributing to the Kubernetes Attack-Defense Lab! 🚀
