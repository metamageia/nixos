{ config, pkgs, inputs, ... }:
{
fonts.packages = with pkgs; [
  corefonts
  vistafonts
];    
}