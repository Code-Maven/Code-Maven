package Code::Maven::RubyGems;
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
}

sub get_recent {
	my ($self) = @_;

	my $db  = Code::Maven::DB->new;
	my $col = $db->get_collection('gems');

	my $n = 10;

	my $url = 'https://rubygems.org/api/v1/activity/just_updated.json';

	my $json = LWP::Simple::get($url);
	my $data = decode_json $json;

DIST:
	for my $d (@$data) {
		my %data;
		foreach my $f (qw(version gem_uri project_uri)) {
			$data{$f} = $d->{$f};
		}

		$data{distribution} = $d->{name};
		$self->add_event(
			{
				source       => 'gems',
				distribution => $d->{name},
				event        => 'added',
			}
		);

		$col->insert(
			{
				cm_update => DateTime->now,
				cm_status => 'added',
				meta      => \%data,
			}
		);
	}

	return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

=head1 NAME

Code::Maven::RubyGems - collecting information about Ruby Gems

=head1 DESCRIPTION

L<http://guides.rubygems.org/rubygems-org-api/>

=cut

