#!perl -T

use warnings;
use strict;

use Test::More;

if ( eval 'use Test::Pod 1.14; 1;' ) {
    all_pod_files_ok();
}
else {
    plan skip_all => 'Test::Pod 1.14 required for testing POD';
}
