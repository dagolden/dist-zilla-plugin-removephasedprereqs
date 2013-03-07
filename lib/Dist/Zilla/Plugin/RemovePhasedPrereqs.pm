use 5.008001;
use strict;
use warnings;

package Dist::Zilla::Plugin::RemovePhasedPrereqs;
# ABSTRACT: No abstract given for Dist::Zilla::Plugin::RemovePhasedPrereqs
# VERSION

use Moose;
with 'Dist::Zilla::Role::PrereqSource';

use namespace::autoclean;

use Moose::Autobox;

use MooseX::Types::Moose qw(ArrayRef);
use MooseX::Types::Perl  qw(ModuleName);

=head1 SYNOPSIS

In your F<dist.ini>:

  [RemovePrereqs]
  remove = Foo::Bar
  remove = MRO::Compat

This will remove any prerequisite of any type from any prereq phase.  This is
useful for eliminating incorrectly detected prereqs.

=head1 SEE ALSO

Dist::Zilla plugins:
L<Prereqs|Dist::Zilla::Plugin::Prereqs>,
L<AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs>.

=cut

my @phases = qw(configure build test runtime develop);

my @types  = qw(requires recommends suggests conflicts);

my %attr_map = map { $_ => "remove_$_" } @phases;

sub mvp_multivalue_args { values %attr_map }

has [ values %attr_map ] => (
  is  => 'ro',
  isa => ArrayRef[ ModuleName ],
  required => 1,
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

In dist.ini:

    [RemovePhasedPrereqs]
    remove_runtime = Foo
    remove_runtime = Bar

=head1 DESCRIPTION

This module is similar to L<Dist::Zilla::Plugin::RemovePrereqs> except it
lets you specify which requirements section to remove from instead of
removing from all.

Valid keys are:

=for :list
* remove_build
* remove_configure
* remove_develop
* remove_runtime
* remove_test

=head1 USAGE

Good luck!

=head1 SEE ALSO

Maybe other modules do related things.

=cut

# vim: ts=4 sts=4 sw=4 et:
