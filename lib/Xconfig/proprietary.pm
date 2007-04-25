package Xconfig::proprietary; # $Id$

use diagnostics;
use strict;

use common;
use Xconfig::card;

my $lib = arch() =~ /x86_64/ ? "lib64" : "lib";

sub install_matrox_hal {
    my ($prefix) = @_;
    my $tmpdir = "$prefix/root/tmp";

    my $tar = "mgadrivers-2.0.tgz";
    my $dir_in_tar = "mgadrivers";
    my $dest_dir = "$prefix/usr/lib/xorg/modules/drivers";

    #- already installed
    return if -e "$dest_dir/mga_hal_drv.o" || $::testing;

    system("wget -O $tmpdir/$tar ftp://ftp.matrox.com/pub/mga/archive/linux/2002/$tar") if !-e "$tmpdir/$tar";
    system("tar xzC $tmpdir -f $tmpdir/$tar");

    my $src_dir = "$tmpdir/$dir_in_tar/xfree86/4.2.1/drivers";
    foreach (all($src_dir)) {
	my $src = "$src_dir/$_";
	my $dest = "$dest_dir/$_";
	rename $dest, "$dest.non_hal";
	cp_af($src, $dest_dir);
    }
    rm_rf("$tmpdir/$tar");
    rm_rf("$tmpdir/$dir_in_tar");
}

sub pkg_name_for_Driver2 {
    my ($card) = @_;
    $card->{Driver2} eq 'fglrx' ? 'ati' :
    $card->{Driver2} =~ /^nvidia/ ? $card->{Driver2} : '';
}

sub pkgs_for_Driver2 {
    my ($card, $do_pkgs) = @_;

    my $pkg = pkg_name_for_Driver2($card);

    $pkg && $do_pkgs->is_available($pkg) or return;

    my $module_pkgs = $do_pkgs->check_kernel_module_packages($pkg) or
      log::l("$pkg available, but no kernel module package (for installed kernels, and no dkms)"), return;

    ($pkg, @$module_pkgs);
}

sub may_use_Driver2 {
    my ($card) = @_;

    my $modules_dir = Xconfig::card::modules_dir();
    #- make sure everything is correct at this point, packages have really been installed
    #- and driver and GLX extension is present.

    my $check_drv = sub {
	my ($drv, $o_subdir) = @_;
	my @l = (if_($o_subdir, "$modules_dir/drivers/$o_subdir/$drv.so"),
		 "$modules_dir/drivers/$drv.so",
		 "$modules_dir/drivers/$drv.o");
	my $has = find { -e "$::prefix$_" } @l;
	$has or log::l("proprietary $drv driver missing, defaulting to free software driver (we searched for: @l)");
	$has;
    };

    my $card2 = { 
	%$card,
	$card->{Driver2} =~ /^nvidia(.*)/ ?
	  (Driver => 'nvidia', DriverVersion => $1) :
	  (Driver => $card->{Driver2}),
    };

    if ($card2->{Driver} eq 'nvidia') {
	$check_drv->('nvidia_drv', "nvidia$card2->{DriverVersion}") or return;

	my $libglx_path = Xconfig::card::modules_dir() . "/extensions/nvidia$card2->{DriverVersion}";
	-e "$::prefix$libglx_path/libglx.so" or log::l("special NVIDIA libglx missing, defaulting to free software driver"), return;

	log::explanations("Using specific NVIDIA driver and GLX extensions");
	$card2->{DRI_GLX_SPECIAL} = $libglx_path;
	$card2->{Options}{IgnoreEDID} = 1 if $card2->{DriverVersion} ne '97xx';
	$card2;
    } elsif ($card2->{Driver} eq 'fglrx') {
	$check_drv->('fglrx_drv') or return;
	-e "$::prefix$modules_dir/dri/fglrx_dri.so" || -e "$::prefix/usr/$lib/dri/fglrx_dri.so" or
	  log::l("proprietary fglrx_dri.so missing, defaulting to free software driver"), return;

	log::explanations("Using specific ATI fglrx and DRI drivers");
	$card2->{DRI_GLX} = 1;
	$card2;
    } else {
	undef;
    }
}

1;

