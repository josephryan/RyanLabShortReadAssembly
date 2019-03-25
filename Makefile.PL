use ExtUtils::MakeMaker;

WriteMakefile(NAME      => 'remove_short_and_sort',
              AUTHOR    => 'Joseph Ryan <joseph.ryan@whitney.ufl.edu',
              VERSION_FROM  => 'remove_short_and_sort',
              PREREQ_PM => { 'JFR::Fasta' => '1.04' },
EXE_FILES => ['remove_short_and_sort','plat.pl']);
