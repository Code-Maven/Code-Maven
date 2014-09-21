package Code::Maven::MetaCPAN;
use Moose;
use 5.010;

use Data::Dumper qw(Dumper);
use LWP::Simple ();
use Cpanel::JSON::XS qw(decode_json);

use Code::Maven::DB;

with 'Code::Maven::Role::Collector';

sub run {
	my ($self) = @_;

	$self->get_recent;
	$self->download_zipfiles;
}

sub get_recent {
	my ($self) = @_;

	my $db  = Code::Maven::DB->new;
	my $col = $db->get_collection('cpan');

	my $n = 100;

#= 'http://api.metacpan.org/v0/release/_search?q=status:latest&sort=date:desc&size='
	my $url
		= 'http://api.metacpan.org/v0/release/_search?sort=date:desc&size='
		. $n;
	my $key = '_source';

	my $json = LWP::Simple::get($url);
	my $data = decode_json $json;

DIST:
	for my $h ( @{ $data->{hits}{hits} } ) {
		my $d = $h->{$key};

		my %data;
		foreach my $f (qw(author distribution status download_url version)) {
			$data{$f} = $d->{$f};
		}
		$data{download_url} =~ s{^https?://[^/]+}{};
		my $ret = $col->find_one(
			{ 'meta.download_url' => $data{download_url} } );
		if ( not $ret ) {
			$col->insert(
				{
					cm_update => DateTime->now,
					cm_status => 'added',
					meta      => \%data,
				}
			);
			$self->add_event(
				{
					source       => 'cpan',
					distribution => $d->{distribution},
					event        => 'added',
				}
			);
		}
	}

	return;
}

sub download_zipfiles {
	my ($self) = @_;

	my $db            = Code::Maven::DB->new;
	my $col           = $db->get_collection('cpan');
	my $distributions = $col->find( { cm_status => 'added' } );

	#while ( my $d = $distributions->next ) {
	#}
	return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

