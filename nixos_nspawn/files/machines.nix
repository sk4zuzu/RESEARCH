{ config, pkgs, lib, ... }:

let
  enable1 = true;
in {
  systemd.targets.machines.enable = true;
  systemd.nspawn = {
    delta = {
      enable = enable1;
      wantedBy = [ "machines.target" ];
      execConfig = {
        Boot = true;
        Capability = "all";
      };
      filesConfig = {
        Bind = [
          "${pkgs.linux_latest}/lib/modules/:/lib/modules/"
          "/sys/fs/cgroup/"
          "/sys/fs/fuse/"
          "/sys/module/"
          "/_datastores/:/var/lib/one/datastores/"
          "/_shared/"
        ];
      };
      networkConfig = {
        VirtualEthernet = true;
        Bridge = "br0";
        Port = "tcp:2202:22";
      };
    };
    epsilon = {
      enable = enable1;
      wantedBy = [ "machines.target" ];
      execConfig = {
        Boot = true;
        Capability = "all";
      };
      filesConfig = {
        Bind = [
          "${pkgs.linux_latest}/lib/modules/:/lib/modules/"
          "/sys/fs/cgroup/"
          "/sys/fs/fuse/"
          "/sys/module/"
          "/_datastores/:/var/lib/one/datastores/"
          "/_shared/"
        ];
      };
      networkConfig = {
        VirtualEthernet = true;
        Bridge = "br0";
        Port = "tcp:2204:22";
      };
    };
    omicron = {
      enable = enable1;
      wantedBy = [ "machines.target" ];
      execConfig = {
        Boot = true;
        Capability = "all";
      };
      filesConfig = {
        Bind = [
          "${pkgs.linux_latest}/lib/modules/:/lib/modules/"
          "/sys/fs/cgroup/"
          "/sys/fs/fuse/"
          "/sys/module/"
          "/_datastores/:/var/lib/one/datastores/"
          "/_shared/"
        ];
      };
      networkConfig = {
        VirtualEthernet = true;
        Bridge = "br0";
        Port = "tcp:2208:22";
      };
    };
    sigma = {
      enable = enable1;
      wantedBy = [ "machines.target" ];
      execConfig = {
        Boot = true;
        Capability = "all";
      };
      filesConfig = {
        Bind = [
          "/_datastores/:/var/lib/one/datastores/"
          "/_shared/"
        ];
      };
      networkConfig = {
        VirtualEthernet = true;
        Bridge = "br0";
        Port = "tcp:2216:22";
      };
    };
  };

  systemd.services = {
    "systemd-nspawn@delta" = {
      enable = enable1;
      wantedBy = [ "machines.target" ];
      bindsTo = [ "sys-devices-virtual-net-br0.device" ];
      after = [ "sys-devices-virtual-net-br0.device" ];
      serviceConfig = {
        Environment = "SYSTEMD_NSPAWN_USE_CGNS=0";
        DevicePolicy = "auto";
        Delegate = true;
      };
    };
    "systemd-nspawn@epsilon" = {
      enable = enable1;
      wantedBy = [ "machines.target" ];
      bindsTo = [ "sys-devices-virtual-net-br0.device" ];
      after = [ "sys-devices-virtual-net-br0.device" ];
      serviceConfig = {
        Environment = "SYSTEMD_NSPAWN_USE_CGNS=0";
        DevicePolicy = "auto";
        Delegate = true;
      };
    };
    "systemd-nspawn@omicron" = {
      enable = enable1;
      wantedBy = [ "machines.target" ];
      bindsTo = [ "sys-devices-virtual-net-br0.device" ];
      after = [ "sys-devices-virtual-net-br0.device" ];
      serviceConfig = {
        Environment = "SYSTEMD_NSPAWN_USE_CGNS=0";
        DevicePolicy = "auto";
        Delegate = true;
      };
    };
    "systemd-nspawn@sigma" = {
      enable = enable1;
      wantedBy = [ "machines.target" ];
      bindsTo = [ "sys-devices-virtual-net-br0.device" ];
      after = [ "sys-devices-virtual-net-br0.device" ];
      serviceConfig = {
        DevicePolicy = "auto";
        Delegate = true;
      };
    };
  };
}
