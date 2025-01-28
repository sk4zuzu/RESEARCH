package main

import (
	"context"
	"fmt"
	"log"
	"regexp"
	"time"

	goca "github.com/OpenNebula/one/src/oca/go/src/goca"
)

func main() {
	log.Println("asd")

	ctrl := goca.NewController(goca.NewDefaultClient(goca.OneConfig{
		Endpoint: "http://10.2.11.40:2633/RPC2",
		Token:    "oneadmin:asd",
	}))

	r, err := regexp.Compile("quick-start-[^-]+-cp")
	if err != nil {
		log.Fatal(err)
	}

	found := false
	for retry := 0; retry < 24; retry++ {
		pool, err := ctrl.VirtualRouters().InfoContext(context.Background())
		if err != nil {
			log.Fatal(err)
		}
		found = false
		for _, vr := range pool.VirtualRouters {
			if r.MatchString(vr.Name) {
				fmt.Printf("%v\n", vr.Name)
				found = true
				time.Sleep(5 * time.Second)
				break
			}
		}
		if !found {
			break
		}
	}
	fmt.Println(found)
}
