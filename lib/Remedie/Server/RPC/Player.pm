package Remedie::Server::RPC::Player;
use Moose;

BEGIN { extends 'Remedie::Server::RPC' }

__PACKAGE__->meta->make_immutable;

no Moose;

eval { require Mac::AppleScript };
use File::Temp;
use LWP::UserAgent;

my %map = (
    VLC => '_vlc',
    QuickTime => '_quicktime',
    iTunes => '_itunes',
);

# XXX This needs to be pluggable
sub nicovideo : POST {
    my($self, $req, $res) = @_;

    my $uri = URI->new( $req->param('url') );
    $uri->host("ext.nicovideo.jp");
    my $path = $uri->path;
    $path =~ s!^/watch/!/thumb_watch/!;
    $uri->path($path);
    $uri->query_form(w => $req->param('width'), h => $req->param('height'));

    my $request = HTTP::Request->new( GET => $uri );
    $request->header('Referer', "http://www.nicovideo.jp/");

    my $ua = LWP::UserAgent->new( $req->header('User-Agent') );
    my $response = $ua->request($request);
    $response->is_success or die "Request failed: " . $response->status_line;

    ## Whoa HACK
    my $code = $response->content;
    $code =~ s/document\.write\((.*?)\)/\$("#embed-player").html($1)/g;
    $code =~ s/(wv_title.*?)$/$1\n, fv_autoplay: 1/m;

    return { success => 1, code => $code };
}

sub play : POST {
    my($self, $req, $res) = @_;

    my $player = $req->param('player')
        or die "No player defined";

    my $p = $map{$player}
        or die "Unkown player $player";

    $self->$p($req, $res);
}

sub _vlc {
    my($self, $req, $res) = @_;
    my $url = $req->param('url');

    _run_apple_script('VLC', <<SCRIPT);
OpenURL "$url"
activate
play
next
SCRIPT

    if ($req->param('fullscreen')) {
        _run_apple_script('VLC', 'fullscreen');
    }

    return { success => 1 };
}

sub _quicktime {
    my($self, $req, $res) = @_;

    my $url = $req->param('url');
    _run_apple_script('QuickTime Player', <<SCRIPT);
activate
getURL "$url"
SCRIPT

    if ($req->param('fullscreen')) {
        _run_apple_script('QuickTime Player', 'present front movie scale screen');
    }
}

sub _run_apple_script {
    my($app, $script) = @_;

    chomp $script;
    my $as = qq(tell Application "$app"\n$script\nend tell);

    if (defined &Mac::AppleScript::RunAppleScript) {
        return Mac::AppleScript::RunAppleScript($as)
            or die "Can't launch $app via AppleScript";
    } else {
        my $temp = File::Temp->new( UNLINK => 1 );
        my $fname = $temp->filename;
        print $temp $as;
        close $temp;

        my $ret = qx(osascript $fname);
        return $ret;
    }
}

1;
