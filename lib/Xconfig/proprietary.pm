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

sub handle_DRIVER2_NO_SSE {
    my ($card) = @_;

    $card->{DRIVER2_NO_SSE} or return;

    require detect_devices;
    if (!detect_devices::has_cpu_flag('sse')) {
	log::l("$card->{Driver2} need a processor featuring SSE, switching back to $card->{DRIVER2_NO_SSE}");
	$card->{Driver2} = $card->{DRIVER2_NO_SSE};
    }
}


sub pkgs_for_Driver2 {
    my ($Driver2, $do_pkgs) = @_;

    my ($pkg, $base_name) = $Driver2 =~ /^fglrx|^nvidia/ ?
                            ("x11-driver-video-$Driver2", $Driver2) : () or return;

    $do_pkgs->is_installed($pkg) || $do_pkgs->is_available($pkg) or
      log::l("proprietary package $pkg not available"), return;

    my $module_pkgs = $do_pkgs->check_kernel_module_packages($base_name) or
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
	my @l = (if_($o_subdir, "$modules_dir/drivers/$o_subdir/$drv.so",
		 "/usr/$lib/$o_subdir/xorg/$drv.so"),
		 "$modules_dir/drivers/$drv.so",
		 "$modules_dir/drivers/$drv.o");
	my $has = find { -e "$::prefix$_" } @l;
	$has or log::l("proprietary $drv driver missing (we searched for: @l)");
	$has;
    };

    my $card2 = { 
	%$card,
	$card->{Driver2} =~ /^(fglrx|nvidia)(.*)/ ?
	  (Driver => $1, DriverVersion => $2) :
	  (Driver => $card->{Driver2}),
    };

    if ($card2->{Driver} eq 'nvidia') {
	$check_drv->('nvidia_drv', "nvidia$card2->{DriverVersion}") or return;

	my $libglx_path = "/usr/$lib/nvidia$card2->{DriverVersion}/xorg";
	-e "$::prefix$libglx_path/libglx.so" or log::l("special NVIDIA libglx missing"), return;

	log::explanations("Using specific NVIDIA driver and GLX extensions");
	$card2->{DRI_GLX_SPECIAL} = 1;
	$card2->{Options}{IgnoreEDID} = 1 if $card2->{DriverVersion} eq "71xx";
	$card2->{Options}{UseEDID} = 0 if $card2->{DriverVersion} eq "96xx";
	$card2;
    } elsif ($card2->{Driver} eq 'fglrx') {
	$check_drv->('fglrx_drv', "fglrx$card2->{DriverVersion}") or return;
	-e "$::prefix/usr/$lib/fglrx$card2->{DriverVersion}/dri/fglrx_dri.so" ||
	  -e "$::prefix$modules_dir/dri/fglrx_dri.so" ||
	  -e "$::prefix/usr/$lib/dri/fglrx_dri.so" or
	  log::l("proprietary fglrx_dri.so missing"), return;

	log::explanations("Using specific ATI fglrx and DRI drivers");
	$card2->{DRI_GLX} = 1;
	$card2;
    } else {
	undef;
    }
}

1;

