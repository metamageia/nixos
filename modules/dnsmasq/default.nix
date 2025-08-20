{pkgs, ...}:
{
  services.dnsmasq = {
  enable = true;
  listenAddress = [ "192.168.100.1" "127.0.0.1" ]; # nebula + local loopback
  extraConfig = ''
    addn-hosts=/etc/dnsmasq.hosts
    domain=home.internal
    no-resolv
  '';
};

environment.etc."dnsmasq.hosts".text = ''
192.168.100.1 beacon.home.internal beacon
192.168.100.2 saiadha.home.internal saiadha
192.168.100.3 auriga.home.internal auriga
'';

}