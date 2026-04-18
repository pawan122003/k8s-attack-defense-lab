// Plugin Loader for dynamic plugin loading
package plugins

import (
	"fmt"
	"io/ioutil"
	"path/filepath"
	"plugin"
)

// PluginLoader handles loading plugins from files
type PluginLoader struct {
	pluginDir string
	manager   *PluginManager
}

// NewPluginLoader creates a new plugin loader
func NewPluginLoader(pluginDir string, manager *PluginManager) *PluginLoader {
	return &PluginLoader{
		pluginDir: pluginDir,
		manager:   manager,
	}
}

// LoadPlugins loads all plugins from the plugin directory
func (pl *PluginLoader) LoadPlugins() error {
	files, err := ioutil.ReadDir(pl.pluginDir)
	if err != nil {
		return fmt.Errorf("failed to read plugin directory: %v", err)
	}

	for _, file := range files {
		if filepath.Ext(file.Name()) == ".so" {
			if err := pl.loadPlugin(filepath.Join(pl.pluginDir, file.Name())); err != nil {
				fmt.Printf("Failed to load plugin %s: %v\n", file.Name(), err)
				continue
			}
		}
	}

	return nil
}

// loadPlugin loads a single plugin file
func (pl *PluginLoader) loadPlugin(path string) error {
	p, err := plugin.Open(path)
	if err != nil {
		return fmt.Errorf("failed to open plugin: %v", err)
	}

	sym, err := p.Lookup("Plugin")
	if err != nil {
		return fmt.Errorf("plugin does not export Plugin symbol: %v", err)
	}

	pluginInstance, ok := sym.(PluginInterface)
	if !ok {
		return fmt.Errorf("plugin does not implement PluginInterface")
	}

	metadata := pluginInstance.GetMetadata()
	return pl.manager.RegisterPlugin(metadata.Name, pluginInstance)
}
