package HPC::Runner::Command::submit_jobs::Plugin::Logger::Elastic;

use Moose::Role;
use JSON::XS;
use Data::Dumper;
use DateTime;
use Search::Elasticsearch;
use Try::Tiny;

with 'HPC::Runner::Command::Plugin::Logger::Elastic';

=head1 HPC::Runner::Command::submit_jobs::Plugin::Logger::Elastic

=cut

around 'execute' => sub {
    my $orig = shift;
    my $self = shift;

    $self->create_elastic_submission;

    $self->$orig(@_);

    $self->update_elastic_submission;
};

=head3 create_elastic_submission

If there is an elasticsearch create the initial submission - which we then update

=cut

sub create_elastic_submission {
    my $self = shift;

    return unless $self->elasticsearch;

    ##Create initial document
    my $dt = DateTime->now(time_zone => 'local');
    my $doc;
    try {
        $doc = $self->elasticsearch->index(
            index => 'hpcrunner',
            type  => 'submission',
            body  => { submission_time => "$dt" },
        );
    }
    catch {
        $self->app_log->info(
            'HPC::Runner::Command was not able to index the submission! '
              . $! );
        return;
    };

    if ( !$doc || !exists $doc->{_id} ) {
        $self->app_log->warn('There was an error indexing the submissions!');
        return;
    }
    else {
        my $id = $doc->{_id};
        $self->submission_id($id);
    }
}

=head3 update_elastic_submission

Take the initial submission and update it to contain the hpcmeta

=cut

sub update_elastic_submission {
    my $self = shift;

    return unless $self->elasticsearch;

    my $hpc_meta = $self->gen_hpc_meta;

    # $hpc_meta->{batches} = $self->job_stats->batches;
    # my $json_text = encode_json $hpc_meta;
    my $body = {};
    $body->{project} = $self->project if $self->has_project;
    $body->{hpc_meta} = $hpc_meta;

    my $ndoc = $self->elasticsearch->update(
        index => 'hpcrunner',
        type  => 'submission',
        id    => $self->submission_id,
        body  => {
            doc => $body
        }
    );

}

sub gen_hpc_meta {
    my $self = shift;

    my $hpc_meta = {};
    $hpc_meta->{jobs} = [];

    foreach my $job ( $self->all_schedules ) {
        my $job_obj = {};

        #Dependencies
        my $ref       = $self->graph_job_deps->{$job};
        my $depstring = join( ", ", @{$ref} );
        my $count_cmd = $self->jobs->{$job}->cmd_counter;
        my $mem       = $self->jobs->{$job}->mem;
        my $cpus      = $self->jobs->{$job}->cpus_per_task;
        my $walltime  = $self->jobs->{$job}->walltime;

        $job_obj->{job}           = $job;
        $job_obj->{deps}          = $depstring;
        $job_obj->{total_tasks}   = $count_cmd;
        $job_obj->{walltime}      = $walltime;
        $job_obj->{cpus_per_task} = $cpus;
        $job_obj->{mem}           = $mem;

        $job_obj->{schedule} = [];

        for ( my $x = 0 ; $x < $self->jobs->{$job}->{num_job_arrays} ; $x++ ) {
            my $obj = {};

            #index start, index end
            next unless $self->jobs->{$job}->batch_indexes->[$x];

            my $batch_start =
              $self->jobs->{$job}->batch_indexes->[$x]->{'batch_index_start'};
            my $batch_end =
              $self->jobs->{$job}->batch_indexes->[$x]->{'batch_index_end'};
            my $len = ( $batch_end - $batch_start ) + 1;

            my $scheduler_id = $self->jobs->{$job}->scheduler_ids->[$x] || '0';
            $obj->{task_indices} = "$batch_start-$batch_end";
            $obj->{total_tasks}  = $len;
            $obj->{scheduler_id} = $scheduler_id;

            push( @{ $job_obj->{schedule} }, $obj );
        }

        # $hpc_meta->{jobs}->{$job} = $job_obj;
        push( @{ $hpc_meta->{jobs} }, $job_obj );
    }

    return $hpc_meta;
}

around 'create_plugin_str' => sub {
    my $orig = shift;
    my $self = shift;

    ##Check to make sure there is a submission id
    if ( $self->submission_id ) {
        $self->job_plugins( [] ) unless $self->job_plugins;
        $self->job_plugins_opts( {} ) unless $self->job_plugins_opts;

        push( @{ $self->job_plugins }, 'Logger::Elastic' );
        $self->job_plugins_opts->{submission_id} = $self->submission_id;
    }
    my $val = $self->$orig(@_);

    return $val;
};

1;
