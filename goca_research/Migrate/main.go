package main

import (
	"fmt"
	"log"
	"time"

	"github.com/OpenNebula/one/src/oca/go/src/goca"
)

func WaitResource(f func() bool) bool {
	for i := 0; i < 20; i++ {
		if f() {
			return true
		}
		time.Sleep(2 * time.Second)
	}
	return false
}

func get_hid(controller *goca.Controller, vmid int) int {
	vm, err := controller.VM(vmid).Info(false)
	if err != nil {
		log.Fatal(err)
	}
	return vm.HistoryRecords[len(vm.HistoryRecords)-1].HID
}

func main() {
	con := map[string]string{
		"user":     "oneadmin",
		"password": "asd",
		"endpoint": "http://10.2.11.40:2633/RPC2",
	}

	client := goca.NewDefaultClient(
		goca.NewConfig(con["user"], con["password"], con["endpoint"]),
	)

	controller := goca.NewController(client)

	vmid, err := controller.VMs().ByName("asd")
	if err != nil {
		tpid, err := controller.Templates().ByName("alpine314")
		if err != nil {
			log.Fatal(err)
		}

		vmid, err = controller.Template(tpid).Instantiate("asd", false, "", false)
		if err != nil {
			log.Fatal(err)
		}
	}
	fmt.Println(vmid)

	WaitResource(func() bool {
		vm, _ := controller.VM(vmid).Info(false)
		return vm.LCMStateRaw == 3
	})

	fmt.Printf("SRC: %d\n", get_hid(controller, vmid))

	hosts, err := controller.Hosts().Info()
	if err != nil {
		log.Fatal(err)
	}

	hidmap := map[int]struct{}{}
	for _, host := range hosts.Hosts {
		hidmap[host.ID] = struct{}{}
	}
	delete(hidmap, get_hid(controller, vmid))

	hids := []int{}
	for key := range hidmap {
	    hids = append(hids, key)
	}

	err = controller.VM(vmid).Migrate(hids[0], true, true, 0, 0)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("DST: %d\n", get_hid(controller, vmid))
}
