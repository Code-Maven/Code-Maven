package Code::Maven::MetaCPAN;
use Moose;

use Data::Dumper qw(Dumper);
use LWP::Simple ();
use Cpanel::JSON::XS qw(decode_json);
use Log::Log4perl        ();
use Log::Log4perl::Level ();

use Code::Maven::DB;

with 'Code::Maven::Role::Collector';

sub BUILD {
	my ($self) = @_;

	if ( not Log::Log4perl->initialized() ) {
		Log::Log4perl->easy_init( Log::Log4perl::Level::to_priority('OFF') );
	}
}

sub run {
	my ($self) = @_;

	$self->get_recent;
	$self->download_zipfiles;
}

sub get_recent {
	my ($self) = @_;

	my $db  = Code::Maven::DB->new;
	my $col = $db->get_collection;

	my $n = 10;

#= 'http://api.metacpan.org/v0/release/_search?q=status:latest&sort=date:desc&size='
	my $url
		= 'http://api.metacpan.org/v0/release/_search?sort=date:desc&size='
		. $n;
	my $key = '_source';

	my $logger = Log::Log4perl->get_logger();

	my $json = LWP::Simple::get($url);
	my $data = decode_json $json;

DIST:
	for my $h ( @{ $data->{hits}{hits} } ) {
		my $d = $h->{$key};

		my %data;
		foreach my $f (qw(author distribution status download_url)) {
			$data{$f} = $d->{$f};
		}
		$self->add_event(
			{
				source       => 'cpan',
				distribution => $d->{distribution},
				event        => 'added',
			}
		);
		$logger->debug(
			"DIST: $d->{distribution} by $d->{author} - $d->{status}");

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

sub download_zipfiles {
	my ($self) = @_;

	my $logger = Log::Log4perl->get_logger();

	my $db            = Code::Maven::DB->new;
	my $col           = $db->get_collection;
	my $distributions = $col->find( { cm_status => 'added' } );
	while ( my $d = $distributions->next ) {
		$logger->debug(
			"$d->{metacpan}{distribution}  $d->{metacpan}{download_url}");
	}
	return;
}

1;

