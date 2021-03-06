use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
	NAME          => 'Code::Maven',
	VERSION_FROM  => 'lib/Code/Maven.pm',
	ABSTRACT_FROM => 'lib/Code/Maven.pm',
	PREREQ_PM     => {
		#'Log::Log4perl'              => '1.44',
		'autodie'                    => '0',
		'Cpanel::JSON::XS'           => '3.0104',
		'LWP::Simple'                => '6.00',
		'LWP::Protocol::https'       => '6.06',
		'DateTime'                   => '1.12',
		'Template'                   => '2.25',

		'Archive::Any'               => '0.0941',
		'Archive::Zip'               => '1.38',
		'Archive::Tar'               => '2.02',

		'Parse::Functions'           => '0.01',
		'PPIx::EditorTools::Outline' => '0.18',
		'Moose'                      => '2.1211',
		'MooseX::Singleton'          => '0.29',

		'XML::Feed'                  => '0.52',
		'Web::Feed'                  => '0.03',

		'YAML'                       => '1.11',
		'Path::Tiny'                 => '0.056',
		'Plack'                      => '1.0031',
		'HTTP::Request::Common'      => '6.04',
		'MongoDB'                    => '0',
	},
);

if (eval { ExtUtils::MakeMaker->VERSION(6.3002) }) {
	$conf{LICENSE} = 'perl';
}

if (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
	$conf{META_MERGE} = {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'http://github.com/Code-Maven/Code-Maven.git',
				web  => 'http://github.com/Code-Maven/Code-Maven',
			}
		}
	};
}

my %configure_requires = (
        'ExtUtils::MakeMaker' => '6.64',
);
my %build_requires = ();
my %test_requires = (
		'Test::More'      => '1.00',
		'Capture::Tiny'   => '0.25',
		#'Test::Exception' => '0.32',
		'Perl::Tidy'             => '20140711',  # Apparently Test::Code::TidyAll does not explicitly depend on it
		'Test::Code::TidyAll'    => 0.20,
		'Test::Perl::Critic'     => 0,

		# standard modules:
		#'File::Temp' => 0,
);

###   merging data "standard code"
if (eval { ExtUtils::MakeMaker->VERSION(6.52) }) {
	$conf{CONFIGURE_REQUIRES} = \%configure_requires;
} else {
	%{ $conf{PREREQ_PM} } = (%{ $conf{PREREQ_PM} }, %configure_requires);
}

if (eval { ExtUtils::MakeMaker->VERSION(6.5503) }) {
	$conf{BUILD_REQUIRES} = \%build_requires;
} else {
	%{ $conf{PREREQ_PM} } = (%{ $conf{PREREQ_PM} }, %build_requires);
}
if (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
	$conf{TEST_REQUIRES} = \%test_requires;
} else {
	%{ $conf{PREREQ_PM} } = (%{ $conf{PREREQ_PM} }, %test_requires);
}
WriteMakefile(%conf);

