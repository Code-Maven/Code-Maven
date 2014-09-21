package Code::Maven::PyPi;
use 5.010;
use Moose;

use Data::Dumper qw(Dumper);
use LWP::Simple ();
use XML::Feed   ();

with 'Code::Maven::Role::Collector';

use Code::Maven::DB;

sub get_recent {
	my ($self) = @_;

	my $db  = Code::Maven::DB->new;
	my $col = $db->get_pypi;

	my $url = 'https://pypi.python.org/pypi?%3Aaction=rss';

	#die LWP::Simple::get($url);
	my $feed = XML::Feed->parse( URI->new($url) );

	#say $feed->title;
	for my $entry ( $feed->entries ) {
		my %data;

		# pyglut 1.0.0
		my $title = $entry->title;

		my $link = $entry->link;

		#http://pypi.python.org/pypi/pyglut/1.0.0
		if ( $link =~ m{http://pypi.python.org/pypi/([^/]+)/([^/]+)$} ) {
			( $data{distribution}, $data{version} ) = ( $1, $2 );
		}
		else {
			# TODO: log error
			return;
		}

# TODO: shall we check if the title contains the same name/version as the link contained?

		#my $description = $entry->description;
		#my $date = $entry->pubDate;
		#say $title;
		#say $link;
		#say $description;
		#say $date;
		#say '';

		$self->add_event(
			{
				source       => 'pypi',
				distribution => $data{distribution},
				event        => 'added',
			}
		);

		$col->insert(
			{
				cm_update => DateTime->now,
				cm_status => 'added',
				metacpan  => \%data,
			}
		);
	}

	return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

