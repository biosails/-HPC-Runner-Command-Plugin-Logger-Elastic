package TestsFor::HPC::Runner::Command::Plugin::Logger::Elastic::Test001;

use Test::Class::Moose;
use HPC::Runner::Command;
use Cwd;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use IPC::Cmd qw[can_run];
use Data::Dumper;
use Capture::Tiny ':all';
use Slurp;
use File::Slurp;

extends 'TestMethods::Base';

sub test_000 : Tags(require) {
    my $self = shift;

    diag("In Test001");

    require_ok('HPC::Runner::Command');
    require_ok('HPC::Runner::Command::stats::Plugin::Logger::Elastic::Long');
    require_ok('HPC::Runner::Command::stats::Plugin::Logger::Elastic::Summary');
    require_ok('HPC::Runner::Command::Plugin::Logger::Elastic');
    require_ok('HPC::Runner::Command::execute_job::Plugin::Logger::Elastic');
    require_ok('HPC::Runner::Command::execute_array::Plugin::Logger::Elastic');
    require_ok('HPC::Runner::Command::submit_jobs::Plugin::Logger::Elastic');
    require_ok('HPC::Runner::Command::elastic_stats');
    ok(1);
}

1;
