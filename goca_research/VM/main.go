package main

import (
	"context"
	"fmt"
	"log"

	"github.com/OpenNebula/one/src/oca/go/src/goca"
	goca_vm "github.com/OpenNebula/one/src/oca/go/src/goca/schemas/vm"
)

func ByUUID(ctx context.Context, rpc2 *goca.Client, needle string) (*goca_vm.VM, error) {
	pool, err := goca.NewController(rpc2).VMs().InfoExtendedContext(ctx, -2)
	if err != nil {
		return nil, err
	}

	for _, vm := range pool.VMs {
		uuid, err := vm.Template.GetStrFromVec("OS", "UUID")
		if err != nil {
			return nil, err
		}
		if needle == uuid {
			return &vm, nil
		}
	}

	return nil, fmt.Errorf("Not found")
}

func main() {
	rpc2 := goca.NewDefaultClient(goca.OneConfig{
		Endpoint: "http://10.2.11.40:2633/RPC2",
		Token:    "oneadmin:asd",
	})
/*
	vm, err := ByUUID(context.Background(), rpc2, "728a3971-4beb-441a-b40a-52704eda622a")
	if err != nil {
		log.Fatalf("%s", err)
	}

	state, _, err := vm.State()
	if err != nil {
		log.Fatalf("%s", err)
	}

	switch state {
	case goca_vm.Poweroff, goca_vm.Undeployed:
		log.Printf("FYK!")
	default:
		log.Printf("%v", vm)
	}
*/
	ctrl := goca.NewController(rpc2)

	asd, err := ctrl.VM(413).Info(true)
	if err != nil {
		log.Fatalf("%s", err)
	}

	log.Printf("%v", asd)
}
