package main

import (
	"fmt"
	"log"
	"time"

	"github.com/OpenNebula/one/src/oca/go/src/goca"
	"github.com/OpenNebula/one/src/oca/go/src/goca/schemas/virtualnetwork"
	"github.com/OpenNebula/one/src/oca/go/src/goca/schemas/virtualnetwork/keys"
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

	vnID, _ := controller.VirtualNetworks().ByName("asd")
	fmt.Println(vnID)

	if vnID != -1 {
		err := controller.VirtualNetwork(vnID).Delete()
		if err != nil {
			log.Fatal(err)
		}
		WaitResource(func() bool {
			vnID, _ := controller.VirtualNetworks().ByName("asd")
			return vnID == -1
		})
	}

	tpl := virtualnetwork.NewTemplate()
	tpl.Add(keys.Name, "asd")
	tpl.Add(keys.Bridge, "br86")
	tpl.Add(keys.DNS, "1.1.1.1 8.8.8.8")
	tpl.Add(keys.Gateway, "10.86.86.1")
	tpl.Add(keys.NetworkAddress, "10.86.86.0")
	tpl.Add(keys.NetworkMask, "255.255.255.0")
	tpl.Add(keys.PhyDev, "eth86")
	tpl.Add(keys.VNMad, "bridge")

	ar1 := tpl.AddAddressRange()
	ar1.Add(keys.Type, "IP4")
	ar1.Add(keys.IP, "10.86.86.10")
	ar1.Add(keys.Size, "10")
	ar1.Add("ASD", "asd")

	vnID, err := controller.VirtualNetworks().Create(tpl.String(), -1)
	if err != nil {
		log.Fatal(err)
	}

	vnctrl := controller.VirtualNetwork(vnID)

	WaitResource(func() bool {
		vn, _ := vnctrl.Info(false)
		st, _ := vn.StateString()
		return st == "READY"
	})

	ar2 := tpl.AddAddressRange()
	ar2.Add(keys.Type, "IP4")
	ar2.Add(keys.IP, "10.86.86.20")
	ar2.Add(keys.Size, "10")
	ar2.Add("ASD", "asd")

	err = vnctrl.AddAR(ar2.String())
	if err != nil {
		log.Fatal(err)
	}

	vn, err := controller.VirtualNetwork(vnID).Info(false)
	if err != nil {
		log.Fatal(err)
	}

	IP := vn.ARs[0].IP
	fmt.Println(IP)

	ASD, _ := vn.ARs[0].Custom.GetStr("ASD")
	fmt.Println(ASD)
}
