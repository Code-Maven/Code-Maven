package Code::Maven::Source::Pear;
use 5.010;
use Moose;

use Data::Dumper qw(Dumper);
use XML::Feed ();

with 'Code::Maven::Role::Collector';

use Code::Maven::DB;

sub get_recent {
	my ($self) = @_;

	my $db  = Code::Maven::DB->new;
	my $col = $db->get_collection('pear');

	$self->source('pear');

	my $url = 'http://pear.php.net/feeds/latest.rss';

	my $feed = XML::Feed->parse( URI->new($url) );
	if ( not $feed ) {
		die "Could not fetch feed from '$url' " . XML::Feed->errstr;
	}

	#say $feed->title;
DIST:
	for my $entry ( $feed->entries ) {
		my %data;

		# PHP_CodeSniffer 2.0.0RC1
		my $title = $entry->title;

		# http://pear.php.net/package/PHP_CodeSniffer/download/2.0.0RC1/
		my $link = $entry->link;
		if ( $link
			=~ m{http://pear.php.net/package/([^/]+)/download/([^/]+)/} )
		{
			( $data{distribution}, $data{version} ) = ( $1, $2 );
			$self->distribution( $data{distribution} );
			$self->version( $data{version} );
		}
		else {
			# TODO: log error
			return;
		}

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

