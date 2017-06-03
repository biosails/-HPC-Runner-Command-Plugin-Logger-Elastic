package HPC::Runner::Command::stats::Plugin::Logger::Elastic::Summary;

use Moose::Role;

use Data::Dumper;
use Log::Log4perl qw(:easy);
use JSON;
use Text::ASCIITable;

sub iter_jobs_summary {
    my $self       = shift;
    my $submission = shift;
    my $jobref     = shift;

    my $submission_id = $submission->{_id};
    my $table         = $self->build_table($submission);
    $table->setCols(
        [ 'JobName', 'Complete', 'Running', 'Success', 'Fail', 'Total' ] );

    foreach my $job ( @{$jobref} ) {
        my $jobname = $job->{job};
        if ( $self->jobname ) {
            next unless $self->jobname eq $jobname;
        }
        my $total_tasks = $job->{total_tasks};


        $self->iter_tasks_summary( $submission_id, $jobname );
        $self->task_data->{$jobname}->{total} = $total_tasks;

        $table->addRow(
            [
                $jobname,
                $self->task_data->{$jobname}->{complete},
                $self->task_data->{$jobname}->{running},
                $self->task_data->{$jobname}->{success},
                $self->task_data->{$jobname}->{fail},
                $self->task_data->{$jobname}->{total},
            ]
        );
        $self->task_data( {} );
    }

    print $table;
    print "\n";
}

sub iter_tasks_summary {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;

    my $running = $self->count_running_tasks( $submission_id, $jobname );
    my $success = $self->count_successful_tasks( $submission_id, $jobname );
    my $fail = $self->count_failed_tasks( $submission_id, $jobname );
    my $complete = $success + $fail;

    $self->task_data->{$jobname} = {
        complete => $complete,
        success  => $success,
        fail     => $fail,
        running  => $running
    };
}
sub count_running_tasks {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;

    my $results = $self->elasticsearch->count(
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
                    ],
                    must_not => {
                        exists => {
                            field => 'exit_code',
                        }
                    }
                }
            }
        }
    );

    return $results->{count};
}

sub count_successful_tasks {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;

    my $results = $self->elasticsearch->count(
        index => 'hpcrunner',
        type  => 'task',
        body  => {
            query => {
                bool => {
                    must => [
                        {
                            match => { submission_id => $submission_id }
                        },
                        { match => { jobname   => $jobname }, },
                        { match => { exit_code => 0 }, }
                    ],
                }
            }
        }
    );

    return $results->{count};
}

sub count_failed_tasks {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;

    my $results = $self->elasticsearch->count(
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
                    ],
                    must_not => {
                        match => {
                            exit_code => 0,
                        }
                    }
                }
            }
        }
    );

    return $results->{count};
}



1;
