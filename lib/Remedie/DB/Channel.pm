package Remedie::DB::Channel;
use strict;
use base qw( Remedie::DB::Object );

use Remedie::DB::Channel;

use constant TYPE_FOLDER => 0;
use constant TYPE_FEED   => 1;

__PACKAGE__->meta->table('channel');
__PACKAGE__->meta->auto_initialize;
__PACKAGE__->json_encoded_columns('props');

sub items {
    my $self = shift;
    return Remedie::DB::Item::Manager->search( channel_id => $self->id );
}

package Remedie::DB::Channel::Manager;
use base qw( Remedie::DB::Manager );

sub object_class { 'Remedie::DB::Channel' }
__PACKAGE__->make_manager_methods('channels');

1;


