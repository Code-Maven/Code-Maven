package Code::Maven::Source::MetaCPAN;
use Moose;
use 5.010;

use Cwd ();
use Data::Dumper qw(Dumper);
use LWP::Simple ();
use Cpanel::JSON::XS qw(decode_json);
use File::Temp qw(tempdir);

use Code::Maven::DB;

with 'Code::Maven::Role::Collector';

sub get_recent {
	my ($self) = @_;

	my $db  = Code::Maven::DB->new;
	my $col = $db->get_collection('cpan');

	my $n = 100;

	$self->source('cpan');

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
		$self->distribution( $data{distribution} );
		$self->version( $data{version} );

		$data{download_url} =~ s{^https?://[^/]+}{};
		my $ret = $col->find_one(
			{ 'meta.download_url' => $data{download_url} } );
		next DIST if $ret;

		my $other = $col->find_one(
			{
				'meta.distribution' => $data{distribution},
				'meta.version'      => $data{version},
			}
		);
		if ($other) {
			$self->add_event(
				{
					event => 'error',
					blob =>
						"When trying to add distribution from $data{download_url}, we already found this entry from $other->{'meta.download_url'}",
				}
			);
			next DIST;
		}

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

sub download_zipfiles {
	my ($self) = @_;

	my $db            = Code::Maven::DB->new;
	my $col           = $db->get_collection('cpan');
	my $distributions = $col->find( { cm_status => 'added' } );

	my $old_dir = Cwd::getcwd;
	while ( my $d = $distributions->next ) {
		my $dir = tempdir( CLEANUP => 1 );
		chdir $dir;
		$self->download_dist($d);
		chdir $old_dir;
	}
	chdir $old_dir;
	return;
}

sub download_dist {
	my ( $self, $d ) = @_;

	my $db  = Code::Maven::DB->new;
	my $col = $db->get_collection('cpan');

	my $url = 'http://cpan.metacpan.org' . $d->{meta}{download_url};
	( my $zip_file = $url ) =~ s{^.*/}{};
	my $resp = LWP::Simple::getstore( $url, $zip_file );
	if ( $resp != 200 ) {
		$self->add_event(
			{
				event => 'download_failed',
				blob  => "File '$url' response: $resp",
			}
		);
		$col->update(
			{
				'meta.distribution' => $self->distribution,
				'meta.version'      => $self->version,
			},
			{
				'$set' => {
					cm_status => 'error',
					cm_error  => "Download failed. Response: $resp"
				}
			}
		);

		return;
	}

	my $size = -s $zip_file;
	$self->add_event(
		{
			event => 'downloaded',
			blob  => "File '$zip_file' size $size",
		}
	);

	my ( $status, $err ) = $self->unzip($zip_file);
	$self->add_event(
		{
			event => 'file_unzipped',
			blob  => "File '$zip_file'"
				. ( defined $status ? " Status: $status" : '' )
				. ( $err            ? " Error: $err"     : '' ),
		}
	);
	if ($status) {
		$err //= '';
		$col->update(
			{
				'meta.distribution' => $self->distribution,
				'meta.version'      => $self->version,
			},
			{
				'$set' => {
					cm_status => 'error',
					cm_error  => "Unzip error Status: '$status' Err: '$err'",
				}
			}
		);
		return;
	}



	return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

