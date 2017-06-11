#!/usr/bin/env bash

export PERL5LIB="/home/jillian/Dropbox/projects/HPC-Runner-Libs/New/HPC-Runner-Command-Plugin-Logger-Elastic/lib:/home/jillian/Dropbox/projects/HPC-Runner-Libs/New/HPC-Runner-Command-Utils-ManyConfigs/lib:/home/jillian/Dropbox/projects/HPC-Runner-Libs/New/HPC-Runner-Command-Plugin-Blog/lib:/home/jillian/Dropbox/projects/HPC-Runner-Libs/New/HPC-Runner-Command-Plugin-Logger-Sqlite/lib:/home/jillian/Dropbox/projects/HPC-Runner-Libs/New/HPC-Runner-Command/lib"

inotify-hookable \
    --watch-directories lib \
    --watch-directories t/lib/TestsFor/ \
    --watch-files t/test_class_tests.t \
    --on-modify-command "prove -v t/test_class_tests.t"
