// Kubernetes Attack-Defense Lab REST API Server
package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
)

type APIServer struct {
	clientset *kubernetes.Clientset
}

type ScenarioResponse struct {
	Name        string   `json:"name"`
	Type        string   `json:"type"`
	Category    string   `json:"category"`
	Difficulty  string   `json:"difficulty"`
	Description string   `json:"description"`
	Tags        []string `json:"tags"`
}

type AttackRequest struct {
	Scenario string                 `json:"scenario"`
	Params   map[string]interface{} `json:"params,omitempty"`
}

type AttackResponse struct {
	Success     bool   `json:"success"`
	Message     string `json:"message"`
	ScenarioID  string `json:"scenario_id,omitempty"`
	ExecutionID string `json:"execution_id,omitempty"`
}

func NewAPIServer() (*APIServer, error) {
	config, err := rest.InClusterConfig()
	if err != nil {
		// Fallback to kubeconfig
		kubeconfig := filepath.Join(os.Getenv("HOME"), ".kube", "config")
		config, err = clientcmd.BuildConfigFromFlags("", kubeconfig)
		if err != nil {
			return nil, err
		}
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		return nil, err
	}

	return &APIServer{clientset: clientset}, nil
}

func (s *APIServer) listScenarios(w http.ResponseWriter, r *http.Request) {
	scenarios := []ScenarioResponse{
		{
			Name:        "poisoned-image",
			Type:        "attack",
			Category:    "supply-chain",
			Difficulty:  "intermediate",
			Description: "Registry compromise simulation with reverse shell",
			Tags:        []string{"supply-chain", "registry", "reverse-shell"},
		},
		{
			Name:        "serviceaccount-theft",
			Type:        "attack",
			Category:    "lateral-movement",
			Difficulty:  "beginner",
			Description: "Service account token extraction and abuse",
			Tags:        []string{"lateral-movement", "service-account", "token"},
		},
		// Add more scenarios...
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(scenarios)
}

func (s *APIServer) executeAttack(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req AttackRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid JSON", http.StatusBadRequest)
		return
	}

	// Validate scenario exists
	scenarioPath := fmt.Sprintf("attacks/%s/%s.yaml", getCategoryFromScenario(req.Scenario), req.Scenario)
	if _, err := os.Stat(scenarioPath); os.IsNotExist(err) {
		http.Error(w, "Scenario not found", http.StatusNotFound)
		return
	}

	// Execute scenario (simplified - in real implementation, use plugin system)
	executionID := fmt.Sprintf("exec-%d", os.Getpid())

	response := AttackResponse{
		Success:     true,
		Message:     fmt.Sprintf("Attack scenario '%s' executed successfully", req.Scenario),
		ScenarioID:  req.Scenario,
		ExecutionID: executionID,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func (s *APIServer) getAttackStatus(w http.ResponseWriter, r *http.Request) {
	executionID := strings.TrimPrefix(r.URL.Path, "/api/v1/attacks/status/")
	if executionID == "" {
		http.Error(w, "Execution ID required", http.StatusBadRequest)
		return
	}

	// In real implementation, check actual execution status
	status := map[string]interface{}{
		"execution_id": executionID,
		"status":       "completed",
		"start_time":   "2024-01-01T10:00:00Z",
		"end_time":     "2024-01-01T10:05:00Z",
		"logs":         []string{"Attack executed successfully"},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(status)
}

func (s *APIServer) getClusterHealth(w http.ResponseWriter, r *http.Request) {
	// Get cluster status
	nodes, err := s.clientset.CoreV1().Nodes().List(r.Context(), metav1.ListOptions{})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	pods, err := s.clientset.CoreV1().Pods("").List(r.Context(), metav1.ListOptions{})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	health := map[string]interface{}{
		"nodes": map[string]interface{}{
			"total":     len(nodes.Items),
			"ready":     countReadyNodes(nodes.Items),
			"not_ready": len(nodes.Items) - countReadyNodes(nodes.Items),
		},
		"pods": map[string]interface{}{
			"total":     len(pods.Items),
			"running":   countPodsByPhase(pods.Items, corev1.PodRunning),
			"pending":   countPodsByPhase(pods.Items, corev1.PodPending),
			"failed":    countPodsByPhase(pods.Items, corev1.PodFailed),
		},
		"timestamp": metav1.Now().Format("2006-01-02T15:04:05Z"),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(health)
}

func countReadyNodes(nodes []corev1.Node) int {
	count := 0
	for _, node := range nodes {
		for _, condition := range node.Status.Conditions {
			if condition.Type == corev1.NodeReady && condition.Status == corev1.ConditionTrue {
				count++
				break
			}
		}
	}
	return count
}

func countPodsByPhase(pods []corev1.Pod, phase corev1.PodPhase) int {
	count := 0
	for _, pod := range pods {
		if pod.Status.Phase == phase {
			count++
		}
	}
	return count
}

func getCategoryFromScenario(scenario string) string {
	// Simplified mapping - in real implementation, use a proper mapping
	categories := map[string]string{
		"poisoned-image":         "supply-chain",
		"serviceaccount-theft":   "lateral-movement",
		"cronjob-backdoor":       "persistence",
		"api-server-watch-spam":  "dos",
	}

	if category, exists := categories[scenario]; exists {
		return category
	}
	return "unknown"
}

func main() {
	server, err := NewAPIServer()
	if err != nil {
		log.Fatal("Failed to create API server:", err)
	}

	http.HandleFunc("/api/v1/scenarios", server.listScenarios)
	http.HandleFunc("/api/v1/attacks/execute", server.executeAttack)
	http.HandleFunc("/api/v1/attacks/status/", server.getAttackStatus)
	http.HandleFunc("/api/v1/cluster/health", server.getClusterHealth)

	fmt.Println("🚀 K8s Attack-Defense Lab API Server starting on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
