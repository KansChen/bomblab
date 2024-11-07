#!/usr/bin/perl
require 5.002;

#######################################################################
# bomblab-requestd.pl - The CS:APP Binary Bomb Request Daemon
#
# ...（省略原有注释部分）...
#
#######################################################################

use strict 'vars';
use Getopt::Std;
use Socket;
use Sys::Hostname; 
use Text::CSV;           # 新增模块，用于处理 CSV 文件

use lib ".";
use Bomblab;

# 
# Generic settings
#
$| = 1;          # Autoflush output on every print statement
$0 =~ s#.*/##s;  # Extract the base name from argv[0] 

# 
# Ignore any SIGPIPE signals caused by the server writing 
# to a connection that has already been closed by the client
#
$SIG{PIPE} = 'IGNORE'; 

#
# Canned client error messages
#
my $bad_usermail_msg = "Invalid student name.";
my $bad_username_msg = "You forgot to enter a student ID.";
my $usermail_taint_msg = "The student name contains an illegal character.";
my $username_taint_msg = "The student ID contains an illegal character.";
my $user_not_found_msg = "Student ID and name do not match our records.";   # 新增错误信息

#
# Configuration variables from Bomblab.pm
#
my $server_port = $Bomblab::REQUESTD_PORT;
my $labid = $Bomblab::LABID;
my $server_dname = $Bomblab::SERVER_NAME;

#
# Other variables 
#
my $notifyflag;
my ($client_port, $client_dname, $client_iaddr);
my $request_hdr;
my $content;
my ($usermail, $username);
my ($bombnum, $maxbombnum);
my $item;
my $tarfilename;
my $buffer;
my @bombs=();

##############
# Main routine
##############

# 
# Parse and check the command line arguments
#
no strict 'vars';
getopts('hsq');
if ($opt_h) {
    usage("");
}

$notifyflag = "-n";
if ($opt_s) {
    $notifyflag = "";
}

$Bomblab::QUIET = 0;
if ($opt_q) {
    $Bomblab::QUIET = 1;
}
use strict 'vars';

#
# Print a startup message
#
log_msg("Request server started on $server_dname:$server_port");

#
# Make sure the files and directories we need are available
#
(-e $Bomblab::MAKEBOMB and -x $Bomblab::MAKEBOMB)
    or log_die("Error: Couldn't find an executable $Bomblab::MAKEBOMB script.");

(-e $Bomblab::BOMBDIR)
    or system("mkdir ./$Bomblab::BOMBDIR");

#
# Establish a listening descriptor
# 
socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname('tcp'))
    or log_die("socket: $!");
setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1)
    or log_die("setsockopt: $!");
bind(SERVER, sockaddr_in($server_port, INADDR_ANY))
    or log_die("Couldn't bind to port $server_port: $!");
listen(SERVER, SOMAXCONN)     
    or log_die("listen: $!");

# LH: On alarm signal (server is hung processing a client request),
# die with message that it happened. The server will then be
# automatically restarted.
$SIG{ALRM} = sub { log_die( "alarm\n") };

#
# Repeatedly wait for scoreboard, form, and bomb requests
#
while (1) {

    # LH: Cancel alarm before waiting for client request
    alarm(0);

    # 
    # Wait for a connection request from a client
    #
    my $client_paddr = accept(CLIENT, SERVER)
        or die "accept: $!\n";

    # LH: Set an alarm for a configurable number of seconds, to
    # prevent the possibility of server hanging while serving a client
    alarm($Bomblab::REQUESTD_TIMEOUT);

    ($client_port, $client_iaddr) = sockaddr_in($client_paddr);
    $client_dname = gethostbyaddr($client_iaddr, AF_INET);

    # 
    # Read the request header (the first text line in the request)
    #
    $request_hdr = <CLIENT>;
    chomp($request_hdr);

    #
    # Ignore requests for favicon.ico
    #
    # NOTE: To avoid memory leak, be careful to close CLIENT fd before 
    # each "next" statement in this while loop.
    #
    if ($request_hdr =~ /favicon/) {
        #log_msg("Ignoring favicon request");
        close CLIENT; 
        next;         
    }

    #
    # If this is a scoreboard request, then simply return the scoreboard
    #
    if ($request_hdr =~ /\/scoreboard/) {
        $content = "No scoreboard yet...";
        if (-e $Bomblab::SCOREBOARDPAGE) {
            $content = `cat $Bomblab::SCOREBOARDPAGE`;
        }
        sendform($content);
    }

    # 
    # If there aren't any specific HTML form arguments, then we interpret
    # this as an initial request for an HTML form. So we build the 
    # form and send it back to the client.
    #

    elsif (!($request_hdr =~ /usermail=/)) {
        #log_msg("Form request from $client_dname");
        sendform(buildform($server_dname, $server_port, $labid, 
                           "", "", ""));
    }

    #
    # If this is a reset request, just send the client a clean form
    #
    elsif ($request_hdr =~ /reset=/) {
        #log_msg("Reset request from $client_dname");
        sendform(buildform($server_dname, $server_port, $labid, 
                           "", "", ""));
    }

    #  Otherwise, since it's not a reset (clean form) request and the
    # URI contains a specific HTML form argument, we interpret this as
    # a bomb request.  So we parse the URI, build the bomb, tar it up,
    # and transfer it back over the connection to the client.

    else {
        

        #
        # Undo the browser's URI translations of special characters
        #
        $request_hdr =~ s/%25/%/g;  # Do first to handle %xx inputs

        $request_hdr =~ s/%20/ /g; 
        $request_hdr =~ s/\+/ /g; 
        $request_hdr =~ s/%21/!/g;  
        $request_hdr =~ s/%23/#/g;  
        $request_hdr =~ s/%24/\$/g; 
        $request_hdr =~ s/%26/&/g;  
        $request_hdr =~ s/%27/'/g;    
        $request_hdr =~ s/%28/(/g;    
        $request_hdr =~ s/%29/)/g;    
        $request_hdr =~ s/%2A/*/g;    
        $request_hdr =~ s/%2B/+/g;    
        $request_hdr =~ s/%2C/,/g;    
        $request_hdr =~ s/%2D/-/g;    
        $request_hdr =~ s/%2d/-/g;    
        $request_hdr =~ s/%2E/./g;    
        $request_hdr =~ s/%2e/./g;    
        $request_hdr =~ s/%2F/\//g;    

        $request_hdr =~ s/%3A/:/g;    
        $request_hdr =~ s/%3B/;/g;    
        $request_hdr =~ s/%3C/</g;    
        $request_hdr =~ s/%3D/=/g;    
        $request_hdr =~ s/%3E/>/g;    
        $request_hdr =~ s/%3F/?/g;    

        $request_hdr =~ s/%40/@/g;

        $request_hdr =~ s/%5B/[/g;
        $request_hdr =~ s/%5C/\\/g;
        $request_hdr =~ s/%5D/[/g;
        $request_hdr =~ s/%5E/\^/g;
        $request_hdr =~ s/%5F/_/g;
        $request_hdr =~ s/%5f/_/g;

        $request_hdr =~ s/%60/`/g;

        $request_hdr =~ s/%7B/\{/g;
        $request_hdr =~ s/%7C/\|/g;
        $request_hdr =~ s/%7D/\}/g;
        $request_hdr =~ s/%7E/~/g;


        # Parse the request URI to get the user information
        $request_hdr =~ /username=(.*?)&usermail=(.*?)&/;
        $username = $1;
        $usermail = $2;

        # Decode URL-encoded strings to handle potential special characters
        use URI::Escape;
        $username = uri_unescape($username);
        $usermail = uri_unescape($usermail);

        #
        # For security purposes, make sure the form inputs contain only 
        # non-shell metacharacters. The only legal characters are spaces, 
        # letters, numbers, hyphens, underscores, and dots.
        #

        # usermail field (now Student Name)
        if ($usermail ne "") {
            if (!($usermail =~ /^([\s-\w.]+)$/)) {
                log_msg ("Invalid bomb request from $client_dname: Illegal character in student name ($usermail):"); 
                sendform(buildform($server_dname, $server_port, $labid, 
                                   $usermail, $username, 
                                   $usermail_taint_msg));
                close CLIENT;
                next;
            }
        }

        # username field (now Student ID)
        if ($username ne "") {
            if (!($username =~ /^([\s-\w.]+)$/)) {
                log_msg ("Invalid bomb request from $client_dname: Illegal character in student ID ($username):"); 
                sendform(buildform($server_dname, $server_port, $labid, 
                                   $usermail, $username, 
                                   $username_taint_msg));
                close CLIENT;
                next;
            }
        }

        # The student ID field is required
        if (!$username or $username eq "" or $username =~ /^ +$/) {
            log_msg ("Invalid bomb request from $client_dname: Missing student ID:");

            sendform(buildform($server_dname, $server_port, $labid, 
                               $usermail, $username, 
                               $bad_username_msg)); 
            close CLIENT;
            next;
        }


        #
        # The student name field is required
        #
        if (!$usermail or $usermail eq "" or 
            $usermail =~ /^ +$/) {
            log_msg ("Invalid bomb request from $client_dname: Invalid student name ($usermail):"); 
            sendform(buildform($server_dname, $server_port, $labid, 
                               $usermail, $username, 
                               $bad_usermail_msg));
            close CLIENT;
            next;
        }

        #
        # NEW FEATURE: Check if the student ID and name match the records
        #
        my $is_valid_user = 0;
        my $csv_file = 'name_list1.csv';

        if (-e $csv_file) {
            my $csv = Text::CSV->new({ binary => 1 });
            open my $fh, "<:encoding(utf8)", $csv_file or die "Could not open '$csv_file' $!\n";
            while (my $row = $csv->getline($fh)) {
                my ($file_student_id, $file_student_name) = @$row;
                if ($username eq $file_student_id && $usermail eq $file_student_name) {
                    $is_valid_user = 1;
                    last;
                }
            }
            $csv->eof or $csv->error_diag();
            close $fh;
        } else {
            log_msg("Cannot find CSV file: $csv_file");
            sendform(buildform($server_dname, $server_port, $labid, 
                               $usermail, $username, 
                               "Internal server error: missing student list."));
            close CLIENT;
            next;
        }

        if (!$is_valid_user) {
            log_msg ("Invalid bomb request from $client_dname: Student ID and name do not match records ($username, $usermail):");
            sendform(buildform($server_dname, $server_port, $labid, 
                               $usermail, $username, 
                               $user_not_found_msg));
            close CLIENT;
            next;
        }

        #
        # Everything checks out OK. So now we build and deliver the 
        # bomb to the client.
        # 
        log_msg ("Bomb request from $client_dname:$username:$usermail:");
        
        # Get a list of all of the bombs in the bomb directory
        opendir(DIR, $Bomblab::BOMBDIR) 
            or die "ERROR: Couldn't open $Bomblab::BOMBDIR\n";
        @bombs = grep(/bomb/, readdir(DIR)); 
        closedir(DIR);
        
        #
        # Find the largest bomb number, being careful to use numeric 
        # instead of lexicographic comparisons.
        #
        map s/bomb//, @bombs;
        $maxbombnum = 0;
        foreach $item (@bombs) {
            if ($item > $maxbombnum) {
                $maxbombnum = $item;
            }
        } 
        $bombnum = $maxbombnum + 1;
        
        #
        # Build a new bomb, being careful, for security reasons, 
        # to invoke the list version of system and thus avoid 
        # running a shell.
        #
        system("./$Bomblab::MAKEBOMB", "-q", "$notifyflag", "-l", "$labid", "-i", "$bombnum", "-b", "./$Bomblab::BOMBDIR", "-s", "./$Bomblab::BOMBSRC", "-u", "$usermail", "-v", "$username") == 0 
            or die "ERROR: Couldn't make bomb$bombnum\n";
        
        #
        # Tar up the bomb
        #
        $tarfilename = "bomb$bombnum.tar";
        system("(cd $Bomblab::BOMBDIR; tar cf - bomb$bombnum/README bomb$bombnum/bomb.c bomb$bombnum/bomb > $tarfilename)") == 0 
            or die "ERROR: Couldn't tar $tarfilename\n";
        
        #
        # Now send the bomb across the connection to the client
        #
        print CLIENT "HTTP/1.0 200 OK\r\n";
        print CLIENT "Connection: close\r\n";
        print CLIENT "MIME-Version: 1.0\r\n";
        print CLIENT "Content-Type: application/x-tar\r\n";
        print CLIENT "Content-Disposition: file; filename=\"$tarfilename\"\r\n";
        print CLIENT "\r\n"; 
        open(INFILE, "$Bomblab::BOMBDIR/$tarfilename")
            or die "ERROR: Couldn't open $tarfilename\n";
        binmode(INFILE, ":raw");
        binmode(CLIENT, ":raw");
        select((select(CLIENT), $| = 1)[0]);
        while (sysread(INFILE, $buffer, 1)) {
            syswrite(CLIENT, $buffer, 1);
        }
        close(INFILE);
        
        # 
        # Log the successful delivery of the bomb to the browser
        #
        log_msg ("Sent bomb $bombnum to $client_dname:$username:$usermail:");
        
        # 
        # Remove the tarfile
        # 
        unlink("$Bomblab::BOMBDIR/$tarfilename")
            or die "ERROR: Couldn't delete $tarfilename: $!\n";

    } # if-then-elsif-else statement

    #
    # Close the client connection after each request/response pair
    #
    close CLIENT;

} # while loop

exit;

###################
# Helper functions
##################

#
# void usage(void) - print help message and terminate
#
sub usage 
{
    printf STDERR "$_[0]\n";
    printf STDERR "Usage: $0 [-hqs]\n";
    printf STDERR "Options:\n";
    printf STDERR "  -h   Print this message.\n";
    printf STDERR "  -s   Silent. Build bombs with NONOTIFY option.\n";
    printf STDERR "  -q   Quiet. Send error and status msgs to $Bomblab::STATUSLOG instead of tty.\n";
    die "\n" ;
}

#
# char *buildform(char *hostname, int port, char *labid, 
#                 char *usermail, char *username,
#                 *char *errmsg)
#
# This routine builds an HTML form as a single string.
# The <hostname,port> pair identifies the request daemon.
# The labid is the unique name for this instance of the Lab.
# The user* fields define the default values for the HTML form fields. 
# The errmsg is optional and informs users about input mistakes.
#
sub buildform {
    my $hostname = $_[0];
    my $port = $_[1];
    my $labid = $_[2];
    my $usermail = $_[3];
    my $username = $_[4];
    my $errmsg = $_[5];
    
    my $form = "";
    $form .= "<!DOCTYPE html>\n";
    $form .= "<html lang=\"en\">\n";
    $form .= "<head>\n";
    $form .= "    <meta charset=\"UTF-8\">\n";
    $form .= "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n";
    $form .= "    <title>CS:APP Binary Bomb Request</title>\n";
    
    # CSS样式
    $form .= "    <style>\n";
    $form .= "        body { font-family: Arial, sans-serif; background-color: #f4f4f9; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; color: #333; }\n";
    $form .= "        .container { background: #fff; border-radius: 8px; box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1); padding: 20px; max-width: 400px; width: 100%; text-align: center; }\n";
    $form .= "        h2 { margin-bottom: 16px; color: #007bff; }\n";
    $form .= "        p { font-size: 0.9em; color: #555; }\n";
    $form .= "        form { display: flex; flex-direction: column; }\n";
    $form .= "        label { font-weight: bold; margin-top: 12px; text-align: left; }\n";
    $form .= "        input[type=\"text\"] { padding: 8px; font-size: 1em; border: 1px solid #ddd; border-radius: 4px; margin-top: 4px; transition: border-color 0.3s; }\n";
    $form .= "        input[type=\"text\"]:focus { border-color: #007bff; }\n";
    $form .= "        .buttons { display: flex; justify-content: space-between; margin-top: 16px; }\n";
    $form .= "        .buttons input[type=\"submit\"] { background-color: #007bff; color: white; padding: 10px; border: none; border-radius: 4px; cursor: pointer; transition: background-color 0.3s; }\n";
    $form .= "        .buttons input[type=\"submit\"]:hover { background-color: #0056b3; }\n";
    $form .= "        .error-message { font-weight: bold; color: #e74c3c; font-size: 0.9em; margin-top: 10px; }\n";
    $form .= "        .lang-toggle { margin-top: 10px; cursor: pointer; color: #007bff; }\n";
    $form .= "    </style>\n";

    # JavaScript切换语言
    $form .= "    <script>\n";
    $form .= "        let isEnglish = true;\n";
    $form .= "        function toggleLanguage() {\n";
    $form .= "            isEnglish = !isEnglish;\n";
    $form .= "            document.getElementById('title').textContent = isEnglish ? 'CS:APP Binary Bomb Request' : 'CS:APP 二进制炸弹请求';\n";
    $form .= "            document.getElementById('instruction').textContent = isEnglish ? 'Please fill out this form to request a binary bomb.' : '请填写此表格以申请二进制炸弹。';\n";
    $form .= "            document.getElementById('allowed-chars').textContent = isEnglish ? 'Only letters, numbers, underscores (_), hyphens (-), and dots (.) are allowed.' : '只允许使用字母、数字、下划线 (_)、连字符 (-) 和点 (.)。';\n";
    $form .= "            document.getElementById('username-label').textContent = isEnglish ? 'Student Id' : '学号';\n";
    $form .= "            document.getElementById('usermail-label').textContent = isEnglish ? 'Student Name' : '学生姓名';\n";
    $form .= "            document.getElementById('submit-button').value = isEnglish ? 'Submit' : '提交';\n";
    $form .= "            document.getElementById('reset-button').value = isEnglish ? 'Reset' : '重置';\n";
    $form .= "            document.getElementById('error-message').textContent = isEnglish ? '$errmsg' : '$errmsg';\n";
    $form .= "            document.getElementById('lang-toggle').textContent = isEnglish ? 'Switch to Chinese' : 'Switch to English';\n";
    $form .= "        }\n";
    $form .= "    </script>\n";
    
    $form .= "</head>\n";
    $form .= "<body>\n";

    # 表单内容
    $form .= "    <div class=\"container\">\n";
    $form .= "        <h2 id=\"title\">CS:APP Binary Bomb Request</h2>\n";
    $form .= "        <p id=\"instruction\">Please fill out this form to request a binary bomb.</p>\n";
    $form .= "        <p id=\"allowed-chars\">Only letters, numbers, underscores (_), hyphens (-), and dots (.) are allowed.</p>\n";
    $form .= "        <form action=\"http://$hostname:$port\" method=\"get\">\n";
    
    $form .= "            <label id=\"username-label\" for=\"username\">Student Id</label>\n";
    $form .= "            <input type=\"text\" id=\"username\" name=\"username\" maxlength=\"50\" value=\"$username\" required>\n";
    
    $form .= "            <label id=\"usermail-label\" for=\"usermail\">Student Name</label>\n";
    $form .= "            <input type=\"text\" id=\"usermail\" name=\"usermail\" maxlength=\"50\" value=\"$usermail\" required>\n";
    
    $form .= "            <div class=\"buttons\">\n";
    $form .= "                <input type=\"submit\" id=\"submit-button\" name=\"submit\" value=\"Submit\">\n";
    $form .= "                <input type=\"reset\" id=\"reset-button\" name=\"reset\" value=\"Reset\">\n";
    $form .= "            </div>\n";
    $form .= "        </form>\n";

    # 错误消息
    # 根据错误信息动态更新表单中的错误消息部分
    if ($errmsg and $errmsg ne "") {
        $form .= "        <div class=\"error-message\" id=\"error-message\"><p><b>$errmsg</b></p></div>\n";
    } else {
        $form .= "        <div class=\"error-message\" id=\"error-message\"></div>\n"; # 没有错误时不显示错误信息
    }


    # 切换语言按钮
    $form .= "        <p id=\"lang-toggle\" class=\"lang-toggle\" onclick=\"toggleLanguage()\">Switch to Chinese</p>\n";

    $form .= "    </div>\n";
    $form .= "</body>\n";
    $form .= "</html>\n";
    
    return $form;
}

#
# void sendform(char *form) - Sends a form to the client   
#
sub sendform
{
    my $form = $_[0];
    my $formlength = length($form);
    print CLIENT "HTTP/1.0 200 OK\r\n";
    print CLIENT "MIME-Version: 1.0\r\n";
    print CLIENT "Content-Type: text/html\r\n";
    print CLIENT "Content-Length: $formlength\r\n";
    print CLIENT "\r\n"; 
    print CLIENT $form;
}
