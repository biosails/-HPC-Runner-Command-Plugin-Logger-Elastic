### submission\_id

This is the ID for the entire hpcrunner.pl submit\_jobs submission, not the individual scheduler IDs

### nodes

### elasticsearch

elastic search connection object

# NAME

HPC::Runner::Command::Plugin::Logger::Elastic - Log HPC::Runner::Command metadata to elasticsearch

# SYNOPSIS

On the command line

    hpcrunner.pl submit_jobs --infile my_submission_file.in --plugins Logger::Elastic

On the command line with elastic nodes specified

    hpcrunner.pl submit_jobs --infile my_submission_file.in --plugins Logger::Elastic --plugin_opts nodes='http://localhost:9200'

In a configuration file (.hpcrunner.yml)

    global:
      plugins:
        - 'Logger::Elastic'

# DESCRIPTION

HPC::Runner::Command::Plugin::Logger::Elastic is a plugin that hooks into the
HPC::Runner::Command libraries, and adds elasticsearch logging capabilities.

This is still a very beta release.

# ABSTRACT

Log HPC::Runner::Command meta to elastic search.

# AUTHOR

Jillian Rowe <jillian.e.rowe@gmail.com>

# COPYRIGHT

Copyright 2017- Jillian Rowe

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
