package main

import (
	"encoding/xml"
	"fmt"
	"log"

	goca "github.com/OpenNebula/one/src/oca/go/src/goca"
	goca_dyn "github.com/OpenNebula/one/src/oca/go/src/goca/dynamic"
	//goca_shared "github.com/OpenNebula/one/src/oca/go/src/goca/schemas/shared"
	//goca_vm "github.com/OpenNebula/one/src/oca/go/src/goca/schemas/vm"
	goca_vr "github.com/OpenNebula/one/src/oca/go/src/goca/schemas/virtualrouter"
)

//const vrTemplate = `
//<TEMPLATE>
//  <NAME>asd</NAME>
//  <CONTEXT>
//    <NETWORK><![CDATA[YES]]></NETWORK>
//    <ONEAPP_VNF_HAPROXY_ENABLED><![CDATA[YES]]></ONEAPP_VNF_HAPROXY_ENABLED>
//    <ONEAPP_VNF_HAPROXY_INTERFACES><![CDATA[$ONEAPP_VNF_HAPROXY_INTERFACES]]></ONEAPP_VNF_HAPROXY_INTERFACES>
//    <ONEAPP_VNF_HAPROXY_LB0_IP><![CDATA[$ONEAPP_VNF_HAPROXY_LB0_IP]]></ONEAPP_VNF_HAPROXY_LB0_IP>
//    <ONEAPP_VNF_HAPROXY_LB0_PORT><![CDATA[$ONEAPP_VNF_HAPROXY_LB0_PORT]]></ONEAPP_VNF_HAPROXY_LB0_PORT>
//    <ONEAPP_VNF_HAPROXY_ONEGATE_ENABLED><![CDATA[YES]]></ONEAPP_VNF_HAPROXY_ONEGATE_ENABLED>
//    <ONEAPP_VROUTER_ETH0_VIP0><![CDATA[$ONEAPP_VROUTER_ETH0_VIP0]]></ONEAPP_VROUTER_ETH0_VIP0>
//    <REPORT_READY><![CDATA[YES]]></REPORT_READY>
//    <SERVICE_ID><![CDATA[$SERVICE_ID]]></SERVICE_ID>
//    <SSH_PUBLIC_KEY><![CDATA[$USER[SSH_PUBLIC_KEY]]]></SSH_PUBLIC_KEY>
//    <TOKEN><![CDATA[YES]]></TOKEN>
//  </CONTEXT>
//  <CPU><![CDATA[1]]></CPU>
//  <DISK>
//    <IMAGE_ID><![CDATA[3]]></IMAGE_ID>
//  </DISK>
//  <GRAPHICS>
//    <LISTEN><![CDATA[0.0.0.0]]></LISTEN>
//    <TYPE><![CDATA[vnc]]></TYPE>
//  </GRAPHICS>
//  <MEMORY><![CDATA[512]]></MEMORY>
//  <NIC_DEFAULT>
//    <MODEL><![CDATA[virtio]]></MODEL>
//  </NIC_DEFAULT>
//  <OS>
//    <ARCH><![CDATA[x86_64]]></ARCH>
//  </OS>
//</TEMPLATE>
//`
//
//func createVRTemplate(client *goca.Client) error {
//	doc := &goca_dyn.Template{}
//
//	err := xml.Unmarshal([]byte(vrTemplate), &doc)
//	if err != nil {
//		return err
//	}
//
//	ctrl := goca.NewController(client)
//
//	id, err := ctrl.Templates().Create(doc.String())
//	if err != nil {
//		return err
//	}
//
//	result, err := ctrl.Template(id).Info(false, false)
//	if err != nil {
//		return err
//	}
//
//	fmt.Printf("%v\n", result)
//	return nil
//}

func ensureLB(one *goca.Client, clusterName, templateName, networkName string) error {
	ctrl := goca.NewController(one)

	vrID, err := ctrl.VirtualRouterByName(clusterName)
	if err != nil && err.Error() != "resource not found" {
		return err
	}
	if vrID < 0 {
		vmTemplateID, err := ctrl.Templates().ByName(templateName)
		if err != nil {
			return err
		}
		vmTemplate, err := ctrl.Template(vmTemplateID).Info(false, true)
		if err != nil {
			return err
		}

		vrTemplate := goca_vr.NewTemplate()
		vrTemplate.Add("NAME", clusterName)
                nicVec0 := &goca_dyn.Vector{XMLName: xml.Name{Local: "NIC"}}
                nicVec0.AddPair("NETWORK", "service")
                nicVec0.AddPair("FLOATING_IP", "YES")
		nicVec0.AddPair("FLOATING_ONLY", "YES")
		vrTemplate.Elements = append(vrTemplate.Elements, nicVec0)
                nicVec1 := &goca_dyn.Vector{XMLName: xml.Name{Local: "NIC"}}
                nicVec1.AddPair("NETWORK", "private")
                nicVec1.AddPair("FLOATING_IP", "YES")
		nicVec1.AddPair("FLOATING_ONLY", "NO")
		vrTemplate.Elements = append(vrTemplate.Elements, nicVec1)

		vrID, err = ctrl.VirtualRouters().Create(vrTemplate.String())
		if err != nil {
			return err
		}
		if _, err := ctrl.VirtualRouter(vrID).Instantiate(
			2,
			vmTemplateID,
			"",    // name
			false, // hold
			vmTemplate.Template.String(),
		); err != nil {
			return err
		}
	}
	vr, err := ctrl.VirtualRouter(vrID).Info(true)
	if err != nil {
		return err
	}
	fmt.Printf("%v\n", vr)

	parentID, err := ctrl.VirtualNetworks().ByName(networkName)
	if err != nil {
		return err
	}
	vnID, err := ctrl.VirtualNetworks().ByName(clusterName)
	if err != nil && err.Error() != "resource not found" {
		return err
	}
	reservationTemplate := &goca_dyn.Template{}
	reservationTemplate.AddPair("NAME", clusterName)
	reservationTemplate.AddPair("SIZE", 1)
	if vnID >= 0 {
		reservationTemplate.AddPair("NETWORK_ID", vnID)
	}
	vnID, err = ctrl.VirtualNetwork(parentID).Reserve(reservationTemplate.String())
	if err != nil {
		return err
	}
	vn, err := ctrl.VirtualNetwork(vnID).Info(true)
	if err != nil {
		return err
	}
	fmt.Printf("%d\n", vnID)

	for _, vmID := range vr.VMs.ID {
		vmCtrl := ctrl.VM(vmID)
		vm, err := vmCtrl.Info(true)
		if err != nil {
			return err
		}
		contextVec, err := vm.Template.GetVector("CONTEXT")
		if err != nil {
			return err
		}
		for k, ar := range vn.ARs {
			key := fmt.Sprintf("ONEAPP_VROUTER_ETH0_VIP%d", k + 1)
			contextVec.Del(key)
			contextVec.AddPair(key, ar.IP)
		}
		if err := vmCtrl.UpdateConf(vm.Template.String()); err != nil {
			return err
		}
	}

	// ensure VN
	// update VR

	return nil
}

func main() {
	log.Println("asd")

	one := goca.NewDefaultClient(
		goca.NewConfig("oneadmin", "asd", "http://10.2.11.40:2633/RPC2"),
	)

	log.Println(ensureLB(one, "asd", "capone131-vr", "service"))
}
