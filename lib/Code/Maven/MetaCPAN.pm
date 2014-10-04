package Code::Maven::MetaCPAN;
use Moose;
use 5.010;

use Cwd ();
use Data::Dumper qw(Dumper);
use LWP::Simple ();
use Cpanel::JSON::XS qw(decode_json);
use File::Temp qw(tempdir);

use Code::Maven::DB;

with 'Code::Maven::Role::Collector';

sub run {
	my ($self) = @_;

	$self->get_recent if $self->fetch;
	$self->download_zipfiles if $self->zip;
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

	my $old_dir = Cwd::getcwd;
	while ( my $d = $distributions->next ) {
		my $dir = tempdir( CLEANUP => 1 );
		chdir $dir;
		$self->download_dist($d);
		chdir $old_dir;
		#say 'Press ENTER to continue';
		#<STDIN>;
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
	say $url;
	say $zip_file;
	my $resp = LWP::Simple::getstore( $url, $zip_file );
	if ( $resp != 200 ) {
		$self->add_event(
			{
				source       => 'cpan',
				distribution => $d->{meta}{distribution},
				event        => 'download_failed',
				blob         => "File '$url' response: $resp",
			}
		);
		$col->update(
			{ 'meta.download_url' => $d->{meta}{download_url} },
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
			source       => 'cpan',
			distribution => $d->{meta}{distribution},
			event        => 'downloaded',
			blob         => "File '$zip_file' size $size",
		}
	);

	say "unzipping $zip_file";
	my ( $status, $err ) = $self->unzip($zip_file);
	if ($status) {
		say $status;
		if ($err) {
			say $err;
		}
	}
	$self->add_event(
		{
			source       => 'cpan',
			distribution => $d->{meta}{distribution},
			event        => 'file_unzipped',
			blob         => "File '$zip_file' status: "
				. ( defined $status ? $status       : '' )
				. ( $err            ? "Error: $err" : '' ),
		}
	);

	return;
}

no Moose;
__PACKAGE__->meta->make_immutable;

