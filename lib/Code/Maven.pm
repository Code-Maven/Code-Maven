package Code::Maven;
use Moose;

our $VERSION = '0.01';

=head1 NAME

Code::Maven - analyze and display source code

=head1 DESCRIPTION

=head1 PLANS

Downloading and processing from various sources. Each release (each zip file) will
be represented in a single document in MongoDB. 
In that document we maintain a field called C<cm_update> that will hold the timestamp of when the
document was last updated.

We also maintaine a field called C<cm_status> that will indicate the current stage of the processing.
If we successfully finished processing, or arived to a stage where we cannot proceed. (e.g. we cannot
unzip the zip file), then we set this field to be 'done'.

There is also a third field called C<cm_error> that will hold the type of error we have seen.

<cm_log> is a field that will contain log messages specific to release.

=head2 Logging

The public should be able to see what's going on on the server. Focusing on the whole
server, on a specific release, or anything in between.

=head2 CPAN

When fetching from MetaCPAN the list of most recently uploaded distributions we
put the information in the database with a cm_state=added.

A separate process will run and try to download the zip file of the entry with th oldest cm_update.
(we might need to have a minimum age for these to make sure the zip files are on the server.)
If successful, the cm_state=downloaded
If cannot download the cm_state=done and cm_error=could_not_unzip

The same process will then go on and try to unzip the file, set cm_state=unzipped if successful
analyze the distribution (similar to what CPANTS does for CPAN modules),
and process each file that was in the zip file.
After unzip finished (either way) we can delete the zip file.
When processing, we can delete all the files we don't recognize.
We can also skip processing and delete files that are bigger than N. At lest at the beginning as
we might need to save space.


=head1 CONFIGURATION

The configuration files of the live server can be found in a private Git repository
called Code-Maven-Live. It has a config/ directory with several files in it.

C<config.yml> is required and has the following fields:

C<google_analytics.txt> optional and contains the code Google Analytics provides
that will be included in the web pages.

On the live server there is a symbolic link from the root directory of this repository
to the config directory of the other  repository.

    ln -s ../Code-Maven-Live/config/

=cut

1;

