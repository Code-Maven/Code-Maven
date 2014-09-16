package Code::Maven::MetaCPAN;
use Moose;

use LWP::Simple ();
use Cpanel::JSON::XS qw(decode_json);
use Log::Log4perl        ();
use Log::Log4perl::Level ();

sub BUILD {
	my ($self) = @_;

	if ( not Log::Log4perl->initialized() ) {
		Log::Log4perl->easy_init( Log::Log4perl::Level::to_priority('OFF') );
	}
}

sub run {
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
		my $author       = $h->{$key}{author};
		my $distribution = $h->{$key}{distribution};
		my $status       = $h->{$key}{status};
		$logger->debug("DIST: $distribution by $author - $status");
	}

	return;
}

1;

