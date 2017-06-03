package HPC::Runner::Command::execute_job::Plugin::Logger::Elastic;

use Moose::Role;
use Data::Dumper;
use DateTime;
use JSON;

with 'HPC::Runner::Command::Plugin::Logger::Elastic';

##TODO Create Logger base class

=head1 HPC::Runner::Command::execute_job::Plugin::Logger::Elastic;

=cut

=head2 Attributes

=cut

=head2 Subroutines

=cut

around 'start_command_log' => sub {
    my $orig   = shift;
    my $self   = shift;
    my $cmdpid = shift;

    my $job_meta = {};

    if ( $self->metastr ) {
        $job_meta = decode_json( $self->metastr );
    }

    if ( !exists $job_meta->{jobname} ) {
        $job_meta->{jobname} = 'undefined';
    }

    my $task_obj = {
        submission_id => $self->submission_id,
        pid           => $cmdpid,
        start_time    => reformat_time( $self->table_data->{start_time} ),
        jobname       => $job_meta->{jobname},
        job_meta      => $job_meta,
    };

    if ( $self->can('task_id') ) {
        $task_obj->{task_id} = $self->task_id;
    }
    if ( $self->job_scheduler_id ) {
        $task_obj->{scheduler_id} = $self->job_scheduler_id;
    }

    my $doc = $self->elasticsearch->index(
        index => 'hpcrunner',
        type  => 'task',
        body  => $task_obj,
    );

    ##TODO error checking ... so much error checking
    $self->table_data->{doc_id} = $doc->{_id};

    $self->$orig($cmdpid);
};

around 'log_table' => sub {
    my $orig = shift;
    my $self = shift;

    $self->$orig(@_);

    my $tags = "";
    if ( exists $self->table_data->{task_tags} ) {
        my $task_tags = $self->table_data->{task_tags};
        if ($task_tags) {
            $tags = $task_tags;
        }
    }

    my $started_task = $self->elasticsearch->get(
        index => 'hpcrunner',
        type  => 'task',
        id    => $self->table_data->{doc_id}
    );

    $self->app_log->info( 'Started task ' . Dumper($started_task) );

    my $updated_task = $self->elasticsearch->update(
        index => 'hpcrunner',
        type  => 'task',
        id    => $started_task->{_id},
        body  => {
            doc => {
                exit_time => reformat_time( $self->table_data->{exit_time} ),
                duration  => $self->table_data->{duration},
                exit_code => $self->table_data->{exitcode},
                task_tags => $tags,
            }
        }
    );

    my $final_task = $self->elasticsearch->get(
        index => 'hpcrunner',
        type  => 'task',
        id    => $self->table_data->{doc_id}
    );
    $self->app_log->info( 'Updated task! ' . Dumper($final_task) );
};

##Make elasticsearch time format happy
sub reformat_time {
    my $time = shift;

    my @dt = split( ' ', $time );
    return $dt[0] . 'T' . $dt[1];
}

1;
