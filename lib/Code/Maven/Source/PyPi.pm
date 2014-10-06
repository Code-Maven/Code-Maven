package Code::Maven::Source::PyPi;
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
	my $col = $db->get_collection('pypi');

	$self->source('pypi');

	my $url = 'https://pypi.python.org/pypi?%3Aaction=rss';

	#die LWP::Simple::get($url);
	my $feed = XML::Feed->parse( URI->new($url) );
	if ( not $feed ) {
		die "Could not fetch feed from '$url' " . XML::Feed->errstr;
	}

	#say $feed->title;
DIST:
	for my $entry ( $feed->entries ) {
		my %data;

		# pyglut 1.0.0
		my $title = $entry->title;

		my $link = $entry->link;

		#http://pypi.python.org/pypi/pyglut/1.0.0
		if ( $link =~ m{http://pypi.python.org/pypi/([^/]+)/([^/]+)$} ) {
			( $data{distribution}, $data{version} ) = ( $1, $2 );
			$self->distribution( $data{distribution} );
			$self->version( $data{version} );
		}
		else {
			# TODO: log error
			return;
		}

# TODO: shall we check if the title contains the same name/version as the link contained?
		my $res = $col->find_one(
			{
				'meta.distribution' => $data{distribution},
				'meta.version'      => $data{version}
			}
		);
		next DIST if $res;

		$col->insert(
			{
				cm_update => DateTime->now,
				cm_status => 'added',
				meta      => \%data,
			}
		);

		$self->add_event(
			{
				event => 'added',
			}
		);
	}

	return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

