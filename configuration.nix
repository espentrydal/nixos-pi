{ config, pkgs, lib, ... }:
let
  home-manager = builtins.fetchGit {
    url = "https://github.com/rycee/home-manager.git";
    ref = "release-22.05";
  };

in
{
  imports = [
    <nixpkgs/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix>
    (import "${home-manager}/nixos")
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_rpi4;
    tmpOnTmpfs = true;
    initrd.availableKernelModules = [ "usbhid" "usb_storage" ];
    # ttyAMA0 is the serial console broken out to the GPIO
    kernelParams = [
        "8250.nr_uarts=1"
        "console=ttyAMA0,115200"
        "console=tty1"
        # A lot GUI programs need this, nearly all wayland applications
        "cma=128M"
    ];
  };

  boot.loader.raspberryPi = {
    enable = true;
    version = 4;
  };
  boot.loader.grub.enable = false;

  # Required for the Wireless firmware
  #hardware.enableRedistributableFirmware = true;

  nix = {
    autoOptimiseStore = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    # Free up to 1GiB whenever there is less than 100MiB left.
    extraOptions = ''
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
    '';
  };


  # File systems configuration for using the installer's partition layout
  fileSystems = {
    # Prior to 19.09, the boot partition was hosted on the smaller first partition
    # Starting with 19.09, the /boot folder is on the main bigger partition.
    # The following is to be used only with older images.
    /*
    "/boot" = {
      device = "/dev/disk/by-label/NIXOS_BOOT";
      fsType = "vfat";
    };
    */
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
  };
  # !!! Adding a swap file is optional, but strongly recommended!
  swapDevices = [ { device = "/swapfile"; size = 1024; } ];

  # systemPackages
  environment.systemPackages = with pkgs; [
    avahi
    bat
    emacs
    fzf
    git
    git-credential-gopass
    gnupg
    gopass
    htop
    mosh
    neovim
    python
    ripgrep
    tailscale
    tmux
    tree
    vim
    wget ];

  programs.zsh = {
      enable = true;
      ohMyZsh = {
          enable = true;
          theme = "bira";
      };
  };

  hardware = {
    enableRedistributableFirmware = true;
    firmware = [ pkgs.wireless-regdb ];
  };

  # Networking
  networking.hostName = "pi4-nixos"; # Define your hostname.
  # WiFi
  networking.wireless.enable = true;
  networking.wireless.userControlled.enable = true;
  networking.wireless.networks = {
    Get-D445A3 = {
      pskRaw="665af6c0e84f5c29d57e3abcb57ee62002392fb38546e16bc78c2a51d5fcf4b4";
    };
  };
  # Avahi
  services.avahi = {
    enable = true;
    nssmdns = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };
  # OpenSSH
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    permitRootLogin = lib.mkDefault "no";
    openFirewall = false;
  };

    # enable the tailscale daemon; this will do a variety of tasks:
  # 1. create the TUN network device
  # 2. setup some IP routes to route through the TUN
  services.tailscale = { enable = true; };
  networking.firewall.allowedUDPPorts = [ 41641 ];
  networking.firewall.checkReversePath = "loose";

  # Users
  users.users.espen = {
    isNormalUser = true;
    home = "/home/espen";
    description = "Espen Trydal";
    extraGroups = [ "wheel" ];
    uid = 1000;
    shell = pkgs.zsh;
  };

  users.users.espen.openssh.authorizedKeys.keys = [
    # This is my public key
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDAiaiBQhGCjeFk8EyRFN+pLSxHqNUQNpx8rP3SxqzA+fpTho/pkq+QqoTt0m2qXlmA2KKJQ9ai2uGAm+iiPmRc3908YS91kL9NjpBvlsyakBAWU366GTAZU1oSQHnshSZnJplyKt5gNMbXQMLHWnlWIr9co3jL8KAI+XNnP8ZrwTMSneK8LPhWYp/NldYH1cazEWTagYoTy9NuUrug1wGkmepCR3bY1I+NbFmsFZtYt4YVA9KUvTuTrR1uvirRn4YQdBMfuYXQIPkAVtBRpk0N1EXC2PnOex3tr5h30VcIJCKYqaYhw7Q9lZP/K97+IzfMv1HD7ei8RZc2BR5KcJUkgvmTBwy0os5WlwbJ32qzJulv8kaZ02IQOpo+zK/g+qH9P1IYiSRMFR796t0V2lFH67+hSfNKLWvQ6gnIDZAnkecJ05moSQ+djFnc7n7H4yncNQ+GegxQeOlMyZnzppMAeZ4i4maz83ri8kk88uDWNekJgDREVhkDiMLHfw+cChc= espen@thinkpad-nixos"
  ];

  home-manager.users.espen = { config, pkgs, ... }: {
    home.username = "espen";
    programs.git = {
      enable = true;
      userName = "Espen Trydal";
      userEmail = "espen@trydal.io";
      extraConfig = {
        credential.helper = "gopass";
        init.defaultBranch = "main";
      };
    };
  };

  system.stateVersion = "22.05"; # First install
}
