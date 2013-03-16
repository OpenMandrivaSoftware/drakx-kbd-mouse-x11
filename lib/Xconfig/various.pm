package Xconfig::various; # $Id$

use diagnostics;
use strict;

use Xconfig::card;
use Xconfig::default;
use Xconfig::resolution_and_depth;
use common;


sub to_string {
    my ($raw_X) = @_;

    $raw_X->is_fbdev ? 'frame-buffer' : Xconfig::resolution_and_depth::to_string($raw_X->get_resolution);
}

sub info {
    my ($raw_X, $card) = @_;
    my $info;
    my $keyboard = eval { $raw_X->get_keyboard } || {};
    my @monitors = eval { $raw_X->get_monitors };
    my $device = eval { $raw_X->get_device } || {};
    my $mouse = eval { first($raw_X->get_mice) } || {};

    $info .= N("Disable Ctrl-Alt-Backspace: %s\n", configure_ServerFlag($raw_X, 'DontZap') eq 'False' ? N("no") : N("yes"));
    $info .= N("3D hardware acceleration: %s\n", translate(bool2yesno($card->{use_DRI_GLX} || $card->{DRI_GLX_SPECIAL})));
    $info .= N("Keyboard layout: %s\n", $keyboard->{XkbLayout});
    $info .= N("Mouse type: %s\n", $mouse->{Protocol});
    foreach my $monitor (@monitors) {
	$info .= N("Monitor: %s\n", $monitor->{ModelName});
	$info .= N("Monitor HorizSync: %s\n", $monitor->{HorizSync});
	$info .= N("Monitor VertRefresh: %s\n", $monitor->{VertRefresh});
    }
    $info .= N("Graphics card: %s\n", $device->{VendorName} . ' ' . $device->{BoardName});
    $info .= N("Graphics memory: %s kB\n", $device->{VideoRam}) if $device->{VideoRam};
    if (my $resolution = eval { $raw_X->get_resolution }) {
	$info .= N("Color depth: %s\n", translate($Xconfig::resolution_and_depth::depth2text{$resolution->{Depth}})) if $resolution->{Depth};
	$info .= N("Resolution: %s\n", Xconfig::resolution_and_depth::to_string($resolution));
    }
    $info .= N("Xorg driver: %s\n", $device->{Driver}) if $device->{Driver};
    $info;
}

sub default {
    my ($card, $various) = @_;

    my $isLaptop = detect_devices::isLaptop();

    add2hash_($various, { 
	isLaptop => $isLaptop,
	xdm => 1,
	DontZap => 0,
	Composite => !($card->{Driver} eq 'nvidia' && $card->{DriverVersion} eq '71xx'),
	if_($card->{Driver} eq 'nvidia', RenderAccel => !member($card->{DriverVersion}, qw(71xx 96xx)), 
	                                 Clone => 0, ForceModeDVI => 0),
	if_($card->{Driver} eq 'savage', HWCursor => 1),
	if_($card->{Driver} eq 'intel' && $isLaptop, Clone => 0),
	if_($card->{Driver} eq 'ati' && $isLaptop, Clone => 1, BIOSHotkeys => 0),
	if_(exists $card->{DRI_GLX}, use_DRI_GLX => $card->{DRI_GLX} && !$card->{Xinerama}),
#	if_(member($card->{Driver}, qw(i128 ati sis trident via savage)), EXA => 0), #- list taken from http://wiki.x.org/wiki/ExaStatus
    });
}

sub various {
    my ($in, $raw_X, $card, $options, $b_auto, $b_read_existing) = @_;

    tvout($in, $card, $options) if !$b_auto;

    my $use_DRI_GLX = member('dri', $raw_X->get_modules);

    my $various = { 
	if_($::isStandalone, xdm => runlevel() == 5),
	if_($b_read_existing,
	    Composite => $raw_X->get_extension('Composite') ne 'Disable',
	      if_($card->{Options}{MonitorLayout} eq 'NONE,CRT+LFP' ||
		  $card->{Options}{TwinViewOrientation} eq 'Clone',
	    Clone => 1),
	      if_($card->{Options}{MonitorLayout} eq 'LVDS,NONE',
	    Clone => 0),
	       if_($card->{Options}{BIOSHotkeys}, 
	    BIOSHotkeys => 1),
	      if_($card->{Options}{AccelMethod},
	    EXA => $card->{Options}{AccelMethod} eq 'EXA'),
	      if_($card->{Options}{ModeValidation},
	    ForceModeDVI => 1),
	      if_($card->{Driver} eq 'nvidia', 
	    RenderAccel => !$card->{Options}{RenderAccel},
	      ),
	    HWCursor => !$card->{Options}{SWCursor},
	    DontZap => (configure_ServerFlag($raw_X, 'DontZap') eq 'False' ? 0 : 1),
	    if_($card->{DRI_GLX} || $use_DRI_GLX, use_DRI_GLX => $use_DRI_GLX),
	),
    };
    default($card, $various);

    if (!$b_auto) {
	choose($in, $various) or return;
    }

    config($raw_X, $card, $various) && $various;
}

sub various_auto_install {
    my ($raw_X, $card, $old_X) = @_;

    my $various = { %$old_X };
    default($card, $various);
    config($raw_X, $card, $various);
    1;
}

sub config {
    my ($raw_X, $card, $various) = @_;

    if (exists $various->{DontZap}) {
	configure_ServerFlag($raw_X, 'DontZap', $various->{DontZap} == 1 ? 'True' : 'False');
    }
    if ($various->{Composite}) {
	$raw_X->remove_extension('Composite');
	if ($card->{Driver} eq 'nvidia') {
	    $card->{Options}{AddARGBGLXVisuals} = undef;
	}
    } else {
	$raw_X->set_extension('Composite', 'Disable');

	if ($card->{Driver} eq 'nvidia') {
	    delete $card->{Options}{AddARGBGLXVisuals};
	}
    }
    if (exists $various->{use_DRI_GLX}) {
	$card->{use_DRI_GLX} = $various->{use_DRI_GLX};
    }

    if (exists $various->{RenderAccel}) {
	if ($various->{RenderAccel}) {
	    delete $card->{Options}{RenderAccel};
	} else {
	    $card->{Options}{RenderAccel} = 'false';
	}
    }

    if (exists $various->{HWCursor}) {
	if ($various->{HWCursor}) {
	    delete $card->{Options}{SWCursor};
	} else {
	    $card->{Options}{SWCursor} = undef;
	}
    }

    if (exists $various->{BIOSHotkeys}) {
	if ($various->{BIOSHotkeys}) {
	    $card->{Options}{BIOSHotkeys} = undef;
	} else {
	    delete $card->{Options}{BIOSHotkeys};
	}
    }

    if (exists $various->{EXA}) {
	if ($card->{Driver} eq 'intel') {
	    # the intel driver is able to automatically pick UXA/EXA
	    #  when xorg.conf has no accel method defined, but XAA
	    #  has to be explicitly selected, that's why the logic
	    #  is reversed compared to the other drivers
	    if ($various->{EXA}) {
		delete $card->{Options}{AccelMethod};
	    } else {
		$card->{Options}{AccelMethod} = 'EXA';
	    }
        } 
#        else {
#	    if ($various->{EXA}) {
#		$card->{Options}{AccelMethod} = 'EXA';
#	    } else {
#		delete $card->{Options}{AccelMethod};
#	    }
#	}
    }

    if (exists $various->{ForceModeDVI}) {
	if ($card->{Driver} eq 'nvidia') {
	    if ($various->{ForceModeDVI}) {
		$card->{Options}{ExactModeTimingsDVI} = undef;
		$card->{Options}{ModeValidation} = 'NoWidthAlignmentCheck, NoDFPNativeResolutionCheck';
	    } else {
		delete $card->{Options}{ExactModeTimingsDVI};
		delete $card->{Options}{ModeValidation};
	    }
	}
    }

    if (exists $various->{Clone}) {
	if ($card->{Driver} eq 'nvidia') {
	    if ($various->{Clone}) {
		$card->{Options}{TwinView} = undef;
		$card->{Options}{TwinViewOrientation} = 'Clone';
		delete $card->{Options}{DynamicTwinView};
	    } else {
		delete $card->{Options}{TwinView};
		delete $card->{Options}{TwinViewOrientation};
		#- below disables runtime setting of TwinView via nvidia-settings
		#- it helps on Compiz (#39171)
		$card->{Options}{DynamicTwinView} = 'false';
	    }
	} elsif ($card->{Driver} eq 'intel') {
	    if ($various->{Clone}) {
		$card->{Options}{MonitorLayout} = 'NONE,CRT+LFP';
	    } else {
		delete $card->{Options}{MonitorLayout};
	    }
	} elsif ($card->{Driver} eq 'ati') {
	    if ($various->{Clone}) {
		#- the default is Clone
		delete $card->{Options}{MonitorLayout};
	    } else {
		#- forcing no display on CRT
		$card->{Options}{MonitorLayout} = 'LVDS,NONE';
	    }
	}
    }

    Xconfig::various::runlevel($various->{xdm} ? 5 : 3);
}

sub runlevel {
    my ($o_runlevel) = @_;
    my $f = "$::prefix/etc/inittab";
    -r $f or log::l("missing inittab!!!"), return;
    if ($o_runlevel) {
	substInFile { s/^id:\d:initdefault:\s*$/id:$o_runlevel:initdefault:\n/ } $f if !$::testing;
	my $t = "/lib/systemd/system/runlevel$o_runlevel.target";
	if (!$::testing && -f "$::prefix$t") {
	    my $d = "$::prefix/etc/systemd/system/default.target";
	    unlink($d);
	    symlink($t, $d);
	}
    } else {
	cat_($f) =~ /^id:(\d):initdefault:\s*$/m && return $1;
	readlink("$::prefix/etc/systemd/system/default.target") =~ /runlevel(\d).target/m && return $1;
    }
}

sub choose {
    my ($in, $various) = @_;

    $in->ask_from_({ title => N("Xorg configuration") }, [
	{ label => N("Global options"), title => 1 },
	{ text => N("Disable Ctrl-Alt-Backspace"),
	  type => 'bool', val => \$various->{DontZap} },
	{ label => N("Graphic card options"), title => 1 },
	{ text => N("Enable Translucency (Composite extension)"),
	  type => 'bool', val => \$various->{Composite} },
	  exists $various->{HWCursor} ?
	{ text => N("Use hardware accelerated mouse pointer"),
	  type => 'bool', val => \$various->{HWCursor} } : (),
	  exists $various->{RenderAccel} ?
	{ text => N("Enable RENDER Acceleration (this may cause bugs displaying text)"),
	  type => 'bool', val => \$various->{RenderAccel} } : (),
	  exists $various->{Clone} ?
	{ text => $various->{isLaptop} ? 
	    N("Enable duplicate display on the external monitor") :
	    N("Enable duplicate display on the second display"),
	  type => 'bool', val => \$various->{Clone} } : (),
	  exists $various->{ForceModeDVI} ?
	{ text => N("Force display mode of DVI"),
	  type => 'bool', val => \$various->{ForceModeDVI} } : (),
	  exists $various->{BIOSHotkeys} ?
	{ text => N("Enable BIOS hotkey for external monitor switching"),
	  type => 'bool', val => \$various->{BIOSHotkeys} } : (),	
#	  exists $various->{EXA} ?
#	{ text => N("Use EXA instead of XAA (better performance for Render and Composite)"),
#	  type => 'bool', val => \$various->{EXA} } : (),
	{ label => N("Graphical interface at startup"), title => 1 },
	{ text => N("Automatically start the graphical interface (Xorg) upon booting"),
	  type => 'bool', val => \$various->{xdm} },
    ]) or return;

    1;
}

sub tvout {
    my ($in, $card, $options) = @_;

    $card->{FB_TVOUT} && $options->{allowFB} or return;

    $in->ask_yesorno('', N("Your graphic card seems to have a TV-OUT connector.
It can be configured to work using frame-buffer.

For this you have to plug your graphic card to your TV before booting your computer.
Then choose the \"TVout\" entry in the bootloader

Do you have this feature?")) or return;
    
    #- rough default value (rationale: http://download.nvidia.com/XFree86_40/1.0-2960/README.txt)
    require timezone;
    my $norm = timezone::read()->{timezone} =~ /America/ ? 'NTSC' : 'PAL';

    $norm = $in->ask_from_list('', N("What norm is your TV using?"), [ 'NTSC', 'PAL' ], $norm) or return;

    configure_FB_TVOUT($in->do_pkgs, { norm => $norm });
}

sub configure_FB_TVOUT {
    my ($do_pkgs, $use_FB_TVOUT) = @_;

    my $raw_X = Xconfig::default::configure($do_pkgs);
    return if is_empty_array_ref($raw_X);

    $raw_X->set_monitors({ HorizSync => '30-50', VertRefresh => ($use_FB_TVOUT->{norm} eq 'NTSC' ? 60 : 50),
			   ModeLine => [ 
	{ val => '"640x480"   29.50       640 675 678 944  480 530 535 625', pre_comment => "# PAL\n" },
	{ val => '"800x600"   36.00       800 818 820 960  600 653 655 750' },
	{ val => '"640x480"  28.195793   640 656 658 784  480 520 525 600', pre_comment => "# NTSC\n" },
	{ val => '"800x600"  38.769241   800 812 814 880  600 646 649 735' },
    ] });
    $raw_X->set_devices({ Driver => 'fbdev' });

    my ($device) = $raw_X->get_devices;
    my ($monitor) = $raw_X->get_monitors;
    $raw_X->set_screens({ Device => $device->{Identifier}, Monitor => $monitor->{Identifier} });

    my $Screen = $raw_X->get_default_screen;
    $Screen->{Display} = [ map { { l => { Depth => { val => $_ } } } } 8, 16 ];

    $raw_X->write("$::prefix/etc/X11/xorg.conf.tvout");

    check_xorg_conf_symlink();

    {
	require bootloader;
	require fsedit;
	require detect_devices;
	my $all_hds = $::isInstall ? $::o->{all_hds} : fsedit::get_hds();
	my $bootloader = $::isInstall ? $::o->{bootloader} : bootloader::read($all_hds);
	
	if (my $tvout = bootloader::duplicate_kernel_entry($bootloader, 'TVout')) {
	    $tvout->{append} .= " XFree=tvout";
	    bootloader::install($bootloader, $all_hds);
	}
    }
}

sub configure_ServerFlag {
    my ($raw_X, $option, $o_value) = @_;
    my $ServerFlags = $raw_X->get_Section('ServerFlags');
    my $option_ref = $ServerFlags->{$option}[0];
    if ($o_value) {
	$option_ref->{val} = $o_value;
	$option_ref->{commented} = 0;
	$option_ref->{Option} = 1;
    }
    return undef if $option_ref->{commented} == 1;
    $option_ref->{val};
}

sub check_xorg_conf_symlink() {
    my $f = "$::prefix/etc/X11/xorg.conf";
    if (!-l $f && -e "$f.tvout") {
	rename $f, "$f.standard";
	symlink "xorg.conf.standard", $f;
    }
}

sub change_bootloader_config {
    my ($do, @do_params) = @_;

    require bootloader;
    my ($bootloader, $all_hds);

    if ($::isInstall && !$::globetrotter) {
	($bootloader, $all_hds) = ($::o->{bootloader}, $::o->{all_hds});
	$bootloader && $bootloader->{method} or return;
    } else {
	require fsedit;
	require fs;
	require bootloader;
	$all_hds = fsedit::get_hds();
	fs::get_info_from_fstab($all_hds);

	$bootloader = bootloader::read($all_hds) or return;
    }

    $do->($bootloader, @do_params) or return;

    # Do not install bootloader when configuring X during install.
    # This will be done at end of summary to allow selecting where
    # to install bootloader.
    unless ($::isInstall) {
	bootloader::action($bootloader, 'write', $all_hds);
	bootloader::action($bootloader, 'when_config_changed');
    }

    1;
}

sub setupFB {
    my ($bios_vga_mode) = @_;

    change_bootloader_config(
	sub {
	    my ($bootloader, $bios_vga_mode) = @_;
	    foreach (@{$bootloader->{entries}}) {
		$_->{vga} = $bios_vga_mode if $_->{vga}; #- replace existing vga= with
	    }
	    bootloader::update_splash($bootloader);
	    1;
	}, $bios_vga_mode);
}

sub setup_kms() {
	# Check whether KMS is supported
	my $kms_ok = run_program::rooted($::prefix, "/sbin/display_driver_helper", "--is-kms-allowed") || 0;

	# Read the current Grub2 configuration
	my $grub;
	open($grub, '<', '/etc/default/grub') or return 0;
	my @lines = <$grub>;
	close($grub);

	# Update the kernel command line with KMS option
	my $cmdline_found = 0;
	foreach my $line (@lines) {
		# Skip comments
		next if ($line =~ m/^\s*#/);

		# If found the command line update it
		if ($line =~ m/^\s*GRUB_CMDLINE_LINUX_DEFAULT\s*=\s*(.*)/) {
			$cmdline_found = 1;
			# Strip the value from surrounding quotes (if any)
			my $value = $1;
			$value =~ s/^['"]//;
			$value =~ s/['"]$//;
			# To avoid messing with starting/trailing spaces, just split the list of parameters
			# and join it afterwards
			my @params = split(m/\s+/, $value);
			if ($kms_ok) {
				# KMS is supported, remove nokmsboot parameter
				$value = join(' ', grep { $_ ne 'nokmsboot' } @params);
			}
			else {
				# KMS is not supported, add nokmsboot (but remove it first to avoid duplicates)
				$value = join(' ', grep { $_ ne 'nokmsboot' } @params, 'nokmsboot');
			}
			# Finally update the source line of the config
			$line = "GRUB_CMDLINE_LINUX_DEFAULT=\"$value\"\n";
		}
	}

	# Save resultant config file
	open($grub, '>', '/etc/default/grub') or return 0;
	if (!$cmdline_found && !$kms_ok) {
		# We needed to add nokmsboot, but the command line option was not present in the config -> add it manually
		print $grub "GRUB_CMDLINE_LINUX_DEFAULT=\"nokmsboot\"\n"
	}
	foreach (@lines) {
		print $grub $_;
	}
	close($grub);
	system('grub2-mkconfig -o /boot/grub2/grub.cfg');
	return 1;
}

1;
