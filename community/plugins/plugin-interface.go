// Plugin Interface for Kubernetes Attack-Defense Lab
// This interface defines the contract for attack/defense plugins

package plugins

import (
	"context"
	"time"
)

// PluginType defines the type of plugin
type PluginType string

const (
	AttackPlugin      PluginType = "attack"
	DefensePlugin     PluginType = "defense"
	MonitoringPlugin  PluginType = "monitoring"
	UtilityPlugin     PluginType = "utility"
)

// PluginMetadata contains plugin information
type PluginMetadata struct {
	Name        string     `json:"name"`
	Version     string     `json:"version"`
	Type        PluginType `json:"type"`
	Description string     `json:"description"`
	Author      string     `json:"author"`
	Tags        []string   `json:"tags"`
	Requires    []string   `json:"requires,omitempty"`
}

// PluginInterface defines the methods all plugins must implement
type PluginInterface interface {
	// GetMetadata returns plugin metadata
	GetMetadata() PluginMetadata

	// Init initializes the plugin with configuration
	Init(config map[string]interface{}) error

	// Execute runs the plugin logic
	Execute(ctx context.Context, params map[string]interface{}) (interface{}, error)

	// Cleanup performs cleanup operations
	Cleanup() error

	// Validate checks if the plugin can run in the current environment
	Validate() error
}

// AttackPlugin extends PluginInterface for attack scenarios
type AttackPlugin interface {
	PluginInterface

	// GetDifficulty returns the difficulty level
	GetDifficulty() string

	// GetCategory returns the attack category
	GetCategory() string

	// GetPrerequisites returns required setup
	GetPrerequisites() []string

	// SimulateAttack runs the attack simulation
	SimulateAttack(ctx context.Context) error

	// CleanupAttack cleans up after attack
	CleanupAttack(ctx context.Context) error
}

// DefensePlugin extends PluginInterface for defense mechanisms
type DefensePlugin interface {
	PluginInterface

	// GetDefenseType returns the type of defense
	GetDefenseType() string

	// DeployDefense deploys the defense mechanism
	DeployDefense(ctx context.Context) error

	// ValidateDefense checks if defense is working
	ValidateDefense(ctx context.Context) (bool, error)

	// RemoveDefense removes the defense mechanism
	RemoveDefense(ctx context.Context) error
}

// PluginManager manages plugin lifecycle
type PluginManager struct {
	plugins map[string]PluginInterface
}

// NewPluginManager creates a new plugin manager
func NewPluginManager() *PluginManager {
	return &PluginManager{
		plugins: make(map[string]PluginInterface),
	}
}

// RegisterPlugin registers a plugin
func (pm *PluginManager) RegisterPlugin(name string, plugin PluginInterface) error {
	if _, exists := pm.plugins[name]; exists {
		return fmt.Errorf("plugin %s already registered", name)
	}
	pm.plugins[name] = plugin
	return nil
}

// GetPlugin returns a registered plugin
func (pm *PluginManager) GetPlugin(name string) (PluginInterface, error) {
	plugin, exists := pm.plugins[name]
	if !exists {
		return nil, fmt.Errorf("plugin %s not found", name)
	}
	return plugin, nil
}

// ListPlugins returns all registered plugins
func (pm *PluginManager) ListPlugins() map[string]PluginMetadata {
	result := make(map[string]PluginMetadata)
	for name, plugin := range pm.plugins {
		result[name] = plugin.GetMetadata()
	}
	return result
}
