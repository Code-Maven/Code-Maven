package Code::Maven::Config;
use MooseX::Singleton;
use YAML qw(LoadFile);

has root => (
	is       => 'rw',
	required => 1,
);

has cfg => (
	is       => 'ro',
	required => 1,
);

around BUILDARGS => sub {
	my ( $orig, $class, %args ) = @_;

	die q{'root' is missing} if not $args{root};
	my $config_file = "$args{root}/config/config.yml";
	die "config file '$config_file' is missing" if not -e $config_file;
	eval {
		$args{cfg} = LoadFile($config_file);
		1;
	} or do {
		my $err = $@ // 'Unknown error';
		die "Error while trying to load the YAML file '$config_file':\n$err";
	};
	return $class->$orig(%args);
};

no Moose;
__PACKAGE__->meta->make_immutable;

