SHELL := $(shell which bash)
SELF  := $(patsubst %/,%,$(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

define INPUT1
<domain type='kvm' id='4'>
  <os>
    <nvram template='/OVMF_VARS.fd' format='raw'>/nvram-r2a1</nvram>
  </os>
  <devices>
    <disk type='volume' device='disk'>
      <target dev='vda' bus='virtio'/>
    </disk>
    <disk type='file' device='cdrom'>
      <target dev='hda' bus='ide'/>
    </disk>
    <disk type='file' device='cdrom'>
      <target dev='hdb' bus='ide'/>
    </disk>
  </devices>
</domain>
endef

define XSLT1
<?xml version="1.0" ?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output omit-xml-declaration="yes" indent="yes"/>
  <xsl:template match="node()|@*">
     <xsl:copy>
       <xsl:apply-templates select="node()|@*"/>
     </xsl:copy>
  </xsl:template>

  <xsl:template match="/domain/os/nvram">
    <nvram templateFormat="raw">
      <xsl:apply-templates select="@*|node()"/>
    </nvram>
  </xsl:template>

  <xsl:template match="/domain/devices/disk[@type='volume']/target/@bus">
    <xsl:attribute name="bus">
      <xsl:value-of select="'ide'"/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="/domain/devices/disk[@type='volume']/target[@dev='vda']/@dev">
    <xsl:attribute name="dev">
      <xsl:value-of select="'hda'"/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="/domain/devices/disk[@type='file']/target[@dev='hda']/@dev">
    <xsl:attribute name="dev">
      <xsl:value-of select="'hdb'"/>
    </xsl:attribute>
  </xsl:template>

  <xsl:template match="/domain/devices/disk[@type='file']/target[@dev='hdb']/@dev">
    <xsl:attribute name="dev">
      <xsl:value-of select="'hdc'"/>
    </xsl:attribute>
  </xsl:template>

</xsl:stylesheet>
endef

export

.PHONY: all

all:
	xsltproc <(echo "$$XSLT1") <(echo "$$INPUT1")
