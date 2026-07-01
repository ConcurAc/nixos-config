{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.users.files;

  # Filter to normal users and key by name for lookup.
  allUsersByName =
    let
      normal = lib.filterAttrs (_: u: u.isNormalUser) config.users.users;
    in
    builtins.listToAttrs (
      map (u: { name = u.name; value = u; }) (lib.attrValues normal)
    );

  userNames = lib.attrNames allUsersByName;

  allGroupsList = lib.attrValues config.users.groups;

  # Union of a user's extraGroups and any group that lists them in members.
  getUserGroups =
    userName:
    let
      user = allUsersByName.${userName} or null;
    in
    if user == null then
      [ ]
    else
      lib.unique (
        (user.extraGroups or [ ])
        ++ map (g: g.name) (lib.filter (g: builtins.elem userName (g.members or [ ])) allGroupsList)
      );

  inGroup = userName: group: builtins.elem group (getUserGroups userName);

  enabledOverlays = lib.filterAttrs (_: o: o.enable) cfg.overlays;

  # Overlays whose group membership requirements the user satisfies.
  overlaysFor =
    userName:
    lib.filterAttrs (
      _: o:
      inGroup userName o.group
      && lib.all (g: inGroup userName g) o.requiredGroups
    ) enabledOverlays;

  # Flat list of every (user, overlay) pair that needs a mount.
  allMounts = lib.flatten (
    map (
      u:
      lib.mapAttrsToList (s: o: {
        userName = u;
        groupName = o.group;
        shareName = s;
        overlay = o;
      }) (overlaysFor u)
    ) userNames
  );

  # Path layout helpers. Mount-scoped helpers take the ctx record from allMounts.
  # share and user are called outside a mount context so take plain strings.
  paths = {
    user    = u:                          "${cfg.usersDir}/${u}";
    share   = s:                          "${cfg.shareDir}/${s}";
    overlay = { userName, shareName, ... }: "${cfg.usersDir}/${userName}/.overlay/${shareName}";
    upper   = { userName, shareName, ... }: "${cfg.usersDir}/${userName}/.overlay/${shareName}/upper";
    work    = { userName, shareName, ... }: "${cfg.usersDir}/${userName}/.overlay/${shareName}/work";
    merge   = { userName, overlay,   ... }: "${cfg.usersDir}/${userName}/${overlay.mountPoint}";
  };

  primaryGroup = u: (allUsersByName.${u} or config.users.users.${u}).group;

  # Build the mount options string for an overlay.
  # allow_other is FUSE-only and must be omitted when PAM mounts on login
  # (PAM already runs as the target user, so the kernel option is irrelevant).
  mkOptions =
    ctx@{ userName, shareName, overlay, ... }:
    let
      dirs = [
        "lowerdir=${paths.share shareName}"
        "upperdir=${paths.upper ctx}"
        "workdir=${paths.work ctx}"
      ];
      fuseOpts = lib.optionals cfg.useFuse (
        lib.optional (!cfg.usePam) "allow_other"
        ++ [ "squash_to_uid=${toString (allUsersByName.${userName}).uid}" ]
      );
    in
    lib.concatStringsSep "," (lib.uniqueStrings (dirs ++ fuseOpts ++ overlay.extraOptions));

  # One pam_mount XML volume entry per (user, overlay) pair.
  mkVolumeEntry =
    ctx@{ userName, shareName, ... }:
    let
      mp   = paths.merge ctx;
      opts = mkOptions ctx;
    in
    if cfg.useFuse then ''
      <volume
        user="${userName}"
        fstype="fuse"
        path="fuse-overlayfs#${paths.share shareName}"
        mountpoint="${mp}"
        options="${opts}"
      />''
    else ''
      <volume
        user="${userName}"
        fstype="overlay"
        path="overlay"
        mountpoint="${mp}"
        options="${opts}"
      />'';

  # One systemd .mount unit per (user, overlay) pair for kernel overlayfs.
  mkMountUnit =
    ctx@{ userName, ... }:
    {
      what    = "overlay";
      where   = paths.merge ctx;
      type    = "overlay";
      options = mkOptions ctx;
      after    = [ "systemd-tmpfiles-setup.service" ];
      requires = [ "systemd-tmpfiles-setup.service" ];
      wantedBy = [ "multi-user.target" ];
      users    = [ userName ];
    };

  # One oneshot service per (user, overlay) pair for FUSE overlayfs.
  mkFuseService =
    ctx@{ userName, groupName, shareName, ... }:
    let
      name = "fuse-overlay-${userName}-${shareName}";
    in
    {
      ${name} = {
        description = "FUSE overlay for ${userName} on ${shareName}";
        after    = [ "systemd-tmpfiles-setup.service" ];
        requires = [ "systemd-tmpfiles-setup.service" ];
        before   = [ "multi-user.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type             = "oneshot";
          RemainAfterExit  = true;
          ExecStart = "${lib.getExe pkgs.fuse-overlayfs} -o ${mkOptions ctx} ${paths.merge ctx}";
          ExecStop  = "${lib.getExe' pkgs.fuse3 "fusermount3"} -u ${paths.merge ctx}";
          User  = userName;
          Group = groupName;
        };
      };
    };

in
{
  options.users.files = {
    enable = lib.mkEnableOption "per-user overlay filesystem setup";

    shareDir = lib.mkOption {
      type    = lib.types.str;
      default = "/srv/share";
      description = ''
        Root of shared lower-layer content. Each enabled overlay uses
        a subdirectory named after its attribute key.
      '';
    };

    usersDir = lib.mkOption {
      type    = lib.types.str;
      default = "/srv/users";
      description = ''
        Root of per-user directories. A user "alice" gets /srv/users/alice
        and their overlay mount points inside it.
      '';
    };

    usePam = lib.mkEnableOption ''
      Mount overlays on login via PAM instead of at boot.
    '';

    useFuse = lib.mkEnableOption ''
      Use fuse-overlayfs instead of kernel overlayfs.

      Kernel overlayfs requires CAP_SYS_ADMIN and does not support per-user
      ownership. fuse-overlayfs allows unprivileged mounts owned by the target
      user at the cost of higher I/O overhead.
    '';

    overlays = lib.mkOption {
      default     = { };
      description = ''
        Attribute set of content groups. The key is the overlay name, used as
        the lower-directory name and default mount point.

        A user receives an overlay when they belong to the overlay's `group`
        and every group in `requiredGroups`.

        Example: user "alice", overlay key "games", group "games":
          lowerdir: /srv/share/games
          upperdir: /srv/users/alice/.overlay/games/upper
          workdir:  /srv/users/alice/.overlay/games/work
          merged:   /srv/users/alice/games
      '';
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              enable = lib.mkEnableOption "this overlay";

              group = lib.mkOption {
                type        = lib.types.str;
                default     = name;
                description = "Primary Unix group controlling access to this overlay.";
              };

              requiredGroups = lib.mkOption {
                type        = lib.types.listOf lib.types.str;
                default     = [ ];
                description = "Additional groups a user must belong to.";
              };

              extraOptions = lib.mkOption {
                type        = lib.types.listOf lib.types.str;
                default     = [ ];
                description = "Extra options appended to the mount command.";
              };

              mountPoint = lib.mkOption {
                type        = lib.types.str;
                default     = name;
                description = "Directory created under the user's dir for this overlay.";
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      # Catch typos in group names before they silently produce no mounts.
      {
        assertion = lib.all
          (o: config.users.groups ? ${o.group})
          (lib.attrValues enabledOverlays);
        message =
          "users.files: overlay references unknown group(s): "
          + lib.concatStringsSep ", " (
            lib.filter
              (n: !(config.users.groups ? ${(enabledOverlays.${n}).group}))
              (lib.attrNames enabledOverlays)
          );
      }
      {
        assertion = lib.all (o:
          lib.all (g: config.users.groups ? ${g}) o.requiredGroups
        ) (lib.attrValues enabledOverlays);
        message =
          "users.files: overlay requiredGroups references unknown group(s)";
      }
      # uid is required by fuse-overlayfs's squash_to_uid option.
      {
        assertion =
          !cfg.useFuse
          || lib.all (u: allUsersByName.${u}.uid != null) (lib.unique (map (m: m.userName) allMounts));
        message =
          "users.files: useFuse requires explicit uid for: "
          + lib.concatStringsSep ", " (
            lib.filter (u: allUsersByName.${u}.uid == null) (lib.unique (map (m: m.userName) allMounts))
          );
      }
    ];

    # Create share, user, and overlay dirs before any mounts run.
    systemd.tmpfiles.rules = lib.unique (
      [ "d ${cfg.shareDir} 0755 root root -" ]
      ++ lib.mapAttrsToList (s: o: "d ${paths.share s} 2750 root ${o.group} -") enabledOverlays
      ++ map (u: "d ${paths.user u} 0750 ${u} ${primaryGroup u} -") userNames
      ++ lib.flatten (
        map (
          ctx@{ userName, groupName, ... }:
          let userGroup = primaryGroup userName; in
          [
            "d ${paths.overlay ctx} 0700 ${userName} ${userGroup} -"
            "d ${paths.upper   ctx} 0700 ${userName} ${userGroup} -"
            "d ${paths.work    ctx} 0700 ${userName} ${userGroup} -"
            "d ${paths.merge   ctx} 0750 ${userName} ${groupName} -"
          ]
        ) allMounts
      )
    );

    systemd.mounts = lib.optionals (!cfg.usePam && !cfg.useFuse)
      (map mkMountUnit allMounts);

    systemd.services = lib.mkIf (!cfg.usePam && cfg.useFuse)
      (lib.mkMerge (map mkFuseService allMounts));

    security.pam.mount = lib.mkIf cfg.usePam {
      enable             = true;
      extraVolumes       = map mkVolumeEntry allMounts;
      additionalSearchPaths = lib.optional cfg.useFuse pkgs.fuse-overlayfs;
    };

    programs.fuse = {
      enable        = cfg.useFuse;
      userAllowOther = lib.mkDefault (!cfg.usePam && cfg.useFuse);
    };
  };
}
