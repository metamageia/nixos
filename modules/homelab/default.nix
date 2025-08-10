{
  inputs,
  config,
  pkgs,
  hostName,
  ...
}: {
  imports = [
    inputs.homelab.nixosModules.homelab
  ];

  environment.systemPackages = with pkgs; [k3s qbittorrent nebula];
  environment.variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

homelab = {
    role = "agent";
    tokenFile = config.sops.secrets.clusterSecret.path;
    clusterAddr = "https://auriga.gagelara.com:6443";
    sopsFile = ../../secrets/homelab.secrets.yaml;
  };

  sops.secrets = {
    "nebula/${hostName}.key" = {
      sopsFile = ../../secrets/homelab.secrets.yaml;
      owner = "root";
      group = "nebula-mesh";
      mode = "0640";
    };
    "nebula/${hostName}.crt" = {
      sopsFile = ../../secrets/homelab.secrets.yaml;
      owner = "root";
      group = "nebula-mesh";
      mode = "0644";
    };
    "nebula/ca.crt" = {
      sopsFile = ../../secrets/homelab.secrets.yaml;
      owner = "root";
      group = "nebula-mesh";
      mode = "0644";
    };
  };
  
  services.nebula.networks.mesh = {
    enable = true;
    isLighthouse = false;
    cert = config.sops.secrets."nebula/${hostName}.crt".path;
    key = config.sops.secrets."nebula/${hostName}.key".path;
    ca = config.sops.secrets."nebula/ca.crt".path; #08-09-2026
    staticHostMap = {
      "192.168.100.1" = [
        "134.199.241.26:4242"
      ];
    };
    lighthouses = ["192.168.100.1"];
    firewall = {
      inbound = [
        {
          host = "any";
          port = "any";
          proto = "any";
        }
      ];
      outbound = [
        {
          host = "any";
          port = "any";
          proto = "any";
        }
      ];
    };
  };
  networking.firewall.allowedTCPPorts = [
    6443
    2379
    2380
  ];
  networking.firewall.allowedUDPPorts = [
    8472
    4242
  ];
}
