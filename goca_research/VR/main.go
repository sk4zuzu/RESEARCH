package main

import (
	"fmt"
	"log"

	"encoding/xml"

	goca "github.com/OpenNebula/one/src/oca/go/src/goca"
	gdyn "github.com/OpenNebula/one/src/oca/go/src/goca/dynamic"
)

const vrTemplate = `
<TEMPLATE>
  <NAME>asd</NAME>
  <CONTEXT>
    <NETWORK><![CDATA[YES]]></NETWORK>
    <ONEAPP_VNF_HAPROXY_ENABLED><![CDATA[YES]]></ONEAPP_VNF_HAPROXY_ENABLED>
    <ONEAPP_VNF_HAPROXY_INTERFACES><![CDATA[$ONEAPP_VNF_HAPROXY_INTERFACES]]></ONEAPP_VNF_HAPROXY_INTERFACES>
    <ONEAPP_VNF_HAPROXY_LB0_IP><![CDATA[$ONEAPP_VNF_HAPROXY_LB0_IP]]></ONEAPP_VNF_HAPROXY_LB0_IP>
    <ONEAPP_VNF_HAPROXY_LB0_PORT><![CDATA[$ONEAPP_VNF_HAPROXY_LB0_PORT]]></ONEAPP_VNF_HAPROXY_LB0_PORT>
    <ONEAPP_VNF_HAPROXY_ONEGATE_ENABLED><![CDATA[YES]]></ONEAPP_VNF_HAPROXY_ONEGATE_ENABLED>
    <ONEAPP_VROUTER_ETH0_VIP0><![CDATA[$ONEAPP_VROUTER_ETH0_VIP0]]></ONEAPP_VROUTER_ETH0_VIP0>
    <REPORT_READY><![CDATA[YES]]></REPORT_READY>
    <SERVICE_ID><![CDATA[$SERVICE_ID]]></SERVICE_ID>
    <SSH_PUBLIC_KEY><![CDATA[$USER[SSH_PUBLIC_KEY]]]></SSH_PUBLIC_KEY>
    <TOKEN><![CDATA[YES]]></TOKEN>
  </CONTEXT>
  <CPU><![CDATA[1]]></CPU>
  <DISK>
    <IMAGE_ID><![CDATA[3]]></IMAGE_ID>
  </DISK>
  <GRAPHICS>
    <LISTEN><![CDATA[0.0.0.0]]></LISTEN>
    <TYPE><![CDATA[vnc]]></TYPE>
  </GRAPHICS>
  <MEMORY><![CDATA[512]]></MEMORY>
  <NIC_DEFAULT>
    <MODEL><![CDATA[virtio]]></MODEL>
  </NIC_DEFAULT>
  <OS>
    <ARCH><![CDATA[x86_64]]></ARCH>
  </OS>
</TEMPLATE>
`

func createVRTemplate(client *goca.Client) error {
	document := &gdyn.Template{}

	err := xml.Unmarshal([]byte(vmTemplate), &document)
	if err != nil {
		return err
	}

	controller := goca.NewController(client)

	id, err := controller.Templates().Create(document.String())
	if err != nil {
		return err
	}

	result, err := controller.Template(id).Info(false, false)
	if err != nil {
		return err
	}

	fmt.Printf("%v\n", result)

	return nil
}

func main() {
	one := goca.NewDefaultClient(
		goca.NewConfig("oneadmin", "asd", "http://10.2.11.40:2633/RPC2"),
	)

	if err := createVMTemplate(one); err != nil {
		log.Println(err)
	}
}
