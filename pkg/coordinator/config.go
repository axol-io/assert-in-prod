package coordinator

import (
	"os"

	"github.com/ethpandaops/assertoor/pkg/coordinator/clients"
	"github.com/ethpandaops/assertoor/pkg/coordinator/test"
	web_types "github.com/ethpandaops/assertoor/pkg/coordinator/web/types"
	"gopkg.in/yaml.v2"
)

type Config struct {
	// List of execution & consensus clients to use.
	Endpoints []clients.ClientConfig `yaml:"endpoints" json:"endpoints"`

	// WebServer config
	Web *web_types.WebConfig `yaml:"web" json:"web"`

	GlobalVars map[string]interface{} `yaml:"globalVars" json:"globalVars"`

	// List of Test configurations.
	Tests []*test.Config `yaml:"tests" json:"tests"`
}

// DefaultConfig represents a sane-default configuration.
func DefaultConfig() *Config {
	return &Config{
		Endpoints: []clients.ClientConfig{
			{
				Name:         "local",
				ExecutionURL: "http://localhost:8545",
				ConsensusURL: "http://localhost:5052",
			},
		},
		GlobalVars: make(map[string]interface{}),
		Tests: []*test.Config{
			test.BasicSynced(),
		},
	}
}

func NewConfig(path string) (*Config, error) {
	if path == "" {
		return DefaultConfig(), nil
	}

	config := DefaultConfig()

	yamlFile, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	if err := yaml.Unmarshal(yamlFile, &config); err != nil {
		return nil, err
	}

	return config, nil
}
