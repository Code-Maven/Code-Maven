package Code::Maven::Config;
use MooseX::Singleton;

has root => (
	is       => 'ro',
	required => 1,
);


no Moose;
__PACKAGE__->meta->make_immutable;

