package HPC::Runner::Command::Plugin::Logger::Elastic;

our $VERSION = '0.01';

use MooseX::App::Role;

##TODO this declaration should be a role
with 'HPC::Runner::Command::Utils::ManyConfigs';

option 'config_base' => (
    is      => 'rw',
    default => '.hpcrunner',
);

use Cwd;
use Log::Log4perl qw(:easy);
use Search::Elasticsearch;

##Application log
##TODO Add this to its own class in hpcrunner
has 'app_log' => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self     = shift;
        my $log_conf = q(
log4perl.category = DEBUG, Screen
log4perl.appender.Screen = \
    Log::Log4perl::Appender::ScreenColoredLevels
log4perl.appender.Screen.layout = \
    Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern = \
    [%d] %m %n
        );

        Log::Log4perl->init( \$log_conf );
        return get_logger();
    }
);

=head3 submission_id

This is the ID for the entire hpcrunner.pl submit_jobs submission, not the individual scheduler IDs

=cut

option 'submission_id' => (
    is        => 'rw',
    isa       => 'Str|Int',
    lazy      => 1,
    default   => '',
    predicate => 'has_submission_id',
    clearer   => 'clear_submission_id'
);

=head3 nodes

=cut

option 'nodes' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub {
        return ['http://localhost:9200'];
    },
    documentation => q(Elastic Search nodes. Default is 'http://localhost:9200'),
    lazy => 1,
);

=head3 elasticsearch

elastic search connection object

=cut

has 'elasticsearch' => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $e = Search::Elasticsearch->new( nodes => $self->nodes );
        return $e;
    },
);

1;

__END__

=encoding utf-8

=head1 NAME

HPC::Runner::Command::Plugin::Logger::Elastic - Blah blah blah

=head1 SYNOPSIS

  use HPC::Runner::Command::Plugin::Logger::Elastic;

=head1 DESCRIPTION

HPC::Runner::Command::Plugin::Logger::Elastic is

=head1 AUTHOR

Jillian Rowe E<lt>jillian.e.rowe@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2017- Jillian Rowe

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
