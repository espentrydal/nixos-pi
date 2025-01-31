{ config, pkgs, lib, ... }:
{
  # NixOS wants to enable GRUB by default
  boot.loader.grub.enable = false;
  # Enables the generation of /boot/extlinux/extlinux.conf
  boot.loader.generic-extlinux-compatible.enable = true;

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

  boot.loader.raspberryPi.firmwareConfig = ''
    dtparam=audio=off
    dtoverlay=disable-bt
    dtoverlay=disable-wifi
    gpu_mem=16
  '';

  boot.blacklistedKernelModules = [
    "btqca"
    "btsdio"
    "hci_uart"
    "btbcm"
    "bluetooth"
  ];

  imports =
    [
      <nixpkgs/nixos/modules/profiles/minimal.nix>
      <nixpkgs/nixos/modules/profiles/hardened.nix>
    ];

  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;
  networking.hostName = "pihole";

  networking.nameservers = [
    "8.8.8.8"
  ];

  networking.firewall.allowedTCPPorts = [ 53 80 ];
  networking.firewall.allowedUDPPorts = [ 53 ];

  # Disable ipv6
  networking.enableIPv6 = false;

  console.keyMap = "nb";

  time.timeZone = "Europe/Oslo";

  environment.systemPackages = with pkgs; [
    bind
    git
  ];

  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;

  programs.htop.enable = true;
  programs.htop.settings = {
    hide_kernel_threads = true;
    hide_userland_threads = true;
  };

  virtualisation.oci-containers.backend = "podman";
  virtualisation.oci-containers.containers.pihole = {
    image = "pihole/pihole:2022.07.1";
    ports = [
      "53:53/udp"
      "53:53/tcp"
      "80:80/tcp"
    ];
    environment = {
      TZ = config.time.timeZone;
      WEB_PORT = "80";
      WEBPASSWORD = "toor";
      #VIRTUAL_HOST = "192.168.1.114";
      PIHOLE_DNS_ = "127.0.0.1#5353";
      REV_SERVER = "true";
      REV_SERVER_DOMAIN = "router.lan";
      REV_SERVER_TARGET = "192.168.0.1";
      REV_SERVER_CIDR = "192.168.0.0/16";
      DNSMASQ_LISTENING = "local";
    };
    extraOptions = [
      "--network=host"
    ];
  };

  systemd.services."podman-pihole".postStart = ''
    sleep 300s

    #podman exec pihole pihole -a addcustomdns 192.168.0.150 server-mads.lan false
    podman exec pihole pihole -a addcustomdns 192.168.0.114 pihole.lan true

    podman exec pihole pihole -a adlist add "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
    podman exec pihole pihole -a adlist add "https://adaway.org/hosts.txt"
    podman exec pihole pihole -a adlist add "https://v.firebog.net/hosts/AdguardDNS.txt"
    podman exec pihole pihole -a adlist add "https://v.firebog.net/hosts/Admiral.txt"
    podman exec pihole pihole -a adlist add "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt"
    podman exec pihole pihole -a adlist add "https://v.firebog.net/hosts/Easylist.txt"
    podman exec pihole pihole -a adlist add "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&mimetype=plaintext"
    podman exec pihole pihole -a adlist add "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/UncheckyAds/hosts"
    podman exec pihole pihole -a adlist add "https://raw.githubusercontent.com/bigdargon/hostsVN/master/hosts"
    podman exec pihole pihole -a adlist add "https://raw.githubusercontent.com/jdlingyu/ad-wars/master/hosts"
    podman exec pihole pihole -a adlist add "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
    podman exec pihole pihole -a adlist add "https://v.firebog.net/hosts/static/w3kbl.txt"
    podman exec pihole pihole -a adlist add "https://raw.githubusercontent.com/matomo-org/referrer-spam-blacklist/master/spammers.txt"
    podman exec pihole pihole -a adlist add "https://v.firebog.net/hosts/Shalla-mal.txt"
    podman exec pihole pihole -a adlist add "https://raw.githubusercontent.com/Spam404/lists/master/main-blacklist.txt"
    podman exec pihole pihole -a adlist add "https://someonewhocares.org/hosts/zero/hosts"
    podman exec pihole pihole -a adlist add "https://raw.githubusercontent.com/HorusTeknoloji/TR-PhishingList/master/url-lists.txt"
    podman exec pihole pihole -a adlist add "https://v.firebog.net/hosts/Easyprivacy.txt"
    podman exec pihole pihole -a adlist add "https://v.firebog.net/hosts/Prigent-Ads.txt"
    podman exec pihole pihole -a adlist add "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-blocklist.txt"
    podman exec pihole pihole -a adlist add "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
    podman exec pihole pihole -a adlist add "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/spy.txt"
    podman exec pihole pihole -a adlist add "https://hostfiles.frogeye.fr/firstparty-trackers-hosts.txt"
    podman exec pihole pihole -a adlist add "https://hostfiles.frogeye.fr/multiparty-trackers-hosts.txt"
    podman exec pihole pihole -a adlist add "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/android-tracking.txt"
    podman exec pihole pihole -a adlist add "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/SmartTV.txt"
    podman exec pihole pihole -a adlist add "https://raw.githubusercontent.com/Perflyst/PiHoleBlocklist/master/AmazonFireTV.txt"
    podman exec pihole pihole -a adlist add "https://raw.githubusercontent.com/RooneyMcNibNug/pihole-stuff/master/SNAFU.txt"
    podman exec pihole pihole -a adlist add "https://www.github.developerdan.com/hosts/lists/ads-and-tracking-extended.txt"
    podman exec pihole pihole -a adlist add "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt"
    podman exec pihole pihole -a adlist add "https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt"
    podman exec pihole pihole -a adlist add "https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt"
    podman exec pihole pihole -a adlist add "https://phishing.army/download/phishing_army_blocklist_extended.txt"
    podman exec pihole pihole -a adlist add "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt"
    podman exec pihole pihole -a adlist add "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Risk/hosts"
    podman exec pihole pihole -a adlist add "https://urlhaus.abuse.ch/downloads/hostfile/"
    podman exec pihole pihole -a adlist add "https://v.firebog.net/hosts/Prigent-Malware.txt"
    podman exec pihole pihole -a adlist add "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/gambling-porn/hosts"
    podman exec pihole pihole -a adlist add "https://raw.githubusercontent.com/chadmayfield/my-pihole-blocklists/master/lists/pi_blocklist_porn_all.list"
    podman exec pihole pihole -a adlist add "https://v.firebog.net/hosts/Prigent-Crypto.txt"
    podman exec pihole pihole -a adlist add "https://zerodot1.gitlab.io/CoinBlockerLists/hosts_browser"


    podman exec pihole pihole -b "dubaid.co.uk"
    podman exec pihole pihole --regex '\.asia$'
    podman exec pihole pihole --regex '\.cn$'
    podman exec pihole pihole --regex '(\.|^)huawei\.com$'
    podman exec pihole pihole --regex '(\.|^)open-telekom-cloud\.com$'
    podman exec pihole pihole --regex 'dbank'
    podman exec pihole pihole --regex 'hicloud'

    podman exec pihole pihole -w "connectivitycheck.cbg-app.huawei.com"
    podman exec pihole pihole -w "connectivitycheck.platform.hicloud.com"
    podman exec pihole pihole -w "fonts.gstatic.com"
    podman exec pihole pihole -w "4chan.org"
    podman exec pihole pihole -w "boards.4channel.org"
    podman exec pihole pihole -w "boards.4chan.org"


    podman exec pihole pihole -g
  '';


  services.dnscrypt-proxy2 = {
    enable = true;
    settings = {
      listen_addresses = [ "127.0.0.1:5353" ];
      server_names = [
        "uncensoreddns-ipv4"
        "uncensoreddns-dk-ipv4"
        "powerdns-doh"
        "dns.watch"
        "moulticast-de-ipv4"
      ];
      block_ipv6 = true;
      ipv6_servers = false;
    };
  };


  users.mutableUsers = false;
  users.users."root" = {
    password = "toor";
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDJpV5T4yWP+OFeRvANCCs321zgAFkJRo1+QdEnjbJOgUdoCtyS2nhO4Od1ERaKck1g2bViWafaqIH2f9vvHGF/mn4pywGsEXpnUnzJLSl3wkjSa61qJcck2N6jQaCZgL25dGoaRdbnGrfYP2k17iS/osy4UKZujUX6zbV+f2uRJ9/EXfnFtpaxUt+tRocyj+zK9HadmXG0qzjWVt+HIepQIbf38pxoJSZfX3bYIRJR9cRfdst/Vk3qDLaMGWoEimdRXKLUWrs5VuOejHPT14sHGOmNcZCyQRoFbp6n2pxCvnbvTQTlPHTtv6fPJb8BFh9KDwHAjPCOZlUmiYerxv3/VkWuqNmk33ZpJ28VvGIg6/nEldtK9+rEVKKr6qR9ccDs4bNuecQz6uTrn0bkPFLuJpMDRbZxnOSVoBvIGD3Qp+IwkY+zgW6tNXYVUBgr8TsZAFmqDTpkd1mR/QtbDNd1wyzTEy072gMwJPQ4WRFZy7Rlbh7XFexKMigP+zw/E5iaiHVbGg1aRa/zxoyyEOTJK8083r1A7pFWpfjrubIOz15QrjMgm34IZCcQnyKK4XA7/5ZwuXtjmzaJxGfreV226/jCmRs6F5W0FWcZehP/ZZ2+7/e25qrMIT6147OcQJ6jbOaOjZ036KkoVZyi8ZaYjJKaVoO4pMz4POTZgPEVbQ== pihole"
    ];
  };


  services.openssh = {
    enable = true;
    permitRootLogin = "yes";
    passwordAuthentication = false;
    challengeResponseAuthentication = false;
  };

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
  };

  nix.gc = {
    automatic = true;
    options = "-d";
  };
  nix.autoOptimiseStore = true;
}
