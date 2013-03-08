use 5.008001;
use strict;
use warnings;

package Dist::Zilla::Plugin::RemovePhasedPrereqs;
# ABSTRACT: Remove gathered prereqs from particular phases
# VERSION

use Moose;
with 'Dist::Zilla::Role::PrereqSource';

use namespace::autoclean;

use Moose::Autobox;

use MooseX::Types::Moose qw(ArrayRef);
use MooseX::Types::Perl  qw(ModuleName);

my @phases = qw(configure build test runtime develop);

my @types  = qw(requires recommends suggests conflicts);

my %attr_map = map { $_ => "remove_$_" } @phases;

sub mvp_multivalue_args { values %attr_map }

has [ values %attr_map ] => (
  is  => 'ro',
  isa => ArrayRef[ ModuleName ],
  default => sub { [] },
);

around dump_config => sub {
  my ($orig, $self) = @_;
  my $config = $self->$orig;

  my $this_config = { map { $_ => $self->$_ } values %attr_map };

  $config->{'' . __PACKAGE__} = $this_config;

  return $config;
};

sub register_prereqs {
  my ($self) = @_;

  my $prereqs = $self->zilla->prereqs;

  for my $p (@phases) {
    my $meth = $attr_map{$p};
    for my $t (@types) {
      for my $m ($self->$meth->flatten) {
        $prereqs->requirements_for($p, $t)->clear_requirement($m);
      }
    }
  }
}

__PACKAGE__->meta->make_immutable;
1;

=for Pod::Coverage register_prereqs mvp_multivalue_args

=head1 SYNOPSIS

In F<dist.ini>:

    [RemovePhasedPrereqs]
    remove_runtime = Foo
    remove_runtime = Bar

=head1 DESCRIPTION

This module is adapted from L<Dist::Zilla::Plugin::RemovePrereqs> to let you
specify particular requirements sections to remove from instead of removing
from all of them.

Valid configuration options are:

=for :list
* remove_build
* remove_configure
* remove_develop
* remove_runtime
* remove_test

These may be used more than once to remove multiple modules.

Modules are removed from all types within a section (e.g. "requires",
"recommends", "suggests", etc.).

=head1 SEE ALSO

=for :list
* L<Dist::Zilla::Plugin::Prereqs>
* L<Dist::Zilla::Plugin::AutoPrereqs>
* L<Dist::Zilla::Plugin::RemovePrereqs>

=cut

# vim: ts=4 sts=4 sw=4 et:
