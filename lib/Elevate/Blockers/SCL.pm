package Elevate::Blockers::SCL;

=encoding utf-8

=head1 NAME

Elevate::Blockers::SCL

Blockers for (non-postgres) SCL provided packages: MySQL, MariaDB, MongoDB...
Also is a surprise tool that will help us later

=cut

use cPstrict;

use Cpanel::Pkgr       ();
use Elevate::StageFile ();

use parent qw{Elevate::Blockers::Base};

sub check ($self) {
    return 0 unless grep { Cpanel::Pkgr::is_installed($_) } qw{centos-release-scl centos-release-scl-rh};
    my %pkgs2check4repo = map { $_ => [ cpev::get_installed_rpms_in_repo($_) ]; } qw{
      centos-sclo-rh
      centos-sclo-rh-testing
      centos-sclo-rh-source
      centos-sclo-rh-debuginfo
      centos-sclo-sclo
      centos-sclo-sclo-testing
      centos-sclo-sclo-source
      centos-sclo-sclo-debuginfo
    };
    my %pkgs_by_action = (
        'blocked' => [],
        'saved'   => [],
    );
    foreach my $repo ( keys %pkgs2check4repo ) {
        foreach my $pkg ( @{ $pkgs2check4repo{$repo} } ) {
            my $action = ( $pkg =~ m/(mongodb|mariadb|mysql|varnish).+/ ) ? 'blocked' : 'saved';
            push @{ $pkgs_by_action{$action} }, [ $pkg, $repo ];
        }
    }
    if ( @{ $pkgs_by_action{'blocked'} } ) {
        my $message = <<~'EOS';
        The following packages from the CentOS SCLo Repositories are known to cause
        issues with ELevation. Please remove the following packages before continuing
        with the Elevate process:

        Package                                                              Repository
        -------                                                              ----------
        EOS

        $message .= _purty_print_repo_line( @{$_} ) for @{ $pkgs_by_action{'blocked'} };

        return $self->has_blocker($message);
    }

    # Store the rest for later to be efficient and not have to fetch them
    # in pre-leapp later within a component. We don't need to store what
    # repo it came from, as Alma's base *should* provide it on 8.
    Elevate::StageFile::update_stage_file(
        { scl_packages => [ map { $_->[0] } @{ $pkgs_by_action{'saved'} } ] },
    );

    return 0;
}

# I like how `yum list` presents the repo for a package, so figured I'd
# print it all purty like yum does. Thus it's a regional dialect of pretty.
#    some-package-name                                                 @whee
sub _purty_print_repo_line ( $pkg, $repo ) {
    die "Bad caller" if !$pkg || !$repo;
    my $spaces = ( 78 - ( length($pkg) + length($repo) ) );
    $spaces = 1 if !$spaces || abs($spaces) ne $spaces;
    return $pkg . ' ' x $spaces . "\@${repo}\n";
}

1;
