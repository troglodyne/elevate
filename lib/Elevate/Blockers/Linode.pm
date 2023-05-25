package Elevate::Blockers::Linode;

=encoding utf-8

=head1 NAME

Elevate::Blockers::Linode

Custom Blocker for Linode to advise users about things they need to do in order
to ensure the elevate process completes successfully.

=cut

use cPstrict;

use Cpanel::Pkgr ();

use parent qw{Elevate::Blockers::Base};

use Log::Log4perl qw(:easy);

sub check ($self) {

    return 0 unless $self->__is_linode();

    my $message = <<~"EOS";
    We have detected that your server is hosted by "Akamai Technologies, Inc.",
    specifically on the platform which was once known as "Linode".
    EOS

    my $longview = <<~"EOS";
    Before continuing the elevation process, you should uninstall the package
    for 'linode-longview', as this will interfere with the upgrade. After
    upgrade, this can be safely reinstalled.
    EOS

    $message .= "\n$longview" if $has_longview;

    # TODO add logic for saying what's needed maybe for boots not to F up

    return $self->has_blocker($message);
}

my $has_longview;
sub __is_linode ($self) {
    return 1 if -e q[/dev/disk/by-label/linode-root];
    return 1 if $has_longview = Cpanel::Pkgr::is_installed('linode-longview');

    # Ok, we've exhaused the easy stuff to check for. Now let's just check the
    # IP we're on to see if we're "in range" of known linode IPs.
    # XXX TODO, mostly steal from OVH module other than ip blocks
}

1;
