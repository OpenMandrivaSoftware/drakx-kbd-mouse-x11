package Xconfig::plugins; # $Id: plugins.pm 110085 2007-01-18 08:45:14Z pixel $

use diagnostics;
use strict;

use Xconfig::parse;
use Xconfig::xfree;
use common;

my $dir = '/usr/share/libDrakX/x11-plugins';

sub list() {
    glob_("$dir/*.pl");
}

sub _load {
    my ($plugin_pl_file) = @_;
    my $plugin = eval cat_($plugin_pl_file);
    $@ and die "bad $plugin_pl_file. error: $@\n";

    #- ensure only one line
    $plugin->{summary} =~ s/\n/ /g;

    eval { $plugin->{raw} = Xconfig::parse::read_XF86Config_from_string($plugin->{conf}) };
    $@ and die "bad $plugin_pl_file conf. error: $@\n";

    $plugin;
}

my $mark = '# Using plugin';
sub parse_active_plugin {
    my ($raw_X) = @_;

    $raw_X->{plugins} and internal_error("parse_active_plugin must be done before doing anything with plugins");

    my $first = $raw_X->{raw}[0];
    if (my @l = $first->{pre_comment} =~ /^\Q$mark\E (.*)/gm) {
	$raw_X->{plugins} = [ map { { active => 1, summary => $_ } } @l ];
    }
}
sub _mark_active_in_header {
    my ($raw_X, $summary) = @_;
    my $first = $raw_X->{raw}[0];
    $first->{pre_comment} =~ s/\n/\n$mark $summary\n/;
}
sub _remove_active_in_header {
    my ($raw_X, $summary) = @_;
    my $first = $raw_X->{raw}[0];
    $first->{pre_comment} =~ s/\Q$mark $summary\E\n//;
}

sub load {
    my ($raw_X, $plugin_pl_file) = @_;

    my $plugin = eval { _load($plugin_pl_file) };
    $@ and log::l("bad plugin $plugin_pl_file: $@"), return;

    if (my $existing = find { $_->{summary} eq $plugin->{summary} } @{$raw_X->{plugins}}) {
	put_in_hash($existing, $plugin);
	$existing->{updated} = 1;
    } else {
	push @{$raw_X->{plugins}}, $plugin;	
    }
}

sub val { &Xconfig::xfree::val }

sub apply_plugin {
    my ($raw_X, $plugin) = @_;

    if ($plugin->{active}) {
	$plugin->{updated} or return;

	#- removing before re-applying again
	remove_plugin($raw_X, $plugin);
    }

    log::l("applying plugin $plugin->{summary}");

    foreach my $e (@{$plugin->{raw}}) {
	_mark_lines_with_name($plugin->{summary}, $e);

	if (my @sections = _select_sections_to_modify($raw_X, $e)) {
	    #- modifying existing sections
	    #- if there is more than one, modify all of them!
	    _merge_in_section($_, $e->{l}) foreach @sections;
	} else {
	    #- adding the section
	    $raw_X->add_Section($e->{name}, $e->{l});
	}
    }

    _mark_active_in_header($raw_X, $plugin->{summary});
    $plugin->{active} = 1;
}

sub _select_sections_to_modify {
    my ($raw_X, $e) = @_;

    my @sections = $raw_X->get_Sections($e->{name}) or return;

    if ($e->{l}{Identifier}) {
	if (my @l = grep { val($_->{Identifier}) eq $e->{l}{Identifier}{val} } @sections) {
	    #- only modifying the section(s) matching the Driver (useful for InputDevice)
	    delete $e->{l}{Identifier}; #- do not tag-with-comment this line used only to select the section
	    @l;
	} else {
	    #- if no matching section, we will create it
	    ();
	}
    } elsif ($e->{l}{Driver}) {
	if (my @l = grep { val($_->{Driver}) eq $e->{l}{Driver}{val} } @sections) {
	    #- only modifying the section(s) matching the Driver (useful for InputDevice)
	    delete $e->{l}{Driver}; #- do not tag-with-comment this line used only to select the section
	    @l;
	} else {
	    #- hum, modifying existing sections, is that good? :-/
	    @sections;
	}
    } else {
	#- modifying existing sections
	@sections;
    }
}

sub _merge_in_section {
    my ($h, $h_to_add) = @_;

    foreach my $name (keys %$h_to_add) {
	if (exists $h->{$name}) {
	    my $pre_comment = join('', map { "#HIDDEN $_->{val}\n" } deref_array($h->{$name}));
	    my ($first, @other) = deref_array($h_to_add->{$name});
	    $first = { pre_comment => $pre_comment, %$first };

	    $h->{$name} = ref($h->{$name}) eq 'ARRAY' ? [ $first, @other ] : $first;
	} else {
	    $h->{$name} = $h_to_add->{$name};
	}
    }
}

sub _mark_lines_with_name {
    my ($summary, $e) = @_;
    if ($e->{l}) {
	_mark_lines_with_name($summary, $_) foreach map { deref_array($_) } values %{$e->{l}};
    } else {
	$e->{comment_on_line} = " # $summary";
    }
}

sub remove_plugin {
    my ($raw_X, $plugin) = @_;

    $plugin->{active} or return;

    log::l("removing plugin $plugin->{summary}");

    @{$raw_X->{raw}} = map {
	_remove_plugin($plugin->{summary}, $_);
    } @{$raw_X->{raw}};

    _remove_active_in_header($raw_X, $plugin->{summary});
    $plugin->{active} = 0;
}

sub _remove_plugin {
    my ($summary, $e) = @_;
    if ($e->{l}) {
	my $removed;
	foreach my $k (keys %{$e->{l}}) {
	    my $v = $e->{l}{$k};
	    my @v = map { _remove_plugin($summary, $_) } deref_array($v);
	    if (@v) {
		if (ref($v) eq 'ARRAY') {
		    @$v = @v;
		} else {
		    $e->{l}{$k} = $v[0];
		}
	    } else {
		$removed = 1;
		delete $e->{l}{$k};
	    }
	}
	if_(!$removed || %{$e->{l}}, $e);
    } elsif ($e->{comment_on_line} eq " # $summary") {
	if (my @hidden = $e->{pre_comment} =~ /^#HIDDEN (.*)/gm) {
	    delete $e->{comment_on_line};
	    delete $e->{pre_comment};
	    map { { %$e, val => $_ } } @hidden;
	} else {
	    ();
	}
    } else {
	$e;
    }
}

sub apply_or_remove_plugin {
    my ($raw_X, $plugin, $apply) = @_;

    if ($apply) {
	apply_plugin($raw_X, $plugin);
    } else {
	remove_plugin($raw_X, $plugin);
    }
}

sub choose {
    my ($in, $raw_X) = @_;    

    parse_active_plugin($raw_X) if !$raw_X->{plugins};

    load($raw_X, $_) foreach list();

    my $plugins = $raw_X->{plugins};
    $_->{want_active} = $_->{active} foreach @$plugins;

    $in->ask_from_({},
		  [ { title => 1, label => N("Choose plugins") },
		    map { 
		      { type => 'bool', val => \$_->{want_active}, text => $_->{summary} },
			{ val => formatAlaTeX($_->{description}) };
		  } @$plugins ]) or return;

    foreach (@$plugins) {
	apply_or_remove_plugin($raw_X, $_, $_->{want_active})
	  if $_->{want_active} != $_->{active};
    }

    1;
}
1;
