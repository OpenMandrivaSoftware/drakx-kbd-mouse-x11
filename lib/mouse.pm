package mouse; # $Id$

#use diagnostics;
#use strict;

#-######################################################################################
#- misc imports
#-######################################################################################
use common;
use modules;
use detect_devices;
use run_program;
use devices;
use modules;
use any;
use log;

sub _all_mice() {
 arch() =~ /^sparc/ ? 
(
 'sunmouse' =>
 [ [ 'sunmouse' ],
   [ [ 3, 'sun', 'sun', N_("Sun - Mouse") ]
   ] ]
) :
(
 'PS/2' => 
 [ [ 'psaux' ],
   [ [ 2, 'ps/2', 'PS/2', N_("Standard") ],
     [ 5, 'ps/2', 'MouseManPlusPS/2', N_("Logitech MouseMan+") ],
     [ 5, 'imps2', 'IMPS/2', N_("Generic PS2 Wheel Mouse") ],
     [ 5, 'ps/2', 'GlidePointPS/2', N_("GlidePoint") ],
     [ 5, 'imps2', 'auto', N_("Automatic") ],
     '',
     [ 5, 'ps/2', 'ThinkingMousePS/2', N_("Kensington Thinking Mouse") ],
     [ 5, 'netmouse', 'NetMousePS/2', N_("Genius NetMouse") ],
     [ 5, 'netmouse', 'NetScrollPS/2', N_("Genius NetScroll") ],
     [ 7, 'ps/2', 'ExplorerPS/2', N_("Microsoft Explorer") ],
   ] ],
     
 'USB' =>
 [ [ 'input/mice' ],
   [ [ 1, 'ps/2', 'ExplorerPS/2', N_("1 button") ],
     [ 2, 'ps/2', 'ExplorerPS/2', N_("Generic 2 Button Mouse") ],
     [ 3, 'ps/2', 'ExplorerPS/2', N_("Generic") ],
     [ 3, 'ps/2', 'ExplorerPS/2', N_("Generic 3 Button Mouse with Wheel emulation"), 'wheel' ],
     [ 5, 'ps/2', 'ExplorerPS/2', N_("Wheel") ],
     [ 7, 'ps/2', 'ExplorerPS/2', N_("Microsoft Explorer") ],
   ] ],

 N_("serial") =>
 [ [ map { "ttyS$_" } 0..3 ],
   [ [ 2, 'Microsoft', 'Microsoft', N_("Generic 2 Button Mouse") ],
     [ 3, 'Microsoft', 'Microsoft', N_("Generic 3 Button Mouse") ],
     [ 3, 'Microsoft', 'Microsoft', N_("Generic 3 Button Mouse with Wheel emulation"), 'wheel' ],
     [ 5, 'ms3', 'IntelliMouse', N_("Microsoft IntelliMouse") ],
     [ 3, 'MouseMan', 'MouseMan', N_("Logitech MouseMan") ],
     [ 3, 'MouseMan', 'MouseMan', N_("Logitech MouseMan with Wheel emulation"), 'wheel' ],
     [ 2, 'MouseSystems', 'MouseSystems', N_("Mouse Systems") ],     
     '',
     [ 3, 'logim', 'MouseMan', N_("Logitech CC Series") ],
     [ 3, 'logim', 'MouseMan', N_("Logitech CC Series with Wheel emulation"), 'wheel' ],
     [ 5, 'pnp', 'IntelliMouse', N_("Logitech MouseMan+/FirstMouse+") ],
     [ 5, 'ms3', 'IntelliMouse', N_("Genius NetMouse") ],
     [ 2, 'MMSeries', 'MMSeries', N_("MM Series") ],
     [ 2, 'MMHitTab', 'MMHittab', N_("MM HitTablet") ],
     [ 3, 'Logitech', 'Logitech', N_("Logitech Mouse (serial, old C7 type)") ],
     [ 3, 'Logitech', 'Logitech', N_("Logitech Mouse (serial, old C7 type) with Wheel emulation"), 'wheel' ],
     [ 3, 'Microsoft', 'ThinkingMouse', N_("Kensington Thinking Mouse") ],
     [ 3, 'Microsoft', 'ThinkingMouse', N_("Kensington Thinking Mouse with Wheel emulation"), 'wheel' ],
   ] ],

 N_("busmouse") =>
 [ [ arch() eq 'ppc' ? 'adbmouse' : ('atibm', 'inportbm', 'logibm') ],
   [ if_(arch() eq 'ppc', [ 1, 'Busmouse', 'BusMouse', N_("1 button") ]),
     [ 2, 'Busmouse', 'BusMouse', N_("2 buttons") ],
     [ 3, 'Busmouse', 'BusMouse', N_("3 buttons") ],
     [ 3, 'Busmouse', 'BusMouse', N_("3 buttons with Wheel emulation"), 'wheel' ],
   ] ],

 N_("Universal") =>
 [ [ 'input/mice' ],
   [ [ 7, 'ps/2', 'ExplorerPS/2', N_("Any PS/2 & USB mice") ],
     [ 7, 'ps/2', 'ExplorerPS/2', N_("Force evdev") ], #- evdev is magically handled in mouse::select()
     if_(detect_devices::is_xbox(), [ 5, 'ps/2', 'IMPS/2', N_("Microsoft Xbox Controller S") ]),
     if_(detect_devices::is_virtualbox(), [ 7, 'ps/2', 'vboxmouse', N_("VirtualBox mouse") ]),
     if_(detect_devices::is_vmware(), [ 7, 'ps/2', 'vmmouse', N_("VMware mouse") ]),
   ] ],

 N_("none") =>
 [ [ 'none' ],
   [ [ 0, 'none', 'Microsoft', N_("No mouse") ],
   ] ],
);
}

#- Logitech MX700
#-
#- I: Bus=0003 Vendor=046d Product=c506 Version=1600
#- N: Name="Logitech USB Receiver"
#- P: Phys=usb-0000:00:11.3-2/input0
#- S: Sysfs=/class/input/input5
#- H: Handlers=mouse2 ts2 event3 
#- B: EV=7
#- B: KEY=ffff0000 0 0 0 0 0 0 0 0
#- B: REL=103
#- 
#- T:  Bus=05 Lev=01 Prnt=01 Port=01 Cnt=02 Dev#=  4 Spd=1.5 MxCh= 0
#- D:  Ver= 1.10 Cls=00(>ifc ) Sub=00 Prot=00 MxPS= 8 #Cfgs=  1
#- P:  Vendor=046d ProdID=c506 Rev=16.00
#- S:  Manufacturer=Logitech
#- S:  Product=USB Receiver
#- C:* #Ifs= 1 Cfg#= 1 Atr=a0 MxPwr= 50mA
#- I:  If#= 0 Alt= 0 #EPs= 1 Cls=03(HID  ) Sub=01 Prot=02 Driver=usbhid
#- E:  Ad=81(I) Atr=03(Int.) MxPS=   8 Ivl=10ms


my %mouse_btn_keymap = (
    0   => "NONE",
    67  => "F9",
    68  => "F10",
    87  => "F11",
    88  => "F12",
    85  => "F13",
    89  => "F14",
    90  => "F15",
    56  => "L-Option/Alt",
    125 => "L-Command (Apple)",
    98  => "Num: /",
    55  => "Num: *",
    117 => "Num: =",
    96 => "Enter",
);
sub _ppc_one_button_keys() { keys %mouse_btn_keymap }
sub _ppc_one_button_key2text { $mouse_btn_keymap{$_[0]} }

my @mouses_fields = qw(nbuttons MOUSETYPE Protocol name EmulateWheel);

sub _raw2mouse {
    my ($type, $raw) = @_;
    $raw or return;

    my %l; @l{@mouses_fields} = @$raw;
    +{ %l, type => $type, if_($l{nbuttons} < 3, Emulate3Buttons => 1) };
}

sub fullname2mouse {
    my ($fname, %opts) = @_;
    my ($type, @l) = split '\|', $fname;
    my $name = pop @l; #- ensure we get rid of "[Other]"
    my %mice = _all_mice();

    if (my @devices = @{$mice{$type}[0]}) {
	member($opts{device}, @devices) or delete $opts{device};
	$opts{device} ||= $devices[0];
    }
    foreach (@{$mice{$type}[1]}) {
	my $l = _raw2mouse($type, $_);
	$name eq $l->{name} and return { %$l, %opts };
    }
    die "$fname not found ($type, $name)";
}

sub read() {
    my %mouse = getVarsFromSh "$::prefix/etc/sysconfig/mouse";
    eval { fullname2mouse($mouse{FULLNAME}, device => $mouse{device}) } || \%mouse;
}

sub write {
    my ($do_pkgs, $mouse) = @_;

    setVarsInSh("$::prefix/etc/sysconfig/mouse", {
	device => $mouse->{device},
	MOUSETYPE => $mouse->{MOUSETYPE},
	FULLNAME => qq($mouse->{type}|$mouse->{name}),
    });

    various_xfree_conf($do_pkgs, $mouse);

    if (arch() =~ /ppc/) {
	my $s = join('',
	  "dev.mac_hid.mouse_button_emulation = " . to_bool($mouse->{button2_key} || $mouse->{button3_key}) . "\n",
	  if_($mouse->{button2_key}, "dev.mac_hid.mouse_button2_keycode = $mouse->{button2_key}\n"),
	  if_($mouse->{button3_key}, "dev.mac_hid.mouse_button3_keycode = $mouse->{button3_key}\n"),
	);
	substInFile { 
	    $_ = '' if /^\Qdev.mac_hid.mouse_button/;
	    $_ .= $s if eof;
	} "$::prefix/etc/sysctl.conf";
    }
}

sub _input_entry_to_device_by_id {
    my ($input) = @_;

    my $ID_SERIAL = chomp_(run_program::get_stdout('usb_id', $input->{sysfs_path}));
    $ID_SERIAL =~ s/[^\w#+\-.:=@_]/_/g; #- udev do a further cleanup, eg: "Wacom_Co.,Ltd._MTE-450" => "Wacom_Co._Ltd._MTE-450". cf ALLOWED_CHARS udev.h
    my $sysfs_device = "input/by-id/usb-$ID_SERIAL-event-mouse"; #- from /etc/udev/rules.d/60-persistent-input.rules
    if ($::isInstall || -e "/dev/$sysfs_device") {
	$sysfs_device;
    } else {
	log::l("$sysfs_device missing");
	();
    }
}

sub _probe_usb_wacom_devices() {
    detect_devices::hasWacom() or return;

    eval { modules::load("wacom", "evdev") };
     
    map { _input_entry_to_device_by_id($_) } detect_devices::usbWacom();
}

sub _detect_serial() {
    my ($t, $mouse, @wacom);

    #- Whouah! probing all devices from ttyS0 to ttyS3 once a time!
    detect_devices::probeSerialDevices();

    #- check new probing methods keep everything used here intact!
    foreach (0..3) {
	$t = detect_devices::probeSerial("/dev/ttyS$_") or next;
	if ($t->{CLASS} eq 'MOUSE') {
	    $t->{MFG} ||= $t->{MANUFACTURER};

	    my $name = 'Generic 2 Button Mouse';
	    $name = 'Microsoft IntelliMouse' if $t->{MFG} eq 'MSH' && $t->{MODEL} eq '0001';
	    $name = 'Logitech MouseMan' if $t->{MFG} eq 'LGI' && $t->{MODEL} =~ /^80/;
	    $name = 'Genius NetMouse' if $t->{MFG} eq 'KYE' && $t->{MODEL} eq '0003';

	    $mouse ||= fullname2mouse("serial|$name", device => "ttyS$_");
	    last;
	} elsif ($t->{CLASS} eq "PEN" || $t->{MANUFACTURER} eq "WAC") {
	    push @wacom, "ttyS$_";
	}
    }
    $mouse, @wacom;
}

sub _mice2evdev {
    my (@mice) = @_;

    [ map {
	#- we always use HWheelRelativeAxisButtons for evdev, it tells mice with no horizontal wheel to skip those buttons
	#- that way we ensure 6 & 7 is always horizontal wheel
	#- (cf patch skip-HWheelRelativeAxisButtons-even-if-unused in x11-driver-input-evdev)
	{ device => "/dev/$_", HWheelRelativeAxisButtons => "7 6" };
    } map { _input_entry_to_device_by_id($_) } @mice ];
}

sub _detect_evdev_mice {
    my (@mice) = @_;

    my $imwheel;
    foreach (@mice) {
	my @l = $_->{usb} && $_->{usb}{driver} =~ /^Mouse:(.*)/ ? split('\|', $1) : ();
	foreach my $opt (@l) {
	    if ($opt eq 'evdev') {
		$_->{want_evdev} = 1;
	    } elsif ($opt =~ /imwheel:(.*)/) {
		$imwheel = $1;
	    }
	}
	if ($_->{HWHEEL}) {
	    $_->{want_evdev} = 1;
	}
	if ($_->{SIDE}) {
	    $imwheel ||= 'generic';
	}
    }

    my @evdev_mice = grep { $_->{want_evdev} } @mice;

    log::l("configuring mice with imwheel for thumb buttons (imwheel=$imwheel)") if $imwheel;
    log::l("configuring mice for evdev (" . join(' ', map { "$_->{vendor}:$_->{product}" } @evdev_mice) . ")") if @evdev_mice;

    { imwheel => $imwheel, 
      evdev_mice_all => _mice2evdev(@mice),
      if_(@evdev_mice, evdev_mice => _mice2evdev(@evdev_mice)) };
}

sub detect {
    my ($modules_conf) = @_;

    # let more USB tablets and touchscreens magically work at install time
    # through /dev/input/mice multiplexing:
    detect_devices::probe_category('input/tablet');
    detect_devices::probe_category('input/touchscreen');

    my @wacom = _probe_usb_wacom_devices();

    $modules_conf->get_probeall("usb-interface") and eval { modules::load('usbhid') };
    if (detect_devices::is_virtualbox()) {
	fullname2mouse("Universal|VirtualBox mouse");
    } elsif (detect_devices::is_vmware()) {
	fullname2mouse("Universal|VMware mouse");
    } elsif (my @mice = grep { $_->{Handlers}{mouse} } detect_devices::getInputDevices_and_usb()) {
	my @synaptics = map {
	    { ALPS => $_->{ALPS} };
	} grep { $_->{Synaptics} || $_->{ALPS} } @mice;

	my $evdev_opts = _detect_evdev_mice(@mice);

	my $fullname = detect_devices::is_xbox() ? 
	  'Universal|Microsoft Xbox Controller S' :
	    arch() eq "ppc" ? 
	  'USB|1 button' :
	  'Universal|Any PS/2 & USB mice';

	fullname2mouse($fullname, wacom => \@wacom, 
		       synaptics => $synaptics[0], 
		       if_($evdev_opts, %$evdev_opts));
    } elsif (arch() eq 'ppc') {
	# No need to search for an ADB mouse.  If I did, the PPC kernel would
	# find one whether or not I had one installed!  So..  default to it.
	fullname2mouse("busmouse|1 button");
    } elsif (arch() =~ /^sparc/) {
	fullname2mouse("sunmouse|Sun - Mouse");
    } else {
	#- probe serial device to make sure a wacom has been detected.
	eval { modules::load("serial") };
	my ($serial_mouse, @serial_wacom) = _detect_serial(); 
	push @wacom, @serial_wacom;
	if ($serial_mouse) {
	    { wacom => \@wacom, %$serial_mouse };
	} elsif (@wacom) {
	    #- in case only a wacom has been found, assume an inexistant mouse (necessary).
	    fullname2mouse('none|No mouse', wacom => \@wacom);
	} else {
	    fullname2mouse('Universal|Any PS/2 & USB mice', unsafe => 1);
	}
    }
}

sub load_modules {
    my ($mouse) = @_;
    my @l;
    push @l, qw(hid mousedev usbmouse) if $mouse->{type} =~ /USB/;
    push @l, qw(serial) if $mouse->{type} =~ /serial/ || any { /ttyS/ } @{$mouse->{wacom}};
    push @l, qw(wacom evdev) if any { /event/ } @{$mouse->{wacom}};
    push @l, qw(evdev) if $mouse->{synaptics} || $mouse->{evdev_mice};

    eval { modules::load(@l) };
}

sub set_xfree_conf {
    my ($mouse, $xfree_conf, $b_keep_auxmouse_unchanged) = @_;

    my @mice = map {
	{
	    (member($_->{Protocol}, qw(vboxmouse vmmouse)) ? "Driver" : "Protocol") => $_->{Protocol},
	    Device => devices::make($_->{device}),
	    if_($_->{Emulate3Buttons} || $_->{EmulateWheel}, Emulate3Buttons => undef, Emulate3Timeout => 50),
	    if_($_->{EmulateWheel}, EmulateWheel => undef, EmulateWheelButton => 2),
	};
    } $mouse;

    if ($mouse->{evdev_mice}) {
	push @mice, @{$mouse->{evdev_mice}};
    } elsif (!$mouse->{synaptics} && $b_keep_auxmouse_unchanged) {
	my (undef, @l) = $xfree_conf->get_mice;
	push @mice, @l;
    }

    $xfree_conf->set_mice(@mice);

    if (my @wacoms = @{$mouse->{wacom} || []}) {
	$xfree_conf->set_wacoms(map { { Device => "/dev/$_", USB => to_bool(m|input/by-path/event|) } } @wacoms);
    }
}

sub various_xfree_conf {
    my ($do_pkgs, $mouse) = @_;

    -e "/usr/bin/X" or return;

    #- we don't need this anymore. Remove it for upgrades
    unlink("$::prefix/etc/X11/xinit.d/mouse_buttons");
    {
	my $f = "$::prefix/etc/X11/xinit.d/xpad";
	if ($mouse->{name} !~ /^Microsoft Xbox Controller/) {
	    unlink($f);
	} else {
	    output_with_perm($f, 0755, "xset m 1/8 1\n");
	}
    }

    require Xconfig::card;
    my $inputdrvpath = Xconfig::card::modules_dir() . '/input';
    my $pkgs = [
	if_($mouse->{synaptics}, ['x11-driver-input-synaptics', "$inputdrvpath/synaptics_drv.so"]),
	if_($mouse->{evdev_mice}, ['x11-driver-input-evdev', "$inputdrvpath/evdev_drv.so"]),
	if_($mouse->{Protocol} eq 'vboxmouse', ['x11-driver-input-vboxmouse', "$inputdrvpath/vboxmouse_drv.so"]),
	if_($mouse->{imwheel}, ['imwheel', "/usr/bin/imwheel"]),
	if_(@{$mouse->{wacom}}, ['linuxwacom', "$inputdrvpath/wacom_drv.so"]),
	if_($mouse->{name} =~ /VMware/i, ['x11-driver-input-vmmouse', "$inputdrvpath/vmmouse_drv.so"]),
    ];
    $do_pkgs->ensure_files_are_installed($pkgs, 1);

    if ($mouse->{imwheel}) {
	my $rc = "/etc/X11/imwheel/imwheelrc.$mouse->{imwheel}";
	eval { setVarsInSh("$::prefix/etc/X11/imwheel/startup.conf", { 
	    IMWHEEL_START => 1, 
	    IMWHEEL_PARAMS => join(' ', '-k', if_(-e "$::prefix$rc", '--rc', $rc)),
	}) };
    }
}

#- write_conf : write the mouse infos into the Xconfig files.
#- input :
#-  $mouse : the hashtable containing the informations
#- $mouse input
#-  $mouse->{nbuttons} : number of buttons : integer
#-  $mouse->{device} : device of the mouse : string : ex 'psaux'
#-  $mouse->{Protocol} : type of the mouse for X : string (eg 'PS/2')
#-  $mouse->{type} : type (generic ?) of the mouse : string : ex 'PS/2'
#-  $mouse->{name} : name of the mouse : string : ex 'Standard'
#-  $mouse->{MOUSETYPE} : type of the mouse : string : ex "ps/2"
sub write_conf {
    my ($do_pkgs, $modules_conf, $mouse, $b_keep_auxmouse_unchanged) = @_;

    &write($do_pkgs, $mouse);
    $modules_conf->write if $mouse->{device} eq "input/mice" && !$::testing;

    eval {
	require Xconfig::xfree;
	my $xfree_conf = Xconfig::xfree->read;
	set_xfree_conf($mouse, $xfree_conf, $b_keep_auxmouse_unchanged);
	$xfree_conf->write;
    };
}

sub _xmouse2xId { 
    #- xmousetypes must be sorted as found in /usr/include/X11/extensions/xf86misc.h
    #- so that first mean "0", etc
    my @xmousetypes = (
		   "Microsoft",
		   "MouseSystems",
		   "MMSeries",
		   "Logitech",
		   "BusMouse", #MouseMan,
		   "Logitech",
		   "PS/2",
		   "MMHittab",
		   "GlidePoint",
		   "IntelliMouse",
		   "ThinkingMouse",
		   "IMPS/2",
		   "ThinkingMousePS/2",
		   "MouseManPlusPS/2",
		   "GlidePointPS/2",
		   "NetMousePS/2",
		   "NetScrollPS/2",
		   "SysMouse",
		   "Auto",
		   "AceCad",
		   "ExplorerPS/2",
		   "USB",
    );
    my ($id) = @_;
    $id = 'BusMouse' if $id eq 'MouseMan';
    $id = 'IMPS/2' if $id eq 'ExplorerPS/2' && $::isInstall;
    eval { find_index { $_ eq $id } @xmousetypes } || 0;
}

sub change_mouse_live {
    my ($mouse, $old) = @_;

    my $xId = _xmouse2xId($mouse->{Protocol});
    $old->{device} ne $mouse->{device} || $xId != _xmouse2xId($old->{Protocol}) or return;

    log::l("telling X server to use another mouse ($mouse->{Protocol}, $xId)");
    eval { modules::load('serial') } if $mouse->{device} =~ /ttyS/;

    if (!$::testing) {
	devices::make($mouse->{device});
	symlinkf($mouse->{device}, "/dev/mouse");
	eval {
	    require xf86misc::main;
	    xf86misc::main::setMouseLive($ENV{DISPLAY}, $xId, $mouse->{Emulate3Buttons});
	};
    }
    1;
}

sub test_mouse_install {
    my ($mouse, $x_protocol_changed) = @_;
    require ugtk2;
    ugtk2->import(qw(:wrappers :create));
    my $w = ugtk2->new(N("Testing the mouse"), disallow_big_help => 1);
    my $darea = Gtk2::DrawingArea->new;
    $darea->set_events([ 'button_press_mask', 'button_release_mask' ]);  #$darea must be unrealized.
    gtkadd($w->{window},
  	   gtkpack(my $vbox_grab = Gtk2::VBox->new(0, 0),
		   $darea,
		   gtkset_sensitive(create_okcancel($w, undef, '', 'edge'), 1)
		  ),
	  );
    test_mouse($mouse, $darea, $x_protocol_changed);
    $w->sync; # HACK
    Gtk2::Gdk->pointer_grab($vbox_grab->window, 1, 'pointer_motion_mask', $vbox_grab->window, undef, 0);
    my $r = $w->main;
    Gtk2::Gdk->pointer_ungrab(0);
    $r;
}

sub _fullnames() { 
    map_each { 
	my $type = $::a;
	grep { $_ } map {
	    if ($_) {
		my $l = _raw2mouse($type, $_);
		"$type|$l->{name}";
	    } else { 
		$type .= "|[" . N("Other") . "]";
		'';
	    }
	} @{$::b->[1]};
    } _all_mice();
}

sub select {
    my ($in, $mouse) = @_;

    my $prev = my $fullname = $mouse->{type} . '|' . $mouse->{name};

    $in->ask_from_({ messages => N("Please choose your type of mouse."),
		     title => N("Mouse choice"),
		     interactive_help_id => 'selectMouse',
		     if_($mouse->{unsafe}, cancel => ''),
		 },
		   [ { list => [ _fullnames() ], separator => '|', val => \$fullname, 
		       format => sub { join('|', map { translate($_) } split('\|', $_[0])) } } ]) or return;

    if ($fullname ne $prev) {
	my $mouse_ = fullname2mouse($fullname, device => $mouse->{device});
	if ($fullname =~ /evdev/) {
	    $mouse_->{evdev_mice} = $mouse_->{evdev_mice_all} = $mouse->{evdev_mice_all};
	}
	%$mouse = %$mouse_;
    }

    if ($mouse->{nbuttons} < 3 && $::isStandalone) {
	$mouse->{Emulate3Buttons} = $in->ask_yesorno('', N("Emulate third button?"), 1);
    }

    if ($mouse->{type} eq 'serial') {
	$in->ask_from_({ title => N("Mouse Port"),
			 messages => N("Please choose which serial port your mouse is connected to."),
			 interactive_help_id => 'selectSerialPort',
		     }, [ { list => [ detect_devices::serialPorts() ], format => \&detect_devices::serialPort2text, val => \$mouse->{device} } ]) or return &select;
    }

    if (arch() =~ /ppc/ && $mouse->{nbuttons} == 1) {
	#- set a sane default F11/F12
	$mouse->{button2_key} = 87;
	$mouse->{button3_key} = 88;
	$in->ask_from('', N("Buttons emulation"),
		[
		{ label => N("Button 2 Emulation"), val => \$mouse->{button2_key}, list => [ _ppc_one_button_keys() ], format => \&_ppc_one_button_key2text },
		{ label => N("Button 3 Emulation"), val => \$mouse->{button3_key}, list => [ _ppc_one_button_keys() ], format => \&_ppc_one_button_key2text },
		]) or return;
    }
    1;
}

sub test_mouse {
    my ($mouse, $darea, $b_x_protocol_changed) = @_;

    require ugtk2;
    ugtk2->import(qw(:wrappers));
    my $suffix = $mouse->{nbuttons} <= 2 ? '2b' : $mouse->{nbuttons} == 3 ? '3b' : '3b+';
    my %offsets = (mouse_2b_right => [ 93, 0 ], mouse_3b_right => [ 117, 0 ],
		   mouse_2b_middle => [ 82, 80 ], mouse_3b_middle => [ 68, 0 ], 'mouse_3b+_middle' => [ 85, 67 ]);
    my %image_files = (
		       mouse => "mouse_$suffix",
		       left => 'mouse_' . ($suffix eq '3b+' ? '3b' : $suffix) . '_left',
		       right => 'mouse_' . ($suffix eq '3b+' ? '3b' : $suffix) . '_right',
		       if_($mouse->{nbuttons} > 2, middle => 'mouse_' . $suffix . '_middle'),
		       up => 'arrow_up',
		       down => 'arrow_down');
    my %images = map { $_ => ugtk2::gtkcreate_pixbuf("$image_files{$_}.png") } keys %image_files;
    my $width = $images{mouse}->get_width;
    my $height = round_up($images{mouse}->get_height, 6);

    my $draw_text = sub {
  	my ($t, $y) = @_;
	my $layout = $darea->create_pango_layout($t);
	my ($w) = $layout->get_pixel_size;
	$darea->window->draw_layout($darea->style->black_gc,
				    ($darea->allocation->width-$w)/2,
				    ($darea->allocation->height-$height)/2 + $y,
				    $layout);
    };
    my $draw_pixbuf = sub {
	my ($p, $x, $y, $w, $h) = @_;
	$w = $p->get_width;
	$h = $p->get_height;
	$p->render_to_drawable($darea->window, $darea->style->bg_gc('normal'), 0, 0,
			       ($darea->allocation->width-$width)/2 + $x, ($darea->allocation->height-$height)/2 + $y,
			       $w, $h, 'none', 0, 0);
    };
    my $draw_by_name = sub {
	my ($name) = @_;
	my $file = $image_files{$name};
	my ($x, $y) = @{$offsets{$file} || [ 0, 0 ]};
	$draw_pixbuf->($images{$name}, $x, $y);
    };
    my $drawarea = sub {
	$draw_by_name->('mouse');
	if ($::isInstall || 1) {
	    $draw_text->(N("Please test the mouse"), 200);
	    if ($b_x_protocol_changed && $mouse->{nbuttons} > 3 && $mouse->{device} eq 'psaux' && member($mouse->{Protocol}, 'IMPS/2', 'ExplorerPS/2')) {
		$draw_text->(N("To activate the mouse,"), 240);
		$draw_text->(N("MOVE YOUR WHEEL!"), 260);
	    }
	}
    };

    my $timeout;
    my $paintButton = sub {
	my ($nb) = @_;
	$timeout or $drawarea->();
	if ($nb == 0) {
	    $draw_by_name->('left');
	} elsif ($nb == 2) {
	    $draw_by_name->('right');
	} elsif ($nb == 1) {
	    if ($mouse->{nbuttons} >= 3) {
		$draw_by_name->('middle');
	    } else {
		my ($x, $y) = @{$offsets{mouse_2b_middle}};
  		$darea->window->draw_arc($darea->style->black_gc,
  					  1, ($darea->allocation->width-$width)/2 + $x, ($darea->allocation->height-$height)/2 + $y, 20, 25,
  					  0, 360 * 64);
	    }
	} elsif ($mouse->{nbuttons} > 3) {
	    my ($x, $y) = @{$offsets{$image_files{middle}}};
	    if ($nb == 3) {
		$draw_pixbuf->($images{up}, $x+6, $y-10);
	    } elsif ($nb == 4) {
		$draw_pixbuf->($images{down}, $x+6, $y + $images{middle}->get_height + 2);
	    }
	    $draw_by_name->('middle');
	    $timeout and Glib::Source->remove($timeout);
	    $timeout = Glib::Timeout->add(100, sub { $drawarea->(); $timeout = 0; 0 });
	}
    };
    
    $darea->signal_connect(button_press_event => sub { $paintButton->($_[1]->button - 1) });
    $darea->signal_connect(scroll_event => sub { $paintButton->($_[1]->direction eq 'up' ? 3 : 4) });
    $darea->signal_connect(button_release_event => $drawarea);
    $darea->signal_connect(expose_event => $drawarea);
    $darea->set_size_request($width, $height);
}


=begin

=head1 NAME

mouse - Perl functions to handle mice

=head1 SYNOPSYS

   require modules;
   require mouse;
   mouse::detect(modules::any_conf->read);

=head1 DESCRIPTION

C<mouse> is a perl module used by mousedrake to detect and configure the mouse.

=head1 COPYRIGHT

Copyright (C) 2000-2006 Mandriva <tvignaud@mandriva.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=cut
