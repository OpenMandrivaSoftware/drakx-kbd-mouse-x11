package Xconfig::screen; # $Id$

use diagnostics;
use strict;

use common;
# perl_checker: require Xconfig::xfree

sub configure {
    my ($raw_X) = @_; # perl_checker: $raw_X = Xconfig::xfree->new

    my @devices = $raw_X->get_devices;
    my @monitors = $raw_X->get_monitors;

    if (@monitors < @devices) {
	$raw_X->set_monitors(@monitors, ({}) x (@devices - @monitors));
	@monitors = $raw_X->get_monitors;
    }

    my @sections = mapn {
	my ($device, $monitor) = @_;
	{ Device => $device->{Identifier}, Monitor => $monitor->{Identifier} };
    } \@devices, \@monitors;

    $raw_X->set_screens(@sections);
    1;
}

1;
