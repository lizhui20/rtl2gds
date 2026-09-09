#!/bin/perl

open(MAKEFILE, "Makefile")||die "\n$SCRIPTS ERROR: Can not open Makefile!\n";
@make_content = <MAKEFILE>;
chomp(@make_content);
close MAKEFILE;

foreach $make_line (@make_content) {
     	if (($make_line =~/^@/)) {next;}
	if ($make_line =~/^\w+\s*:(?!=)/) {
		@make_words = split("\s*:\s*", $make_line);
		$target = $make_words[0];$target =~s/ //g;
		$depend = $make_words[1];$depend =~s/ //g;
		if (system ("gmake -f Makefile -n -q $target") == 0) {
			$status = " -";
		        $time_stamp_file = `cat $target`;
		        @time_stamp_list = split (/\n/, $time_stamp_file);
			$time_stamp = "\[Finished\] @time_stamp_list[0] - @time_stamp_list[1]";
		} elsif (-e "$target") {
			$status = " -";
		        $time_stamp = "\[NeedRunAgain\]";
		} else {
			$status = " -";
			$time_stamp = "";
		}
		chomp($time_stamp);
		print "$status $target";
                $sl=length($target);
                for($i=0;$i< 20 -$sl;$i=$i+1) {
                    print " ";
                }
		print "\t$time_stamp\n";
	}

}

exit;
