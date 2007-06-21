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
	$info .= N("Color depth: %s\n", translate($Xconfig::resolution_and_depth::depth2text{$resolution->{Depth}}));
	$info .= N("Resolution: %s\n", join('x', @$resolution{'X', 'Y'}));
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
	Composite => !($card->{Driver} eq 'fglrx' || $card->{Driver} eq 'nvidia' && $card->{DriverVersion} eq '71xx'),
	if_($card->{Driver} eq 'nvidia', RenderAccel => $card->{DriverVersion} eq '97xx', Clone => 0),
	if_($card->{Driver} eq 'savage', HWCursor => 1),
	if_($card->{Driver} eq 'intel' && $isLaptop, Clone => 0),
	if_($card->{Driver} eq 'ati' && $isLaptop, Clone => 1, BIOSHotkeys => 0),
	if_(exists $card->{DRI_GLX}, use_DRI_GLX => $card->{DRI_GLX} && !$card->{Xinerama}),
	if_(member($card->{Driver}, qw(i128 ati sis trident via savage)), EXA => 0), #- list taken from http://wiki.x.org/wiki/ExaStatus
    });
}

sub various {
    my ($in, $raw_X, $card, $options, $b_auto, $b_read_existing) = @_;

    tvout($in, $card, $options) if !$b_auto;

    my $use_DRI_GLX = member('dri', $raw_X->get_modules);

    my $various = { 
	if_($::isStandalone, xdm => runlevel() == 5),
	if_($b_read_existing,
	    Composite => ($raw_X->get_Section('Extensions') || {})->{Composite},
	      if_(($card->{Options}{MonitorLayout} || [])->[0] eq '"NONE,CRT+LFP"' ||
		  ($card->{Options}{TwinViewOrientation} || [])->[0] eq '"Clone"',
	    Clone => 1),
	      if_(($card->{Options}{MonitorLayout} || [])->[0] eq '"LVDS,NONE"',
	    Clone => 0),
	       if_($card->{Options}{BIOSHotkeys}, 
	    BIOSHotkeys => 1),
	      if_($card->{Options}{AccelMethod},
	    EXA => ($card->{Options}{AccelMethod} || [])->[0] eq '"EXA"'),
	      if_($card->{Driver} eq 'nvidia', 
	    RenderAccel => !$card->{Options}{RenderAccel},
	      ),
	    HWCursor => !$card->{Options}{SWCursor},
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

    if ($various->{Composite}) {
	my $raw = $raw_X->get_Section('Extensions') || $raw_X->add_Section('Extensions', {});
	$raw->{Composite} = { 'Option' => 1 };
	if ($card->{Driver} eq 'nvidia') {
	    $card->{Options}{AddARGBGLXVisuals} = undef;
	}
    } else {
	if (my $raw = $raw_X->get_Section('Extensions')) {
	    delete $raw->{Composite};
	    %$raw or $raw_X->remove_Section('Extensions');
	}
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
	if ($various->{EXA}) {
	    $card->{Options}{AccelMethod} = 'EXA';
	} else {
	    delete $card->{Options}{AccelMethod};
	}
    }

    if (exists $various->{Clone}) {
	if ($card->{Driver} eq 'nvidia') {
	    if ($various->{Clone}) {
		$card->{Options}{TwinView} = undef;
		$card->{Options}{TwinViewOrientation} = 'Clone';
	    } else {
		delete $card->{Options}{TwinView};
		delete $card->{Options}{TwinViewOrientation};
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
    } else {
	cat_($f) =~ /^id:(\d):initdefault:\s*$/m && $1;
    }
}

sub choose {
    my ($in, $various) = @_;

    $in->ask_from_({ title => N("Xorg configuration") }, [
	{ label => N("Graphic card options"), title => 1 },
	  exists $various->{use_DRI_GLX} ?
	{ text => N("3D hardware acceleration"),
	  type => 'bool', val => \$various->{use_DRI_GLX} } : (),
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
	  exists $various->{BIOSHotkeys} ?
	{ text => N("Enable BIOS hotkey for external monitor switching"),
	  type => 'bool', val => \$various->{BIOSHotkeys} } : (),	
	  exists $various->{EXA} ?
	{ text => N("Use EXA instead of XAA (better performance for Render and Composite)"),
	  type => 'bool', val => \$various->{EXA} } : (),
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

    $raw_X->write("$::prefix/etc/X11/XF86Config.tvout");

    check_XF86Config_symlink();

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

sub check_XF86Config_symlink() {
    my $f = "$::prefix/etc/X11/XF86Config";
    if (!-l $f && -e "$f.tvout") {
	rename $f, "$f.standard";
	symlink "XF86Config.standard", $f;
    }
}

sub setupFB {
    my ($bios_vga_mode) = @_;

    require bootloader;
    my ($bootloader, $all_hds);

    if ($::isInstall && !$::globetrotter) {
	($bootloader, $all_hds) = ($::o->{bootloader}, $::o->{all_hds});
    } else {
	require fsedit;
	require fs;
	require bootloader;
	$all_hds = fsedit::get_hds();
	fs::get_info_from_fstab($all_hds);

	$bootloader = bootloader::read($all_hds) or return;
    }

    foreach (@{$bootloader->{entries}}) {
	$_->{vga} = $bios_vga_mode if $_->{vga}; #- replace existing vga= with
    }

    bootloader::update_splash($bootloader);
    bootloader::action($bootloader, 'write', $all_hds);
    bootloader::action($bootloader, 'when_config_changed');
}

sub handle_May_Need_ForceBIOS {
    my ($in, $raw_X) = @_;

    Xconfig::resolution_and_depth::is_915resolution_configured and return;

    any { $_->{Options}{May_Need_ForceBIOS} } $raw_X->get_devices or return;

    my $log = cat_('/var/log/Xorg.0.log');
    $log =~ /Option "May_Need_ForceBIOS" is not used/ or return;


    my @builtin_modes = $log =~ /\*Built-in mode "(\d+x\d+)"/g or return;
    my $resolution = $raw_X->get_resolution;
    !member("$resolution->{X}x$resolution->{Y}", @builtin_modes) or return;

    $in->ask_yesorno('', formatAlaTeX(N("The display resolution being used may not be correct. 

If your desktop appears to stretch beyond the edges of the display, 
installing %s may help fix the problem. Install it now?", '915resolution')), 1) or return; 

    $in->do_pkgs->ensure_binary_is_installed('915resolution', '915resolution', 1) or return;

    Xconfig::resolution_and_depth::set_915resolution($resolution);

    'need_restart';
}

1;
