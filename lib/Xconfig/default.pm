package Xconfig::default; # $Id$

use diagnostics;
use strict;

use Xconfig::xfree;
use keyboard;
use common;
use mouse;
use modules::any_conf;


sub configure {
    my ($do_pkgs, $o_keyboard, $o_mouse) = @_;

    my $mouse = $o_mouse || do {
	my $mouse = mouse::read(); 
	add2hash($mouse, mouse::detect(modules::any_conf->read)) if !$::noauto;
	$mouse;
    };

    my $raw_X = Xconfig::xfree->empty_config;

    $raw_X->add_load_module('v4l');

    config_mouse($raw_X, $do_pkgs, $mouse);

    $raw_X;
}

sub config_mouse {
    my ($raw_X, $do_pkgs, $mouse) = @_;
    mouse::set_xfree_conf($mouse, $raw_X);
    mouse::various_xfree_conf($do_pkgs, $mouse);
}

1;

