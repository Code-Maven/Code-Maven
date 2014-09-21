package Code::Maven::Role::Collector;
use Moose::Role;

use Code::Maven::DB;

sub add_event {
	my ( $self, $data ) = @_;

	my $db  = Code::Maven::DB->new;
	my $col = $db->get_eventlog;
	$col->insert($data);

	return;
}

1;

