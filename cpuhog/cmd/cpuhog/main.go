package main

import (
	"fmt"
	"math"
	"math/rand"
	"net/http"
)

// https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
func CPUHog(w http.ResponseWriter, r *http.Request) {
	x := rand.Float64()
	for k := 0; k < 1000000; k++ {
		x += math.Sqrt(x)
	}
	fmt.Fprintf(w, "%f\n", x)
}

func main() {
	http.HandleFunc("/", CPUHog)

	fmt.Println("Listening on :8000")
	http.ListenAndServe(":8000", nil)
}
