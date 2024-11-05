#!/usr/bin/perl
#######################################################################
# bomblab-update.pl - The CS:APP Bomb Lab Web updater
#
# Copyright (c) 2003-2016, R. Bryant and D. O'Hallaron, All rights reserved.
#
#######################################################################

use strict 'vars';
use Getopt::Std;
use Fcntl qw(:DEFAULT :flock);
use Cwd;

use lib ".";
use Bomblab;

# 
# Generic settings
#
$| = 1;      # Autoflush output on every print statement

##############
# Main routine
##############

my %RESULTS = ();
my %HIST = ();

my $linenum;
my $line;
my $i;
my $k;
my $bombcount;
my $bombid;
my $userid;
my $numdefused;
my $numexplosions;
my $bombdir;
my $bombfile;
my $valid;
my $totaldefused;
my $comment;
my $headerhtml;
my $defusedate;

my $bf = "<font size=-1>";
my $ef = "</font>";

my $score;
my @studentsol;

# Configure the updating script
my $bombsdir = $Bomblab::BOMBDIR;
my $logfile = $Bomblab::LOGFILE;
my $webpage = $Bomblab::SCOREBOARDPAGE;
my $tmpwebpage = "tmpwebpage.$$";
my $gradefile = $Bomblab::SCOREFILE;
my $explosion_penalty = $Bomblab::EXPLOSION_PENALTY;
my $do_validate = 1;
my $lab = "bomblab";
my $verbose = 0;
my $student_ID;

#
# Remove any leftover temp files 
#
system("rm -f tmp-solution.*") == 0
    or log_msg("Unable to remove temp files");

#读取学生名单CSV并返回哈希表
use Text::CSV;
sub load_student_info {
    my $filename = 'name_list.csv'; # 假设CSV文件名为name_list.csv
    my %students = ();  # 初始化一个空的哈希表，用于存储学生信息
    my $csv = Text::CSV->new({ binary => 1 });  # 创建一个新的Text::CSV对象，支持二进制模式
    open my $fh, '<', $filename or die "Cannot open $filename: $!";  # 打开CSV文件，如果失败则显示错误信息
    # 逐行读取CSV文件内容
    while (my $row = $csv->getline($fh)) {
        my ($student_id, $student_name, $teacher_name, $class_id) = @$row;  # 将每一行数据解构为学生ID、学生姓名、教师姓名和班级ID
        # 将学生ID作为键，存储学生的姓名、教师和班级信息到哈希表中
        $students{$student_id} = {
            name => $student_name,
            teacher => $teacher_name,
            class => $class_id,
            bombID => -1
        };
    }
    close $fh;  # 关闭文件句柄
    return %students;  # 返回存有学生信息的哈希表
}
# 在主代码中加载学生信息
my %STUDENT_INFO = load_student_info();  # 调用子程序，加载学生信息到%STUDENT_INFO变量中

# Scan the log file and store a complete record for each bomb in the
# RESULTS hash.
#
%RESULTS = read_logfile($logfile);

#
# Open the temporary output Web page
# 

open(WEB, ">:encoding(UTF-8)",$tmpwebpage)
    or log_die("Unable to open $tmpwebpage: $!");
    
use open ':std',':encoding(UTF-8)';

# Initialize some statistics variables
$bombcount = 0;                         
for ($i=0; $i <= $Bomblab::NUMPHASES+1; $i++) {  
    $HIST{$i} = 0;
}

#
# Validate and print a Web page entry for each bomb
#
# ngm
# Old method was to sort by numdefused, then numexploded, then bombid
# New method is  to sort by numdefused, then numexploded, 
# then time defused, then bombid
#
# Results{}[0] contains userid
# Results{}[1] unused
# Results{}[2] contains number of phases defused.
# Results{}[3] contains number of explosions so far.
# Results{}[4] contains time of last phase pass.
#
print_webpage_header();
foreach $student_ID (sort{$a<=>$b}keys %STUDENT_INFO)
{

    $bombid = $STUDENT_INFO{$student_ID}->{bombID};
    if ($verbose) {
        print "Bomb$bombid...";
    }

    if ($bombid eq "") {
        next;
    }
    
    my $student_info = $STUDENT_INFO{$student_ID} || {name => 'Unknown', class => 'Unknown', teacher => 'Unknown' };
    
    if ($bombid eq "-1") {
        print WEB "<tr data-class=\"$student_info->{class}\" data-teacher=\"$student_info->{teacher}\" bgcolor=$Bomblab::LIGHT_GREY align=center>\n";
        print WEB "<td align=center>$bf 0</td>\n"; 
        print WEB "<td align=left> $bf bomb$bombid $ef</td>";  # bomb number 
        print WEB "<td align=left>$bf NoRecords$ef </td>\n"; # defusion date
        
        # Report the score based on the largest validated defused phase
        
        print WEB "<td align=center> $bf 0 $ef</td>";   # defused
        print WEB "<td align=center> $bf 0 $ef</td>";   # exploded
        print WEB "<td align=center> $bf 0 $ef</td>";   # lab score
        print WEB "<td align=center> $bf $student_ID $ef </td>\n";  # valid/invalid
        print WEB "<td align=center> $bf $student_info->{name} $ef </td>\n";
        print WEB "<td align=center> $bf $student_info->{class} $ef </td>\n";
        print WEB "<td align=center> $bf $student_info->{teacher} $ef </td>\n";
        print WEB "</tr>\n";
        
        # Terminate the status line in verbose mode
        
        if ($verbose) {
            print "\n";
        }
        next;
    }
    
    my $student_id = $RESULTS{$bombid}[0];
 
    #
    # Extract the results for this bomb from the results hash
    #
    $numdefused = $RESULTS{$bombid}[2];
    $numexplosions = $RESULTS{$bombid}[3];
    $defusedate = short_date($RESULTS{$bombid}[4]);

    #
    # Make sure all the input files we need exist and are accessible
    # Notice that we're validating with the quiet (non-notifying version) 
    # of each bomb.
    # 
    $bombdir = "$bombsdir/bomb$bombid";
    $bombfile = "$bombdir/bomb-quiet";
    unless (-d $bombdir) {
        log_msg("Couldn't find bomb directory $bombdir");
        next;
    }
    unless (-x $bombfile) {
        log_msg("Couldn't execute $bombfile");
        next;
    }

    # 
    # Copy the defusing strings to a separate array for convenience
    #
    for ($i = 1; $i <= $numdefused; $i++) {
        $studentsol[$i-1] = $RESULTS{$bombid}[$i+4];
    }

    #
    # Validate the solutions that the student claims have defused the bomb
    #
    $valid = validate($numdefused, $bombfile);

    # If the solution is invalid, then only give credit for the valid
    # phases before the smallest numbered invalid phase.  

    if (!$valid) {

        # Find the first invalid phase
        $valid = 1;
        $k = 0;
        do {
            $valid = validate(++$k, $bombfile);
        } until !$valid or $k > $numdefused;

        # Set the number of valid defused phases for this bomb
        $RESULTS{$bombid}[2] = $k-1;
        $numdefused = $k-1;

    }

    # Update some statistics
    $bombcount++;
    $HIST{$numdefused}++;
    if ($valid and $numdefused >= $Bomblab::NUMPHASES) {
        $totaldefused++;
    }


    # Compute the score for this bomb
    $score = bomb_score($numdefused, $numexplosions);

    #
    # Add a table row to the Web page for this bomb
    #
    if ($valid) {
        $comment = "valid";
    }
    else {
        my $invalid_phase = $numdefused+1;
        $comment = "<font color=ff0000><b>invalid phase $invalid_phase</b></font>";
    }
    
    print WEB "<tr data-class=\"$student_info->{class}\" data-teacher=\"$student_info->{teacher}\" bgcolor=$Bomblab::LIGHT_GREY align=center>\n";
    print WEB "<td align=center>$bf $bombcount</td>\n"; 
    print WEB "<td align=left> $bf bomb$bombid $ef</td>";  # bomb number 
    print WEB "<td align=left>$bf $defusedate$ef </td>\n"; # defusion date

    # Report the score based on the largest validated defused phase
    print WEB "<td align=center> $bf $RESULTS{$bombid}[2] $ef</td>";   # defused
    print WEB "<td align=center> $bf $RESULTS{$bombid}[3] $ef</td>";   # exploded
    print WEB "<td align=center> $bf $score $ef</td>";   # lab score
    print WEB "<td align=center> $bf $student_id $ef </td>\n";  # valid/invalid
    print WEB "<td align=center> $bf $student_info->{name} $ef </td>\n";
    print WEB "<td align=center> $bf $student_info->{class} $ef </td>\n";
    print WEB "<td align=center> $bf $student_info->{teacher} $ef </td>\n";
    print WEB "</tr>\n";

    # Terminate the status line in verbose mode
    if ($verbose) {
        print "\n";
    }

} #end iteration over each bombid

#
# Print the page epilogue information
#
print WEB "</table>\n";
print WEB "$bf <p>Summary [phase:cnt]  $ef\n";
for ($i = 1; $i <= $Bomblab::NUMPHASES+1; $i++) {

    # Always print the non-secret stages
    if ($i < $Bomblab::NUMPHASES+1) {
        print WEB "$bf [$i:$HIST{$i}]  $ef";
    }

    # Don't reveal the existence of the secret phase 
    # until someone has solved it
    elsif ($HIST{$i}) {
        print WEB "$bf [$i:$HIST{$i}]  $ef";
    }
}
$totaldefused = $HIST{6} + $HIST{7};
print WEB "$bf total defused = $totaldefused/$bombcount<br>\n $ef";
print WEB "<p>";
print WEB "</body></html>\n";

#
# Rename the tmp web page to the final web page
#
close(WEB)
    or log_die("Unable to close $tmpwebpage: $!");

if (system("/bin/cp", $tmpwebpage, $webpage)) { 
    log_msg("Warning: Unable to copy $tmpwebpage to $webpage: $!");
}
if (system("/bin/rm", $tmpwebpage)) {
    log_msg("Warning: Unable to remove $tmpwebpage: $!");
}

# 
# Emit the gradefile of (userid,score) pairs
#
if ($gradefile) {   
    open(GRADE, ">$gradefile") 
        or log_die("Unable to open output gradefile $gradefile: $!");
    flock(GRADE, LOCK_EX)
        or log_die("Unable to lock $gradefile: $!");

    #dcf 3/17/04 - fix for grading bug:
    #  students should receive credit for the
    #  highest number of (valid) phases defused
    #  minus the highest number of explosions
    #dcf 3/17/04 - new grading code
    my %BEST = ();
    my $student;
    foreach $bombid (keys %RESULTS) {
        $student = $RESULTS{$bombid}[0];
        $BEST{$student}[0] = 0;
        $BEST{$student}[1] = 0;
    }
    foreach $bombid (keys %RESULTS) {
        $student = $RESULTS{$bombid}[0];
        $BEST{$student}[0] = $RESULTS{$bombid}[2] if $RESULTS{$bombid}[2] > $BEST{$student}[0]; #take highest number of phases defused
        $BEST{$student}[1] += $RESULTS{$bombid}[3]; #sum all explosions
    }
    foreach $student (sort keys %BEST) {
        $numdefused = $BEST{$student}[0];
        $numexplosions = $BEST{$student}[1];
        $score = bomb_score($numdefused, $numexplosions);
        print GRADE "$student\t$score\n";
    }


    close(GRADE);
}


exit(0);

###################
# End main routine
###################

#
# validate - Validate the first $s solutions in global studentsol array
#
sub validate {
    my $k = shift;   # Validate first k strings 
    my $bombfile = shift; # Name of bomb executable

    my $i;
    my $valid;
    my $tmpfile = "tmp-solution.$$";
    
    # Create a temporary solution file
    unless (open(SOLUTION, ">$tmpfile")) { 
        log_die("Couldn't open temp file $tmpfile");
    }
    for ($i = 0; $i < $k; $i++) {
        print SOLUTION "$studentsol[$i]\n";
    }
    close(SOLUTION);

    # Now validate by running the bomb with partial solutions enabled
    # (i.e., GRADE_BOMB environment variable set)
    $valid = 1;
    system("(export GRADE_BOMB='y';$bombfile $tmpfile>/dev/null 2>&1)") == 0 
        or $valid = 0;

    # clean up temporary solution file
    system("rm -f $tmpfile") == 0
        or log_die("rm -f $tmpfile failed");

    # Return the result of the validation
    return $valid;
}    

#
# read_logfile - Read logfile and make summarizing hash. For each bombid:  
#     RESULTS{bombid} = 
#         [0: userid, 
#          1: unused, 
#          2: max defused, 
#          3: num explosions, 
#          4: time of least recent defusion/explosion,
#          5,6,...: most recent defusing string for phase 1, 2,..., phase k
#          ]
#
sub read_logfile {
    my $logfile = shift;

    my $linenum;
    my $line;
    my $hostname;
    my $time;
    my $timesecs;
    my $userid;
    my $user_password;
    my $labid;
    my $result;
    my $bombid;
    my $event;
    my $phase;
    my $string;
    
    my %RESULTS = ();
    my %PASSWORD_CACHE = ();
    my %USERID_CACHE = ();
    
    if ($verbose) {
        print "Reading log file.\n";
    }

    open(LOGFILE, $logfile) 
        or exit(0); # If there is no log file, just exit quietly

    # Read log file and gather results for each bomb in this Lab
    $linenum = 0;
    while ($line = <LOGFILE>) {
        $linenum++;
        chomp($line);

        
        # Skip blank lines
        if ($line eq "") {
            next;
        }

        # Parse the input line
        ($hostname, $time, $userid, $user_password, $labid, $result) =
            split(/\|/, $line, 6);
        if (!$hostname or !$time or !$userid or !$user_password or !$labid or !$result) {
            log_msg("Bad input field in bomblab log line $linenum. Ignored")
                if $verbose;
            next;
        }

        # Ignore results from bombs from previous terms
        if ($labid ne $Bomblab::LABID) {
            next;
        }

        # Parse the result field from the bomb client
        ($bombid, $event, $phase, $string) = split(/:/, $result, 4);
        if (($bombid <= 0) or 
            (($event ne "exploded") and ($event ne "defused")) or 
            (($phase <= 0) or ($phase > $Bomblab::NUMPHASES+1))) {
            log_msg("Bad autoresult string in bomblab log line $linenum. Ignored")
                if $verbose;
            next;
        }
        
        $STUDENT_INFO{$userid}->{bombID}=$bombid;
        
        if (length($string) > $Bomblab::MAXSTRLEN) {
            log_msg("Bomb input string too long in bomblab log line $linenum. Ignored")
                if $verbose;
            next;
        }

        #
        # Make sure all the input files we need exist and are accessible
        # Notice that we're validating with the quiet (non-notifying version)
        # of each bomb.
        #
        $bombdir = "$bombsdir/bomb$bombid";
        unless (-d $bombdir) {
            log_msg("Couldn't find bomb directory $bombdir");
            next;
        }

        #
        # Per-user password to prevent spoofing: validate that the user really is
        # who they claim to be
        #
        # https://stackoverflow.com/questions/881779/neatest-way-to-remove-linebreaks-in-perl/884082#884082
        # https://stackoverflow.com/questions/206661/what-is-the-best-way-to-slurp-a-file-into-a-string-in-perl/206778#206778
        #
        if (!exists $PASSWORD_CACHE{$bombid}) {
            my $passwordfile = "$bombdir/PASSWORD";
            unless (-f $passwordfile) {
                log_msg("Couldn't find file with user password $passwordfile");
                next;
            }
            my $password_contents = do { local $/; open my $fh, $passwordfile; <$fh> };
            $password_contents =~ s/\R*//g;
            $PASSWORD_CACHE{$bombid} = $password_contents;
        }

        my $expected_password = $PASSWORD_CACHE{$bombid};
        unless ($user_password eq $expected_password) {
            log_msg("Rejecting solution: invalid password (actual: $user_password, expected: $expected_password)");
            next;
        }

        # Similarly, also check for attemps to forge a user identity (email).
        if (!exists $USERID_CACHE{$bombid}) {
            my $useridfile = "$bombdir/ID";
            unless (-f $useridfile) {
                log_msg("Couldn't find file with user ID $useridfile");
                next;
            }
            my $userid_contents = do { local $/; open my $fh, $useridfile; <$fh> };
            $userid_contents =~ s/\R*//g;
            $USERID_CACHE{$bombid} = $userid_contents;
        }

        my $expected_userid = $USERID_CACHE{$bombid};
        unless ($userid eq $expected_userid) {
            log_msg("Rejecting solution: invalid userid (actual: $userid, expected: $expected_userid)");
            next;
        }

        #
        # ngm Added the following line to allow bomb sorting by
        # completion time. For the latest diffused phase, we want to
        # remember the first time it was diffused. $timesecs will store
        # the value of time in seconds since the Epoch.
        #
        $timesecs = date2time($time);

        # If this is the first activity for this bomb, create a new
        # entry in the hash.
        if (!exists $RESULTS{$bombid}) {
            $RESULTS{$bombid} = [$userid, 0, 0, 0, 0]; 
        }
        
        # If this event is an explosion, simply increment the 
        # number of explosions for this bomb.
        if ($event eq "exploded") {
            $RESULTS{$bombid}[3]++;
            $RESULTS{$bombid}[4] = $timesecs;
            
            next;
        }
        
        # If this event is a defusion, remember the largest phase 
        # defused so far.
        if ($phase > $RESULTS{$bombid}[2]) { # current phase > max phase
            $RESULTS{$bombid}[2] = $phase;

            # Assume the log is appended to, so later records will have $time
            # values at least as large as this $time value
            $RESULTS{$bombid}[4] = $timesecs;
        }	

        # Store the defusing string
        $RESULTS{$bombid}[$phase+4] = $string;
    }
    close(LOGFILE);

    if ($verbose) {
        print "Done reading log file\n";
    }

    return %RESULTS;
}

#
# usage - print help message and terminate
#
sub usage 
{
    my $msg = shift;

    if ($msg) {
        printf STDERR "$0: ERROR: $msg\n";
    }

    printf STDERR "Usage: $0 [-h]\n";
    printf STDERR "Options:\n";
    printf STDERR "  -h           Print this message\n";
    die "\n";
}

# 
# print_webpage_header - Print the standard Web page header
#

sub print_webpage_header {
    my $title = "Bomb Lab Scoreboard";
    $headerhtml = "bgcolor=$Bomblab::DARK_GREY align=center";

    print WEB <<"EOF";
    <html>
    <head>
    <meta charset="UTF-8">
    <title>$title</title>
    <style>
        /* 页面总体样式 */
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f4f9;
            color: #333;
            margin: 0;
            padding: 20px;
        }

        h2 {
            color: #2c3e50;
            text-align: center;
        }

        /* 筛选器样式 */
        #filter {
            margin: 20px auto;
            max-width: 600px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        #filter label {
            font-weight: bold;
            margin-right: 5px;
        }

        #filter select, #search-input {
            padding: 8px;
            font-size: 14px;
        }

        /* 表格样式 */
        table {
            width: 100%;
            border-collapse: collapse;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
            margin-top: 20px;
        }

        th {
            background-color: #34495e;
            color: #ffffff;
            padding: 10px;
        }

        td {
            padding: 10px;
            border: 1px solid #ddd;
            text-align: center;
        }

        tr:nth-child(even) {
            background-color: #f9f9f9;
        }

        tr:hover {
            background-color: #f1f1f1;
        }

        /* 状态样式 */
        .valid { color: #2ecc71; font-weight: bold; }
        .invalid { color: #e74c3c; font-weight: bold; }
    </style>
    <script>
        // 筛选和搜索功能
        function filterTable() {
            const classFilter = document.getElementById('class-filter').value;
            const teacherFilter = document.getElementById('teacher-filter').value;
            const searchQuery = document.getElementById('search-input').value.toLowerCase();
            const rows = document.querySelectorAll('#scoreboard-table tr:not(.header)');

            rows.forEach(row => {
                const classMatch = classFilter === '' || row.dataset.class === classFilter;
                const teacherMatch = teacherFilter === '' || row.dataset.teacher === teacherFilter;
                const searchMatch = row.innerText.toLowerCase().includes(searchQuery);
                row.style.display = (classMatch && teacherMatch && searchMatch) ? '' : 'none';
            });
        }

        // 自动更新时间
        function updateTime() {
            const now = new Date();
            document.getElementById('update-time').innerText = 'Last updated: ' + now.toLocaleString();
        }
        setInterval(updateTime, 60000);  // 每分钟更新一次
    </script>
    </head>
    <body onload="updateTime()">
    <h2>$title</h2>
    <p id="update-time">Last updated: @{[ scalar localtime ]}</p>

    <!-- 筛选器和搜索框 -->
    <div id="filter">
        <div>
            <label for="class-filter">Class:</label>
            <select id="class-filter" onchange="filterTable()">
                <option value="">All</option>
EOF

    # 动态生成班级选项
    my %classes = map { $_->{class} => 1 } values %STUDENT_INFO;
    foreach my $class (sort keys %classes) {
        print WEB "<option value=\"$class\">$class</option>\n";
    }

    print WEB <<"EOF";
            </select>
        </div>
        <div>
            <label for="teacher-filter">Teacher:</label>
            <select id="teacher-filter" onchange="filterTable()">
                <option value="">All</option>
EOF

    # 动态生成老师选项
    my %teachers = map { $_->{teacher} => 1 } values %STUDENT_INFO;
    foreach my $teacher (sort keys %teachers) {
        print WEB "<option value=\"$teacher\">$teacher</option>\n";
    }

    print WEB <<"EOF";
            </select>
        </div>
        <div>
            <label for="search-input">Search:</label>
            <input type="text" id="search-input" onkeyup="filterTable()" placeholder="Search by name...">
        </div>
    </div>

    <!-- 结果表格 -->
    <table id="scoreboard-table">
        <tr class="header">
            <th>#</th>
            <th>Bomb Number</th>
            <th>Submission Date</th>
            <th>Phases Defused</th>
            <th>Explosions</th>
            <th>Score</th>
            <th>Student_id</th>
            <th>Student</th>
            <th>Class</th>
            <th>Teacher</th>
        </tr>
EOF
}


	       
# 
# bomb_score - Compute the lab score: 
#   +10 pts for each defused phase 1-4. 15 pts for 5 and 6
#   No extra credit for secret phase. 
#   EXPLOSION_PENALTY pt per explosion, up to a max of MAXEPLOSIONS 
#   Round final score up to nearest integer (first explosions free!)
#
sub bomb_score {
    my $numdefused = shift;
    my $numexplosions = shift;

    my $netdefused = $numdefused;
    my $netexplosions = $numexplosions;
    my $defusepts;
    my $explodepts_round;
    
    if ($numdefused > $Bomblab::NUMPHASES) { # no extra points for secret phase
        $netdefused = $Bomblab::NUMPHASES;
    }    
    if ($numexplosions > $Bomblab::MAXEXPLOSIONS) { # limit the explosion penalty
        $netexplosions = $Bomblab::MAXEXPLOSIONS;
    }


    #Last two phases are worth 15 points each
    if ($netdefused <= 4) {
        $defusepts = $netdefused*10;
    }
    if ($netdefused == 5) {
        $defusepts = 55;
    }
    if ($netdefused == 6) {
        $defusepts = 70;
    }
    
    # Deduct EXPLOSION_PENALTY points for each explosion
    $explodepts_round = 
        int $netexplosions * $explosion_penalty; # round down to nearest int


    $score = $defusepts - $explodepts_round;
    return $score;
}
