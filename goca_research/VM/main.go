package main

import (
	"log"

	"github.com/OpenNebula/one/src/oca/go/src/goca"
)

func main() {
	rpc2 := goca.NewDefaultClient(goca.OneConfig{
		Endpoint: "http://10.2.11.40:2633/RPC2",
		Token:    "oneadmin:asd",
	})

	controller := goca.NewController(rpc2)

	if err := controller.VM(242).TerminateHard(); err != nil {
		log.Fatalf("%w", err)
	}
}
