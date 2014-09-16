package Code::Maven::DB;
use Moose;
use MongoDB;

has dbname => ( is => 'ro', required => 1 );
has host   => ( is => 'ro', default  => 'localhost' );
has port   => ( is => 'ro', default  => 27017 );

sub get_collection {
	my ($self) = @_;

	my $client = MongoDB::MongoClient->new(
		host => $self->host,
		port => $self->port
	);
	my $database = $client->get_database( $self->dbname );

	#$database->drop;
	my $collection = $database->get_collection('cpan');
}

1;

