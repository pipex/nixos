{ config, pkgs, lib, ... }:

{
  # Packages to install
  home.packages = [
    # pkgs is the set of all packages in the default home.nix implementation
    pkgs.gcc
    pkgs.fzf
    pkgs.ripgrep
    pkgs.neovim
    pkgs.tmux
    pkgs.curl
    pkgs.openssh
    pkgs.lazygit
    pkgs.rustup
    pkgs.shfmt
    pkgs.shellcheck
    pkgs.rust-analyzer
    pkgs.nixpkgs-fmt
    pkgs.rnix-lsp
    pkgs.jq
    pkgs.unzip
    pkgs."nodejs-16_x"
    # TODO: check system before installing this
    # pkgs.reattach-to-user-namespace
  ];

  # Install AstroVim
  xdg.configFile."nvim".recursive = true;
  xdg.configFile."nvim".source = pkgs.fetchFromGitHub {
    owner = "AstroNvim";
    repo = "AstroNvim";
    rev = "v2.6.3";
    sha256 = "11dyfilk4xh9m7zwm7c951l28h2ixqzmqdn86rngv0kl6yp5jzsp";
  };
  xdg.configFile."nvim/lua/user".source = pkgs.fetchFromGitHub {
    owner = "pipex";
    repo = "astronvim";
    rev = "b54b853c971b3cf9318a3c31e7a2a3e8629f4c9a";
    sha256 = "1avc4pjrvbb0pcln2q5216c7rjpg8xj5vlhr1fj880awgb2a23k9";
  };
  # xdg.configFile."nvim/lua/user".source = ./astronvim;

  xdg.configFile."oh-my-zsh".source = ./oh-my-zsh;

  home.file.".tmux.conf".source = ./tmux/tmux.conf;
  home.file.".tmux".recursive = true;
  home.file.".tmux".source = ./tmux;
  home.file.".tmux/plugins/tpm".source = pkgs.fetchFromGitHub {
    owner = "tmux-plugins";
    repo = "tpm";
    rev = "v3.0.0";
    sha256 = "18q5j92fzmxwg8g9mzgdi5klfzcz0z01gr8q2y9hi4h4n864r059";
  };

  # Prettier
  home.file.".prettierrc".source = ./prettierrc;

  # Git config using Home Manager modules
  programs.git = {
    enable = true;
    userName = "Felipe Lalanne";
    userEmail = "1822826+pipex@users.noreply.github.com";
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
      push = {
        autoSetupRemote = true;
      };
      pull = {
        rebase = true;
      };
      core = {
        editor = "nvim";
      };
    };
    aliases = {
      lg = "log --graph --pretty='\''%Cred%h%Creset -%C(auto)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'\'' --all";
    };
  };

  programs.autojump = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      ll = "ls -l";
      update = "home-manager switch";
      vi = "nvim";
      lg = "lazygit";
    };
    localVariables = {
      TZ = "America/Santiago";
      EDITOR = "nvim";
    };
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };
    initExtra = ''
      export NVM_DIR="$HOME/.nvm"
      [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
      [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

      cs() {
        folder=$1
        [ "$folder" = "" ] && folder="balena-supervisor"
        git clone git@github.com:balena-os/balena-supervisor.git $folder && cd $folder && git checkout -b $folder && nix-shell -p dbus pkg-config --run "npm ci"
      }
    '';

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      custom = "${config.xdg.configHome}/oh-my-zsh";
      theme = "pipex";
    };

    plugins = [
      {
        name = "zsh-nix-shell";
        file = "nix-shell.plugin.zsh";
        src = pkgs.fetchFromGitHub {
          owner = "chisui";
          repo = "zsh-nix-shell";
          rev = "v0.5.0";
          sha256 = "0za4aiwwrlawnia4f29msk822rj9bgcygw6a8a6iikiwzjjz0g91";
        };
      }
    ];
  };


  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.05";
}
