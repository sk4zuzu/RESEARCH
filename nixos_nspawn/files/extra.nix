{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    iptables iproute2 bridge-utils dnsutils tcpdump
    unzip zip
    mc tmux htop vim
    git
    gnumake patch
    openssl gnupg
    bat fd ripgrep
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "systemd.unified_cgroup_hierarchy=0" ];
    kernelModules = [ "ip6table_filter" "nbd" ];
  };

  networking = {
    enableIPv6 = true;
    bridges = {
      br0 = { interfaces = []; };
      br1 = { interfaces = []; };
    };
    interfaces = {
      br0.ipv4.addresses = [ { address = "10.2.11.1"; prefixLength = 24; } ];
      br1.ipv4.addresses = [ { address = "172.20.0.1"; prefixLength = 24; } ];
    };
    nat = {
      enable = true;
      externalInterface = "bond0";
      internalIPs = [ "10.2.11.0/24" ];
    };
    firewall = {
      enable = true;
      checkReversePath = false;
      trustedInterfaces = [ "br0" ];
      allowedTCPPorts = [ 22 ];
    };
  };
}
