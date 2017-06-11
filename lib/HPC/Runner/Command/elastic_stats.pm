package HPC::Runner::Command::elastic_stats;
use MooseX::App::Command;

use Log::Log4perl qw(:easy);
use JSON;
use Text::ASCIITable;

with 'HPC::Runner::Command::Plugin::Logger::Elastic';
with 'HPC::Runner::Command::stats::Plugin::Logger::Elastic::Summary';
with 'HPC::Runner::Command::stats::Plugin::Logger::Elastic::Long';

command_short_description 'Get an overview of your submission.';
command_long_description 'Query Elastic Search for a submission overview.';

#TODO project and jobname are already defined as options in execute_array
option 'most_recent' => (
    is            => 'rw',
    isa           => 'Bool',
    required      => 0,
    default       => 1,
    documentation => q(Show only the most recent submission.),
    trigger       => sub {
        my $self = shift;
        $self->all(1) if !$self->most_recent;
    }
);

option 'all' => (
    is            => 'rw',
    isa           => 'Bool',
    required      => 0,
    default       => 0,
    documentation => 'Show all submissions.',
    trigger       => sub {
        my $self = shift;
        $self->most_recent(1) if !$self->all;
    },
    cmd_aliases => ['a'],
);

option 'project' => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'Query by project',
    required      => 0,
    predicate     => 'has_project',
);

option 'jobname' => (
    is            => 'rw',
    isa           => 'Str',
    documentation => 'Query by jobname',
    required      => 0,
    predicate     => 'has_jobname',
);

option 'summary' => (
    is  => 'rw',
    isa => 'Bool',
    documentation =>
'Summary view of your jobs - Number of running, completed, failed, successful.',
    required => 0,
    default  => 1,
);

option 'long' => (
    is  => 'rw',
    isa => 'Bool',
    documentation =>
      'Long view. More detailed report - Task tags, exit codes, duration, etc.',
    required => 0,
    default  => 0,
    trigger  => sub {
        my $self = shift;
        $self->summary(0) if $self->long;
    },
    cmd_aliases => ['l'],
);

has 'task_data' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub { {} },
    clearer => 'clear_task_data',
);

sub execute {
    my $self = shift;

    return unless $self->elasticsearch;
    $self->iter_submissions;
}

sub iter_submissions {
    my $self    = shift;
    my $results = $self->get_submissions();

    my $total = scalar @{$results};
    $total = 0 if $self->most_recent;

    for ( my $x = 0 ; $x <= $total ; $x++ ) {
        my $submission = $results->[$x];

        my $jobref = $submission->{_source}->{hpc_meta}->{jobs};

        $self->iter_jobs_summary( $submission, $jobref ) if $self->summary;
        $self->iter_jobs_long( $submission, $jobref ) if $self->long;
    }
}

sub build_table {
    my $self = shift;
    my $res  = shift;

    my $header = "Time: " . $res->{_source}->{submission_time};
    $header .= " Project: " . $res->{_source}->{project}
      if defined $res->{_source}->{project};
    $header .= "\nSubmissionID: " . $res->{_id};
    my $table = Text::ASCIITable->new( { headingText => $header } );

    return $table;
}

sub get_submissions {
    my $self = shift;
    my $search = { sort => [ { submission_time => 'desc' } ], };

    if ( $self->has_project ) {
        $search->{query}->{bool}->{must}->{match} =
          { project => $self->project };
    }

    my $results = $self->elasticsearch->search(
        index => 'hpcrunner',
        type  => 'submission',
        body  => $search
    );

    my $submit_count = $results->{hits}->{total};
    return $results->{hits}->{hits};
}

1;
