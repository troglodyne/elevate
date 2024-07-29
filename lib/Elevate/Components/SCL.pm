package Elevate::Components::SCL;

=encoding utf-8

=head1 NAME

Elevate::Components::SCLPkgs

Uninstalls, then later Reinstalls packages from SCL we saved in --check.

=cut

use cPstrict;

use Log::Log4perl qw(:easy);

use parent qw{Elevate::Components::Base};

sub pre_leapp ($self) {
    my $pkgs2remove = Elevate::StageFile::read_stage_file('scl_packages');
    $self->cpev->ssystem( qw{rpm -e}, @$pkgs2remove ) and do {

        # Force re-read in case things went sideways and they fix it
        Elevate::StageFile::remove_from_stage_file('scl_packages');
        die "Failed to remove SCL packages; rpm exited nonzero ($?). Manual cleanup may be necessary before re-running ELevate.";
    };

    return;
}

sub post_leapp ($self) {
    my $pkgs2reinstall = Elevate::StageFile::read_stage_file('scl_packages');

    # OK, let's reinstall the repos themselves.
    $self->cpev->ssystem( qw{yum -y install}, @$pkgs2reinstall )
      and WARN("Failed to reinstall SCL packages; yum exited nonzero ($?). Manual cleanup may be necessary.");

    return;
}

1;
