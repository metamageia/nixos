{
  config,
  pkgs,
  ...
}: {
  environment.variables = {
    LV2_PATH = "/run/current-system/sw/lib/lv2";
  };

  environment.systemPackages = with pkgs; [
    # Daw
    reaper
    bitwig-studio
    # ardour
    #lmms

    # Plugins
    distrho-ports
    bespokesynth
    rkrlv2
    mda_lv2
    x42-plugins
    carla
    soundfont-generaluser
    infamousPlugins
    talentedhack
    lsp-plugins
    drum-machine
    x42-avldrums
  ];
}
