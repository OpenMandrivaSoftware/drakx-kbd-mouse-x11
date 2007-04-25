package Xconfig::card; # $Id$

use diagnostics;
use strict;

use lib '/usr/lib/libDrakX';
use detect_devices;
use Xconfig::xfree;
use modules;
use common;
use interactive;
use log;

my $lib = arch() =~ /x86_64/ ? "lib64" : "lib";

sub modules_dir() { "/usr/$lib/xorg/modules" }

my %VideoRams = (
     256 => N_("256 kB"),
     512 => N_("512 kB"),
    1024 => N_("1 MB"),
    2048 => N_("2 MB"),
    4096 => N_("4 MB"),
    8192 => N_("8 MB"),
   16384 => N_("16 MB"),
   32768 => N_("32 MB"),
   65536 => N_("64 MB or more"),
);

my @xfree4_Drivers = ((arch() =~ /^sparc/ ? qw(sunbw2 suncg14 suncg3 suncg6 sunffb sunleo suntcx) :
		    qw(amd apm ark ast chips cirrus cyrix glide i128 i740 i810 imstt
                       mga nsc neomagic newport nv rendition openchrome vesa via
                       s3 s3virge savage siliconmotion sis sisusb tdfx tga trident tseng vmware)), 
		    qw(ati glint vga fbdev));

sub from_raw_X {
    my ($raw_X) = @_;

    my $device = $raw_X->get_device or die "no card configured";

    my $card = {
	use_DRI_GLX  => eval { any { /dri/ } $raw_X->get_modules },
	DRI_GLX_SPECIAL => first($raw_X->get_ModulePaths),
	%$device,
	if_($device->{Driver} eq 'nvidia',
	    DriverVersion => 
	      readlink("$::prefix/etc/alternatives/gl_conf") =~ m!nvidia(.*)/! ? $1 : '97xx'),
    };
    add_to_card__using_Cards($card, $card->{BoardName});
    $card;
}

sub to_raw_X {
    my ($card, $raw_X) = @_;

    my @cards = ($card, @{$card->{cards} || []});

    foreach (@cards) {
	#- Specific ATI fglrx driver default options
	if ($_->{Driver} eq 'fglrx') {
	    # $default_ATI_fglrx_config need to be move in proprietary ?
	    $_->{raw_LINES} ||= default_ATI_fglrx_config();
	}
	if (arch() =~ /ppc/ && ($_->{Driver} eq 'r128' || $_->{Driver} eq 'radeon')) {
	    $_->{UseFBDev} = 1;
	}
	if ($_->{Driver} eq 'i810') {
	    $_->{Options}{May_Need_ForceBIOS} = '1';
	}
        if (member($_->{Driver}, qw(i810 ati))) {
	    $_->{Options}{XaaNoOffscreenPixmaps} = '1';
        }
    }

    $raw_X->set_devices(@cards);

    $raw_X->get_ServerLayout->{Xinerama} = { commented => !$card->{Xinerama}, Option => 1 }
      if defined $card->{Xinerama};

    # cleanup deprecated previous special nvidia explicit libglx
    $raw_X->remove_load_module(modules_dir() . "$_/libglx.so") foreach '/extensions/nvidia', '/extensions/nvidia_legacy', '/extensions';

    # remove ModulePath that we added
    $raw_X->remove_ModulePath(modules_dir() . "/extensions/$_") foreach 'nvidia97xx', 'nvidia96xx', 'nvidia71xx';
    $raw_X->remove_ModulePath(modules_dir());
    # then may re-add some
    if ($card->{DRI_GLX_SPECIAL}) {
	$raw_X->add_ModulePath($card->{DRI_GLX_SPECIAL});
    }
    #- if we have some special ModulePath, ensure the last one is the standard ModulePath
    $raw_X->add_ModulePath(modules_dir()) if $raw_X->get_ModulePaths;

    $raw_X->set_load_module('glx', $card->{Driver} ne 'fbdev'); #- glx for everyone, except fbdev
    $raw_X->set_load_module('dri', $card->{use_DRI_GLX}); #- dri when needed, except proprietary nvidia

    $raw_X->remove_Section('DRI');

    $raw_X->remove_load_module('v4l') if $card->{use_DRI_GLX} && $card->{Driver} eq 'r128';
}

sub default_ATI_fglrx_config() { our $default_ATI_fglrx_config }

sub probe() {
#-for Pixel tests
#-    my @c = { driver => 'Card:Matrox Millennium G400 DualHead', description => 'Matrox|Millennium G400 Dual HeadCard' };
    my @c = detect_devices::matching_driver__regexp('^(Card|Server|Driver):');

    my @cards = map {
	my @l = $_->{description} =~ /(.*?)\|(.*)/;
	my $card = { 
	    description => $_->{description},
	    VendorName => $l[0], BoardName => $l[1],
	    BusID => "PCI:$_->{pci_bus}:$_->{pci_device}:$_->{pci_function}",
	};
	if (my ($card_name) = $_->{driver} =~ /Card:(.*)/) { 
	    $card->{BoardName} = $card_name; 
	    add_to_card__using_Cards($card, $card_name);
	} elsif ($_->{driver} =~ /Driver:(.*)/) { 
	    $card->{Driver} = $1;
	} else { 
	    internal_error();
	}
	$card;
    } @c;

    if (@cards >= 2 && $cards[0]{card_name} eq $cards[1]{card_name} && $cards[0]{card_name} eq 'Intel 830 - 965') {
	shift @cards;
    }
    #- take a default on sparc if nothing has been found.
    if (arch() =~ /^sparc/ && !@cards) {
        log::l("Using probe with /proc/fb as nothing has been found!");
	my $s = cat_("/proc/fb");
	@cards = { server => $s =~ /Mach64/ ? "Mach64" : $s =~ /Permedia2/ ? "3DLabs" : "Sun24" };
    }

    #- disabling MULTI_HEAD when not available
    foreach (@cards) { 
	$_->{MULTI_HEAD} && $_->{card_name} =~ /G[24]00/ or next;
	if ($ENV{MATROX_HAL}) {
	    $_->{need_MATROX_HAL} = 1;
	} else {
	    delete $_->{MULTI_HEAD};
	}
    }

    #- in case of only one cards, remove all BusID reference, this will avoid
    #- need of change of it if the card is moved.
    #- on many PPC machines, card is on-board, BusID is important, leave?
    if (@cards == 1 && !$cards[0]{MULTI_HEAD} && arch() !~ /ppc/) {
	delete $cards[0]{BusID};
    }

    @cards;
}

sub card_config__not_listed {
    my ($in, $card, $options) = @_;

    my $vendors_regexp = join '|', map { quotemeta } (
        '3Dlabs',
        'AOpen', 'ASUS', 'ATI', 'Ark Logic', 'Avance Logic',
        'Cardex', 'Chaintech', 'Chips & Technologies', 'Cirrus Logic', 'Compaq', 'Creative Labs',
        'Dell', 'Diamond', 'Digital',
        'ET', 'Elsa',
        'Genoa', 'Guillemot', 'Hercules', 'Intel', 'Leadtek',
        'Matrox', 'Miro', 'NVIDIA', 'NeoMagic', 'Number Nine',
        'Oak', 'Orchid',
        'RIVA', 'Rendition Verite',
        'S3', 'Silicon Motion', 'STB', 'SiS', 'Sun',
        'Toshiba', 'Trident',
        'VideoLogic',
    );
    my $cards = readCardsDB("$ENV{SHARE_PATH}/ldetect-lst/Cards+");

    my @xf4 = grep { $options->{allowFB} || $::isStandalone || $_ ne 'fbdev' } @xfree4_Drivers;
    my @list = (
	(map { 'Vendor|' . $_ } keys %$cards),
	(map { 'Xorg|' . $_ } @xf4),
    );

    my $r = exists $cards->{$card->{BoardName}} ? "Vendor|$card->{BoardName}" : 'Xorg|vesa';
    $in->ask_from_({ title => N("X server"), 
		     messages => N("Choose an X server"),
		     interactive_help_id => 'configureX_card_list',
		   },
		   [ { val => \$r, separator => '|', list => \@list, sort => 1,
		       format => sub { $_[0] =~ /^Vendor\|($vendors_regexp)\s*-?(.*)/ ? "Vendor|$1|$2" : 
				       $_[0] =~ /^Vendor\|(.*)/ ? "Vendor|Other|$1" : $_[0] } } ]) or return;

    log::explanations("Xconfig::card: $r manually chosen");

    $r eq "Vendor|$card->{BoardName}" and return 1; #- it is unchanged, do not modify $card

    my ($kind, $s) = $r =~ /(.*?)\|(.*)/;

    %$card = ();
    if ($kind eq 'Vendor') {
	add_to_card__using_Cards($card, $s);
    } else {
	$card->{Driver} = $s;
	$card->{DRI_GLX} = 0;
    }
    $card->{manually_chosen} = 1;
    1;
}

sub multi_head_choose {
    my ($in, $_auto, @cards) = @_;

    my @choices = multi_head_choices('', @cards);

    my $tc = $choices[0];
    if (@choices > 1) {
	$tc = $in->ask_from_listf(N("Multi-head configuration"),
				  N("Your system supports multiple head configuration.
What do you want to do?"), sub { $_[0]{text} }, \@choices) or return;
    }
    $tc->{code} or die internal_error();
    return $tc->{code}();
}

sub configure_auto_install {
    my ($raw_X, $do_pkgs, $old_X, $options) = @_;

    my $card = $old_X->{card} || {};

    if ($card->{card_name}) {
	#- try to get info from given card_name
	add_to_card__using_Cards($card, $card->{card_name});
	if (!$card->{Driver}) {
	    log::l("bad card_name $card->{card_name}, using probe");
	    undef $card->{card_name};
	}
    }

    if (!$card->{Driver}) {
	my @cards = probe();
	my ($choice) = multi_head_choices($old_X->{Xinerama}, @cards);
	$card = $choice ? $choice->{code}() : do {
	    log::explanations('no graphic card probed, try providing one using $o->{card}{Driver} or $o->{card}{card_name}. Defaulting...');
	    { Driver => $options->{allowFB} ? 'fbdev' : 'vesa' };
	};
    }

    install_server($card, $options, $do_pkgs) or return;
    $card = choose_Driver2_or_not($card, undef);

    Xconfig::various::various_auto_install($raw_X, $card, $old_X);
    set_glx_restrictions($card);

    if ($card->{needVideoRam} && !$card->{VideoRam}) {
	$card->{VideoRam} = $options->{VideoRam_probed} || 4096;
	log::explanations("argh, I need to know VideoRam! Taking " . ($options->{probed_VideoRam} ? "the probed" : "a default") . " value: VideoRam = $card->{VideoRam}");
    }
    to_raw_X($card, $raw_X);
    $card;
}

sub configure {
    my ($in, $raw_X, $do_pkgs, $auto, $options) = @_;

    my @cards = probe();
    @cards or @cards = {};

    if (!$cards[0]{Driver}) {
	if ($options->{allowFB}) {
	    $cards[0]{Driver} = 'fbdev';
	}
    }
    if (!$auto || !$cards[0]{Driver}) {
      card_config__not_listed:
	card_config__not_listed($in, $cards[0], $options) or return;
    }

    my $card = multi_head_choose($in, $auto, @cards) or return;

    install_server($card, $options, $do_pkgs) or goto card_config__not_listed;

    $card = choose_Driver2_or_not($card, $in);

    Xconfig::various::various($in, $raw_X, $card, $options, $auto);
    set_glx_restrictions($card);

    if ($card->{needVideoRam} && !$card->{VideoRam}) {
	$card->{VideoRam} = (find { $_ <= $options->{VideoRam_probed} } reverse ikeys %VideoRams) || 4096;
	$in->ask_from('', N("Select the memory size of your graphics card"),
		      [ { val => \$card->{VideoRam},
			  type => 'list',
			  list => [ ikeys %VideoRams ],
			  format => sub { translate($VideoRams{$_[0]}) },
			  not_edit => 0 } ]) or return;
    }

    to_raw_X($card, $raw_X);
    $card;
}

sub install_server {
    my ($card, $options, $do_pkgs) = @_;

    my @packages;
    my @must_have = "x11-driver-video-$card->{Driver}";

    if ($options->{freedriver}) {
	delete $card->{Driver2};
    }

    if ($card->{Driver2}) {       
	require Xconfig::proprietary;
	push @packages, Xconfig::proprietary::pkgs_for_Driver2($card, $do_pkgs);
    }

    $do_pkgs->ensure_are_installed([ @must_have, @packages ], 1) or
      @must_have == listlength($do_pkgs->are_installed(@must_have))
	or return;

    if ($card->{need_MATROX_HAL}) {
	require Xconfig::proprietary;
	Xconfig::proprietary::install_matrox_hal($::prefix);
    }
    1;
}

sub choose_Driver2_or_not {
    my ($card, $o_in) = @_;

    my $card2;
    if ($card->{Driver2}) {
        require Xconfig::proprietary;
        $card2 = Xconfig::proprietary::may_use_Driver2($card);
    }

    if ($card2) {
	!$o_in || $o_in->ask_yesorno('', formatAlaTeX(N("There is a proprietary driver available for your video card which may support additional features.
Do you wish to use it?")), 1) and $card = $card2;
    }

    libgl_config_and_more($card);
    $card;
}

#- configures which libGL.so.1 to use, using update-alternatives
#- it also configures nvidia_drv.so (using a slave alternative, cf "update-alternatives --display gl_conf")
sub libgl_config_and_more {
    my ($card) = @_;

    if ($card->{Driver} eq 'nvidia') {
	$card->{DriverVersion} or internal_error("DriverVersion should be set for driver nvidia!");
    }

    #- ensure old deprecated conf files are not there anymore
    unlink("/etc/ld.so.conf.d/$_.conf") foreach 'nvidia', 'nvidia_legacy', 'ati';

    my $wanted = $card->{Driver} eq 'fglrx' ? "/etc/ld.so.conf.d/GL/ati.conf" :
                 $card->{Driver} eq 'nvidia' ? "/etc/nvidia$card->{DriverVersion}/ld.so.conf" :
		   '/etc/ld.so.conf.d/GL/' . (arch() =~ /64/ ? 'lib64' : 'lib') . 'mesagl1.conf';
    my $link = "$::prefix/etc/alternatives/gl_conf";
    if (readlink($link) ne $wanted) {
	-e "$::prefix$wanted" or log::l("ERROR: $wanted does not exist, linking $link to it anyway");
	common::symlinkf_update_alternatives('gl_conf', $wanted);
	if ($::isStandalone) {
	    log::explanations("ldconfig will be run because the GL library was " . ($wanted ? 'enabled' : 'disabled'));
	    system("/sbin/ldconfig");
	}
    }
    if ($card->{Driver} eq 'fglrx') {
	log::l("workaround buggy fglrx driver: make dm restart xserver (#29550)");
        eval { common::update_gnomekderc_no_create("$::prefix/etc/kde/kdm/kdmrc", 'X-:0-Core' => (
            TerminateServer => "true",
        )) };
        eval { update_gnomekderc("$::prefix/etc/X11/gdm/custom.conf", daemon => (
            AlwaysRestartServer => "true",
        )) };
    }
}

sub multi_head_choices {
    my ($want_Xinerama, @cards) = @_;
    my @choices;

    my $has_multi_head = @cards > 1 || @cards && $cards[0]{MULTI_HEAD} > 1;
    my $disable_multi_head = any { 
	$_->{Driver} or log::explanations("found card $_->{description} not supported by XF4, disabling multi-head support");
	!$_->{Driver};
    } @cards;

    if ($has_multi_head && !$disable_multi_head) {
	my $configure_multi_head = sub {

	    #- special case for multi head card using only one BusID.
	    @cards = map {
		map_index { { Screen => $::i, %$_ } } ($_) x ($_->{MULTI_HEAD} || 1);
	    } @cards;

	    my $card = shift @cards; #- assume good default.
	    $card->{cards} = \@cards;
	    $card->{Xinerama} = $_[0];
	    $card;
	};
	my $independent = { text => N("Configure all heads independently"), code => sub { $configure_multi_head->('') } };
	my $xinerama    = { text => N("Use Xinerama extension"),            code => sub { $configure_multi_head->(1) } };
	push @choices, $want_Xinerama ? ($xinerama, $independent) : ($independent, $xinerama);
    }

    foreach my $c (@cards) {
	push @choices, { text => N("Configure only card \"%s\"%s", $c->{description}, $c->{BusID} && " ($c->{BusID})"),
			 code => sub { $c } };
    }
    @choices;
}

sub set_glx_restrictions {
    my ($card) = @_;

    #- 3D acceleration configuration for XFree 4 using DRI, this is enabled by default
    #- but for some there is a need to specify VideoRam (else it will not run).
    if ($card->{use_DRI_GLX}) {
	$card->{needVideoRam} = 1 if $card->{description} =~ /Matrox.* G[245][05]0/;
	($card->{needVideoRam}, $card->{VideoRam}) = (1, 16384)
	  if $card->{card_name} eq 'Intel 810 / 815';

	#- hack for ATI Rage 128 card using a bttv or peripheral with PCI bus mastering exchange
	#- AND using DRI at the same time.
	if ($card->{card_name} eq 'ATI Rage 128 TV-out') {
	    $card->{Options}{UseCCEFor2D} = bool2text(detect_devices::probe_category('multimedia/tv'));
	}
    }
}

sub add_to_card__using_Cards {
    my ($card, $name) = @_;
    my $cards = readCardsDB("$ENV{SHARE_PATH}/ldetect-lst/Cards+");
    add2hash($card, $cards->{$name});
    $card->{BoardName} = $card->{card_name};

    $card;
}

#- needed for bad cards not restoring cleanly framebuffer, according to which version of Xorg are used.
sub check_bad_card {
    my ($card) = @_;
    my $bad_card = $card->{BAD_FB_RESTORE};
    $bad_card ||= $card->{Driver} eq 'i810' || $card->{Driver} eq 'fbdev';
    $bad_card ||= member($card->{Driver}, 'nvidia', 'vmware') if !$::isStandalone; #- avoid testing during install at any price.

    log::explanations("the graphics card does not like X in framebuffer") if $bad_card;

    !$bad_card;
}

sub readCardsDB {
    my ($file) = @_;
    my ($card, %cards);

    my $F = openFileMaybeCompressed($file);

    my $lineno = 0;
    my ($cmd, $val);
    my $fs = {
	NAME => sub {
	    $cards{$card->{card_name}} = $card if $card;
	    $card = { card_name => $val };
	},
	SEE => sub {
	    my $c = $cards{$val} or die "Error in database, invalid reference $val at line $lineno";
	    add2hash($card, $c);
	},
        LINE => sub { $val =~ s/^\s*//; $card->{raw_LINES} .= "$val\n" },
	CHIPSET => sub { $card->{Chipset} = $val },
	DRIVER => sub { $card->{Driver} = $val },
	DRIVER2 => sub { $card->{Driver2} = $val },
	NEEDVIDEORAM => sub { $card->{needVideoRam} = 1 },
	DRI_GLX => sub { $card->{DRI_GLX} = 1 if $card->{Driver} },
	DRI_GLX_EXPERIMENTAL => sub { $card->{DRI_GLX_EXPERIMENTAL} = 1 if $card->{Driver} },
	MULTI_HEAD => sub { $card->{MULTI_HEAD} = $val if $card->{Driver} },
	BAD_FB_RESTORE => sub { $card->{BAD_FB_RESTORE} = 1 },
	FB_TVOUT => sub { $card->{FB_TVOUT} = 1 },
	UNSUPPORTED => sub { delete $card->{Driver} },
	COMMENT => sub {},
    };

    local $_;
    while (<$F>) { $lineno++;
	s/\s+$//;
	/^#/ and next;
	/^$/ and next;
	/^END/ and do { $cards{$card->{card_name}} = $card if $card; last };

	($cmd, $val) = /(\S+)\s*(.*)/ or next;

	my $f = $fs->{$cmd};

	$f ? $f->() : log::l("unknown line $lineno ($_)");
    }
    \%cards;
}

our $default_ATI_fglrx_config = <<'END';
# === disable PnP Monitor  ===
#Option                              "NoDDC"
# === disable/enable XAA/DRI ===
Option "no_accel"                   "no"
Option "no_dri"                     "no"
# === FireGL DDX driver module specific settings ===
# === Screen Management ===
Option "DesktopSetup"               "0x00000000" 
Option "MonitorLayout"              "AUTO, AUTO"
Option "IgnoreEDID"                 "off"
Option "HSync2"                     "unspecified" 
Option "VRefresh2"                  "unspecified" 
Option "ScreenOverlap"              "0" 
# === TV-out Management ===
Option "NoTV"                       "yes"     
Option "TVStandard"                 "NTSC-M"     
Option "TVHSizeAdj"                 "0"     
Option "TVVSizeAdj"                 "0"     
Option "TVHPosAdj"                  "0"     
Option "TVVPosAdj"                  "0"     
Option "TVHStartAdj"                "0"     
Option "TVColorAdj"                 "0"     
Option "GammaCorrectionI"           "0x00000000"
Option "GammaCorrectionII"          "0x00000000"
# === OpenGL specific profiles/settings ===
Option "Capabilities"               "0x00000000"
# === Video Overlay for the Xv extension ===
Option "VideoOverlay"               "on"
# === OpenGL Overlay ===
# Note: When OpenGL Overlay is enabled, Video Overlay
#       will be disabled automatically
Option "OpenGLOverlay"              "off"
Option "CenterMode"                 "off"
# === QBS Support ===
Option "Stereo"                     "off"
Option "StereoSyncEnable"           "1"
# === Misc Options ===
Option "UseFastTLS"                 "0"
Option "BlockSignalsOnLock"         "on"
Option "UseInternalAGPGART"         "no"
Option "ForceGenericCPU"            "no"
# === FSAA ===
Option "FSAAScale"                  "1"
Option "FSAADisableGamma"           "no"
Option "FSAACustomizeMSPos"         "no"
Option "FSAAMSPosX0"                "0.000000"
Option "FSAAMSPosY0"                "0.000000"
Option "FSAAMSPosX1"                "0.000000"
Option "FSAAMSPosY1"                "0.000000"
Option "FSAAMSPosX2"                "0.000000"
Option "FSAAMSPosY2"                "0.000000"
Option "FSAAMSPosX3"                "0.000000"
Option "FSAAMSPosY3"                "0.000000"
Option "FSAAMSPosX4"                "0.000000"
Option "FSAAMSPosY4"                "0.000000"
Option "FSAAMSPosX5"                "0.000000"
Option "FSAAMSPosY5"                "0.000000"
END

1;

