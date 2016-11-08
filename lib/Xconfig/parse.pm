package Xconfig::parse; # $Id$

use diagnostics;
use strict;

use common;
use Xconfig::card;

sub read_XF86Config {
    my ($file) = @_;
    my $raw = _rraw_from_file($file);
    _from_rraw(@$raw);
    $raw;
}

sub prepare_write_XF86Config {
    my ($raw) = @_;
    map { _raw_to_string(_before_to_string({ %$_ }, 0)) } @$raw;
}

sub write_XF86Config {
    my ($raw, $file) = @_;
    my @blocks = prepare_write_XF86Config($raw);
    @blocks ? output($file, @blocks) : unlink $file;
}

sub read_XF86Config_from_string {
    my ($s) = @_;
    my $raw = _rraw_from_file('-', [ split "\n", $s ]);
    _from_rraw(@$raw);
    $raw;
}

#-###############################################################################
#- raw reading/saving
#-###############################################################################
sub _rraw_from_file {
    my ($file, $o_lines) = @_;
    my $rraw = [];

    my $lines = $o_lines || [ cat_($file) ];
    my $line;

    my ($comment, $obj, @objs);

    my $attach_comment = sub {
	$obj || @objs or warn "$file:$line: can not attach comment\n";
	if ($comment) {
	    $comment =~ s/\n+$/\n/;
	    ($obj || $objs[0])->{$_[0] . '_comment'} = $comment;
	    $comment = '';
	}
    };

    foreach (@$lines) {
	$line++;
	s/^\s*//; s/\s*$//;

	if (/^$/) {
	    $comment .= "\n" if $comment;
	    next;
	} elsif (@objs ? m/^#\W/ || /^#$/ : /^#/) {
	    s/^#\s+/# /;
	    $comment .= "$_\n";
	    next;
	}

	if (/^Section\s+"(.*)"/i) {
	    die "$file:$line: missing EndSection\n" if @objs;
	    my $e = { name => $1, l => [], kind => 'Section' };
	    push @$rraw, $e;
	    unshift @objs, $e; $obj = '';
	    $attach_comment->('pre');
	} elsif (/^Subsection\s+"(.*)"/i) {
	    die "$file:$line: missing EndSubsection\n" if  @objs && $objs[0]{kind} eq 'Subsection';
	    die "$file:$line: not in Section\n"        if !@objs || $objs[0]{kind} ne 'Section';
	    my $e = { name => $1, l => [], kind => 'Subsection' };
	    push @{$objs[0]{l}}, $e;
	    unshift @objs, $e; $obj = '';
	    $attach_comment->('pre');
	} elsif (/^EndSection/i) {
	    die "$file:$line: not in Section\n"        if !@objs || $objs[0]{kind} ne 'Section';
	    $attach_comment->('post');
	    shift @objs; $obj = '';
	} elsif (/^EndSubsection/i) {
	    die "$file:$line: not in Subsection\n"     if !@objs || $objs[0]{kind} ne 'Subsection';
	    $attach_comment->('post');
	    shift @objs; $obj = '';
	} else {
	    die "$file:$line: not in Section\n" if !@objs;

	    my $commented = s/^#//;

	    my $comment_on_line;
	    s/(\s*#.*)/$comment_on_line = $1; ''/e;

	    if (/^$/) {
		die "$file:$line: weird";
	    }

	    (my $name, my $Option, $_)  = 
 	      /^Option\s*"(.*?)"(.*)/ ? ($1, 1, $2) : /^(\S+)(.*)/ ? ($1, 0, $2) : internal_error($_);
	    my ($val) = /(\S.*)/;

	    my %e = (Option => $Option, commented => $commented, comment_on_line => $comment_on_line, pre_comment => $comment);
	    $comment = '';
	    $obj = { name => $name, val => $val };
	    $e{$_} and $obj->{$_} = $e{$_} foreach keys %e;

	    push @{$objs[0]{l}}, $obj;
	}
    }
    $rraw;
}

sub _simple_val_to_string {
    my ($name, $e) = @_;
    my $key = $e->{Option} ? qq(Option "$name") : $name;
    my $val = defined $e->{val} ? ($e->{Option} && $e->{val} !~ /^"/ ? qq( "$e->{val}") : qq( $e->{val})) : '';
    ($e->{commented} ? '#' : '') . $key . $val;
}

sub _raw_to_string {
    my ($e, $b_want_spacing) = @_;
    my $s = do {
	if ($e->{l}) {
	    my $inside = join('', map_index { _raw_to_string($_, $::i) } @{$e->{l}});
	    $inside .= $e->{post_comment} || '';
	    $inside =~ s/^/    /mg;
	    qq(\n$e->{kind} "$e->{name}"\n) . $inside . "End$e->{kind}";
	} else {
	    _simple_val_to_string($e->{name}, $e);
	}
    };
    ($e->{pre_comment} ? ($b_want_spacing ? "\n" : '') . $e->{pre_comment} : '') . $s . ($e->{comment_on_line} || '') . "\n" . (!$e->{l} && $e->{post_comment} || '');
}

#-###############################################################################
#- refine the data structure for easier use
#-###############################################################################
my %kind_names = (
    Pointer  => [ qw(Protocol Device Emulate3Buttons Emulate3Timeout EmulateWheel EmulateWheelButton) ],
    Mouse    => [ qw(DeviceName Protocol Device AlwaysCore Emulate3Buttons Emulate3Timeout EmulateWheel EmulateWheelButton) ], # Subsection in XInput
    Keyboard => [ qw(Protocol Driver XkbModel XkbLayout XkbVariant XkbDisable) ],
    Monitor  => [ qw(Identifier VendorName ModelName HorizSync VertRefresh PreferredMode) ],
    Device   => [ qw(Identifier VendorName BoardName Chipset Driver VideoRam Screen BusID DPMS power_saver AccelMethod MonitorLayout TwinViewOrientation BIOSHotkeys RenderAccel SWCursor XaaNoOffscreenPixmaps) ],
    Display  => [ qw(Depth Modes Virtual) ], # Subsection in Device
    Screen   => [ qw(Identifier Driver Device Monitor DefaultDepth DefaultColorDepth) ],
    Extensions  => [ qw(Composite) ],
    InputDevice => [ qw(Identifier Driver Protocol Device Type Mode XkbModel XkbLayout XkbVariant XkbDisable Emulate3Buttons Emulate3Timeout EmulateWheel EmulateWheelButton) ],
    WacomCursor => [ qw(Port) ], #-\
    WacomStylus => [ qw(Port) ], #--> Port must be first
    WacomEraser => [ qw(Port) ], #-/
    ServerLayout => [ qw(Identifier) ],
);
my @want_string = qw(Identifier DeviceName VendorName ModelName BoardName Driver Device Chipset Monitor Protocol XkbModel XkbLayout XkbVariant XkbOptions XkbCompat Load Disable ModulePath BusID PreferredMode);

%kind_names = map_each { lc $::a => [ map { lc } @$::b ] } %kind_names;
@want_string = map { lc } @want_string;

sub _from_rraw {
    sub _from_rraw__rec {
	my ($current, $e) = @_;
	if ($e->{l}) {
	    _from_rraw($e);
	    push @{$current->{l}{$e->{name}}}, $e;
	} else {
	    if (member(lc $e->{name}, @want_string) || $e->{Option} && $e->{val}) {
		$e->{val} =~ s/^"(.*)"$/$1/ or warn "$e->{name} $e->{val} has no quote\n";
	    }

	    if (member(lc $e->{name}, @{$kind_names{lc $current->{name}} || []})) {
		if ($current->{l}{$e->{name}} && !$current->{l}{$e->{name}}{commented}) {
		    warn "skipping conflicting line for $e->{name} in $current->{name}\n" if !$e->{commented};
		} else {
		    $current->{l}{$e->{name}} = $e;
		}
	    } else {
		push @{$current->{l}{$e->{name}}}, $e;
	    }
	}
	delete $e->{name};
    }

    foreach my $e (@_) {
	($e->{l}, my $l) = ({}, $e->{l});
	_from_rraw__rec($e, $_) foreach @$l;

	delete $e->{kind};
    }
}

sub _before_to_string {
    my ($e, $depth) = @_;

    if ($e->{l}) {
	$e->{kind} = $depth ? 'Subsection' : 'Section';

	my %rated = map_index { $_ => $::i + 1 } @{$kind_names{lc $e->{name}} || []};
	my @sorted = sort { ($rated{lc $a} || 99) <=> ($rated{lc $b} || 99) } keys %{$e->{l}};
	$e->{l} = [ map {		  
	    my $name = $_;
	    map { 
		_before_to_string({ name => $name, %$_ }, $depth+1);
	    } deref_array($e->{l}{$name});
	} @sorted ];
    } elsif (member(lc $e->{name}, @want_string)) {
	$e->{val} = qq("$e->{val}");
    }
    $e;
}
