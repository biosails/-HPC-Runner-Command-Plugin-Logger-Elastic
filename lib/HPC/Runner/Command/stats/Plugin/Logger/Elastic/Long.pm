package HPC::Runner::Command::stats::Plugin::Logger::Elastic::Long;

use Moose::Role;

use Data::Dumper;
use Log::Log4perl qw(:easy);
use JSON;
use Text::ASCIITable;

sub iter_jobs_long {
    my $self       = shift;
    my $submission = shift;
    my $jobref     = shift;

    my $submission_id = $submission->{_id};
    my $table         = $self->build_table($submission);

    $table->setCols(
        [
            'Jobname',
            'Task Tags',
            'Start Time',
            'End Time',
            'Duration',
            'Exit Code'
        ]
    );

    foreach my $job ( @{$jobref} ) {
        my $jobname = $job->{job};

        # $table->addRow([$jobname]);
        # $table->addRowLine;

        if ( $self->jobname ) {
            next unless $self->jobname eq $jobname;
        }
        my $total_tasks = $job->{total_tasks};

        my $tasks = $self->get_tasks( $submission_id, $jobname );
        $self->iter_tasks_long( $jobname, $tasks, $table );

        $self->task_data( {} );
    }

    print $table;
    print "\n";
}

sub iter_tasks_long {
    my $self    = shift;
    my $jobname = shift;
    my $tasks   = shift;
    my $table   = shift;

    foreach my $task ( @{$tasks} ) {

        my $task_tags  = $task->{_source}->{task_tags}  || '';
        my $start_time = $task->{_source}->{start_time} || '';
        my $end_time   = $task->{_source}->{exit_time}  || '';
        my $exit_code  = $task->{_source}->{exit_code}  || '';
        my $duration   = $task->{_source}->{duration}   || '';

        $table->addRow(
            [
                $jobname,  $task_tags, $start_time,
                $end_time, $duration,  $exit_code,
            ]
        );

    }
}

##TODO Move this to long view
sub get_tasks {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;

    my $results = $self->elasticsearch->search(
        index => 'hpcrunner',
        type  => 'task',
        body  => {
            query => {
                bool => {
                    must => [
                        {
                            match => { submission_id => $submission_id }
                        },
                        { match => { jobname => $jobname }, }
                    ]
                }
            }
        }
    );

    return $results->{hits}->{hits};
}

1;
