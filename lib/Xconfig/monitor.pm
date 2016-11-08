package Xconfig::monitor; #- $Id$




use Xconfig::xfree;
use detect_devices;
use common;
use any;
use log;


sub good_default_monitor() {
#  detect_devices::is_xbox() ? 'Generic|640x480 @ 60 Hz' :
#    arch() =~ /ppc/ ? 
#      (detect_devices::get_mac_model() =~ /^iBook/ ? 'Apple|iBook 800x600' : 'Apple|iMac/PowerBook 1024x768');
    "Plug'n'Play"
}

sub default_monitor {
    my ($card_Driver) = @_;
#    if (detect_devices::is_virtualbox() || detect_devices::isLaptop() || $card_Driver eq 'siliconmotion' && arch() =~ /mips/) {
	# HACK: since there is no way to get the EDID on gdium, the resolution is passed to the kernel
	# so we can rely on it
	# in vbox, we return Plug'n'Play because the vbox integration addons
	# will take care of everything for us
	# On laptops the X server should usually be able to autodetect everything.
	{ VendorName => "Plug'n Play" };
#    } else {
#	good_default_monitor() =~ /(.*)\|(.*)/ or internal_error("bad good_default_monitor");
#	{ VendorName => $1, ModelName => $2 };
#    }
}

my @VertRefresh_ranges = ("50-70", "50-90", "50-100", "40-150");

my @HorizSync_ranges = (
	"31.5",
	"31.5-35.1",
	"31.5-37.9",
	"31.5-48.5",
	"31.5-57.0",
	"31.5-64.3",
	"31.5-79.0",
	"31.5-82.0",
	"31.5-88.0",
	"31.5-94.0",
);

sub configure {
    my ($in, $raw_X, $nb_monitors, $o_probed_info, $b_auto) = @_;

    my $monitors = [ $raw_X->get_or_new_monitors($nb_monitors) ];
    if ($o_probed_info) {
	put_in_hash($monitors->[0], $o_probed_info);
    }
    my $head_nb = 1;
    foreach my $monitor (@$monitors) {
	choose($in, $raw_X, $monitor, @$monitors > 1 ? $head_nb++ : 0, $b_auto) or return;
    }
    $raw_X->set_monitors(@$monitors);
    $monitors;
}

sub configure_auto_install {
    my ($raw_X, $old_X) = @_;

    if ($old_X->{monitor}) {
	#- keep compatibility
	$old_X->{monitor}{VertRefresh} = $old_X->{monitor}{vsyncrange};
	$old_X->{monitor}{HorizSync} = $old_X->{monitor}{hsyncrange};

	#- new name
	$old_X->{monitors} = [ delete $old_X->{monitor} ];
    }

    my $monitors = [ $raw_X->get_or_new_monitors($old_X->{monitors} ? int @{$old_X->{monitors}} : 1) ];
    mapn {
	my ($monitor, $auto_install_monitor) = @_;
	put_in_hash($monitor, $auto_install_monitor);
	configure_automatic($monitor);
    } $monitors, $old_X->{monitors} if $old_X->{monitors};

    my $card_Driver;
    if (!is_valid($monitors->[0])) {
	my ($first_card) = Xconfig::card::probe();
	$card_Driver = $first_card->{Driver} if $first_card;
	put_in_hash($monitors->[0], probe());
    }

    foreach my $monitor (@$monitors) {
	if (!is_valid($monitor)) {
	    put_in_hash($monitor, default_monitor($card_Driver));
	    configure_automatic($monitor) or internal_error("good_default_monitor (" . good_default_monitor()  . ") is unknown in MonitorsDB");
	}
    }
    $raw_X->set_monitors(@$monitors);
    $monitors;
}

sub choose {
    my ($in, $_raw_X, $monitor, $head_nb, $b_auto) = @_;

    my $ok = is_valid($monitor);
    if ($b_auto && $ok) {
	return $ok;
    }

    my (@l_monitors, %h_monitors);
    foreach (monitors_db()) {
	my $s = "$_->{VendorName}|$_->{ModelName}";
	push @l_monitors, $s;
	$h_monitors{$s} = $_;
    }
    $h_monitors{"Plug'n Play"} = {};

  ask_monitor:
    my $merge_name = sub {
	my ($monitor) = @_;
	$monitor->{ModelName} ? $monitor->{VendorName} . '|' . $monitor->{ModelName} : $monitor->{VendorName};
    };
    my $merged_name = do {
	my $merged_name = $merge_name->($monitor);
	if (!exists $h_monitors{$merged_name}) {
	    $merged_name = is_valid($monitor) ? 'Custom' : 
	                                        $merge_name->(default_monitor($raw_X->get_Driver));
	}
	$merged_name;
    };

    $in->ask_from_({ title => N("_: This is a display device\nMonitor"),
		     messages => $head_nb ? N("Choose a monitor for head #%d", $head_nb) : N("Choose a monitor"), 
		     interactive_help_id => 'configureX_monitor' 
		   },
		  [ { val => \$merged_name, separator => '|', 
		      list => ['Custom', "Plug'n Play", uniq(@l_monitors)],
		      format => sub { $_[0] eq 'Custom' ? N("Custom") : 
				      $_[0] eq "Plug'n Play" ? N("Plug'n Play") . ($monitor->{VendorName} eq "Plug'n Play" ? " ($monitor->{ModelName})" : '') :
				      $_[0] =~ /^Generic\|(.*)/ ? N("Generic") . "|$1" :  
				      N("Vendor") . "|$_[0]" },
		      sort => !$in->isa('interactive::gtk') } ]) or return;

    if ($merged_name eq "Plug'n Play") {
	local $::noauto = 0; #- hey, you asked for plug'n play, so i do probe!
	delete @$monitor{'VendorName', 'ModelName', 'EISA_ID', 'HorizSync', 'VertRefresh'};
	if ($head_nb <= 1) {
	    if (my $probed_info = probe()) {
		put_in_hash($monitor, $probed_info);
	    } else {
		log::l("Plug'n Play probing failed, but Xorg may do better");
		$monitor->{VendorName} = "Plug'n Play";
	    }
	} else {
	    $monitor->{VendorName} = "Plug'n Play";
	}
    } elsif ($merged_name eq 'Custom') {
	$in->ask_from('',
N("The two critical parameters are the vertical refresh rate, which is the rate
at which the whole screen is refreshed, and most importantly the horizontal
sync rate, which is the rate at which scanlines are displayed.

It is VERY IMPORTANT that you do not specify a monitor type with a sync range
that is beyond the capabilities of your monitor: you may damage your monitor.
 If in doubt, choose a conservative setting."),
		      [ { val => \$monitor->{HorizSync}, list => \@HorizSync_ranges, label => N("Horizontal refresh rate"), not_edit => 0 },
			{ val => \$monitor->{VertRefresh}, list => \@VertRefresh_ranges, label => N("Vertical refresh rate"), not_edit => 0 } ]) or goto &choose;
	delete @$monitor{'VendorName', 'ModelName', 'EISA_ID'};
    } else {
	put_in_hash($monitor, $h_monitors{$merged_name});
    }
    $monitor->{manually_chosen} = 1;
    1;
}

sub _configure_automatic_LCD {
    my ($monitor) = @_;

    $monitor->{HorizSync} && $monitor->{VertRefresh} and return;

    $monitor->{preferred_resolution} 
      && Xconfig::xfree::resolution2ratio($monitor->{preferred_resolution}) eq '16/10' or return;

    log::l("no HorizSync nor VertRefresh, using preferred resolution (hopefully this is a flat panel)");
    add2hash($monitor, generic_flat_panel($monitor->{preferred_resolution}));
    1;
}

sub configure_automatic {
    my ($monitor) = @_;

    if ($monitor->{EISA_ID}) {
	log::l("EISA_ID: $monitor->{EISA_ID}");
	if (my $mon = find { lc($_->{EISA_ID}) eq $monitor->{EISA_ID} } monitors_db()) {
	    add2hash($monitor, $mon);
	    log::l("EISA_ID corresponds to: $monitor->{ModelName}");
	} elsif (!$monitor->{HorizSync} || !$monitor->{VertRefresh}) {
	    log::l("unknown EISA_ID and partial DDC probe, so unknown monitor");
	    delete @$monitor{'VendorName', 'ModelName', 'EISA_ID'};	    
	}
    } elsif ($monitor->{VendorName}) {
	if (my $mon = find { $_->{VendorName} eq $monitor->{VendorName} && $_->{ModelName} eq $monitor->{ModelName} } monitors_db()) {
	    put_in_hash($monitor, $mon);
	}
    }

    _configure_automatic_LCD($monitor);

    is_valid($monitor);
}

sub is_valid {
    my ($monitor) = @_;
    $monitor->{HorizSync} && $monitor->{VertRefresh} || $monitor->{VendorName} eq "Plug'n Play";
}

sub probe() {
    probe_DDC() || probe_DMI();
}

#- some EDID are much too strict:
#- the HorizSync range is too small to allow smaller resolutions
sub adjust_HorizSync_from_edid {
    my ($monitor) = @_;
    
    my ($hmin, $hmax) = $monitor->{HorizSync} =~ /(\d+)-(\d+)/ or return;
    if ($hmin > 45) {
	log::l("replacing HorizSync $hmin-$hmax with 28.8-$hmax (allow 800x480)");
	$monitor->{HorizSync} = "28.8-$hmax";
    }
}
#- the VertRefresh range is too weird
sub adjust_VertRefresh_from_edid {
    my ($monitor) = @_;
    
    my ($vmin, $vmax) = $monitor->{VertRefresh} =~ /(\d+)-(\d+)/ or return;
    if ($vmin > 60) {
	log::l("replacing VertRefresh $vmin-$vmax with 60-$vmax");
	$monitor->{VertRefresh} = "60-$vmax";
    }
}

sub probe_DDC() {
    my ($edid, $vbe) = any::monitor_full_edid() or return;
    my $monitor = eval($edid);

    if ($vbe =~ /Memory: (\d+)k/) {
	$monitor->{VideoRam_probed} = $1;
    }
    use_EDID($monitor);
}

sub use_EDID {
    my ($monitor) = @_;

    adjust_HorizSync_from_edid($monitor);
    adjust_VertRefresh_from_edid($monitor);

    $monitor->{ModeLine} = Xconfig::xfree::default_ModeLine();
    my $detailed_timings = $monitor->{detailed_timings} || [];
    my @different_timings = uniq_ { $_->{horizontal_active} . 'x' . $_->{vertical_active} } @$detailed_timings;
    foreach (grep { !$_->{bad_ratio} } @$detailed_timings) {
	if (Xconfig::xfree::xorg_builtin_resolution($_->{horizontal_active}, $_->{vertical_active})) {
	    #- we don't want the 4/3 modelines otherwise they conflict with the Xorg builtin vesamodes
	} else {
	    unshift @{$monitor->{ModeLine}},
	      { val => $_->{ModeLine}, pre_comment => $_->{ModeLine_comment} . "\n" };
	}

	if ((@different_timings == 1 || $_->{preferred}) && $_->{horizontal_active} >= 1024) {
	    #- we don't use detailed_timing when it is 640x480 or 800x600,
	    #- since 14" CRTs often give this even when they handle 1024x768 correctly (and desktop is no good in poor resolutions)

	    $monitor->{preferred_resolution} = { X => $_->{horizontal_active}, Y => $_->{vertical_active} };
	}
    }

    if ($monitor->{EISA_ID}) {
	$monitor->{VendorName} = "Plug'n Play";
	$monitor->{ModelName} = $monitor->{monitor_name};
	$monitor->{ModelName} =~ s/"/''/g;
	$monitor->{ModelName} =~ s/[\0-\x20]/ /g;
    }
    configure_automatic($monitor) or return;
    $monitor;
}

sub probe_DMI() {
    my $res = detect_devices::probe_unique_name('Resolution');
    $res && generic_flat_panel_txt($res);
}

sub generic_flat_panel {
    my ($resolution) = @_;
    generic_flat_panel_($resolution->{X}, $resolution->{Y});
}
sub generic_flat_panel_txt {
    my ($resolution) = @_;
    my ($X, $Y) = $resolution =~ /(\d+)x(\d+)/ or log::l("bad resolution $resolution"), return;
    generic_flat_panel_($X, $Y);
}
sub generic_flat_panel_ {
    my ($X, $Y) = @_;
    {
	VendorName => 'Generic',
	ModelName => "Flat Panel ${X}x${Y}",
	HorizSync => '28.8-' . ($X > 1920 ? '100' : '90'), VertRefresh => '60',
	preferred_resolution => { X => $X, Y => $Y },
    };
}

my $monitors_db;
sub monitors_db() {
    $monitors_db ||= readMonitorsDB("$ENV{SHARE_PATH}/ldetect-lst/MonitorsDB");
    @$monitors_db;
}
sub readMonitorsDB {
    my ($file) = @_;

    my @monitors_db;
    my $F = openFileMaybeCompressed($file);
    local $_;
    my $lineno = 0; while (<$F>) {
	$lineno++;
	s/\s+$//;
	/^#/ and next;
	/^$/ and next;

	my @fields = qw(VendorName ModelName EISA_ID HorizSync VertRefresh dpms);
	my %l; @l{@fields} = split /\s*;\s*/;
	push @monitors_db, \%l;
    }
    \@monitors_db;
}


1;

