{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    syncthing
  ];

  services = {
    syncthing = {
      enable = true;
      user = "metamageia";
      configDir = "/home/metamageia/Documents/.config/syncthing";
      openDefaultPorts = true;
      devices = {
        "auriga" = {id = "27P4DZL-P6VMQJB-G32VMXG-67DVGRJ-ZLOCJ5A-CE2TI65-62USK6K-2R5CFAW";};
        "saiadha" = {id = "FONRABV-HJBZQNY-J2CQVV2-PO53IEP-YRKGCP4-TCFEIAM-EGF5O3M-ZIP4BQY";};
        "pixel 2xl" = {id = "4PRXCDI-UKGADIJ-INQKWXL-WOUF3P3-JKH4WET-4EEQ5TP-YXR4AED-THF7WAA";};
        "pixel 8" = {id = "UVRIGUQ-547I3BL-WKLTYAY-7SJPE73-VOL6S2M-4PGHGMB-7X3WN6R-2H52LAI";};
      };
      folders = {
        "Obsidian" = {
          path = "/home/metamageia/Sync/Obsidian";
          devices = ["saiadha" "auriga" "pixel 2xl" "pixel 8"];
        };
        "Desktop" = {
          path = "/home/metamageia/Sync/Desktop";
          devices = ["saiadha" "auriga"];
        };
      };
    };
  };
}
