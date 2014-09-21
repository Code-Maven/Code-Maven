package Code::Maven::DB;
use Moose;
use MongoDB;

has dbname => ( is => 'ro', required => 1 );
has host   => ( is => 'ro', required => 1 );
has port   => ( is => 'ro', required => 1 );

around BUILDARGS => sub {
	my ( $orig, $class, %args ) = @_;

	my $cfg = Code::Maven::Config->instance;
	%args = ( %{ $cfg->{cfg}{db} }, %args );

	return $class->$orig(%args);
};

sub get_db {
	my ($self) = @_;

	my $client = MongoDB::MongoClient->new(
		host => $self->host,
		port => $self->port
	);
	return $client->get_database( $self->dbname );
}

sub get_eventlog {
	my ($self) = @_;

	my $database = $self->get_db;

	my $collection = $database->get_collection('events');
}

sub get_collection {
	my ( $self, $name ) = @_;

	my $database = $self->get_db;

	my $collection = $database->get_collection($name);
}

sub clean_collection {
	my ( $self, $name ) = @_;

	my $collection = $self->get_collection($name);
	$collection->drop;
}

#$database->drop;

1;

