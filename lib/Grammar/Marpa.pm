package Grammar::Marpa;

use 5.018;
use utf8;
use overload ('qr' => 'regexify', fallback => 0);

use Carp qw( confess );
use Marpa::R2;

our $VERSION = '1.000';

sub regexify {
    my ($grammar) = @_;
    use re 'eval';
    return qr/(?{Grammar::Marpa::parse("$_", $grammar)})/;
}

sub parse {
    my ($string, $grammar) = @_;
    my $R = Marpa::R2::Scanless::R->new({ grammar => $grammar->[ 0 ], semantics_package => $grammar->[ 1 ] });
    $R->read(\$string);
    my $V = $R->value or confess("No parse");
    return $$V;
}

package Grammar;

sub Marpa {
    my ($ebnf, $pkg) = @_;
    $pkg //= (caller)[0];
    my $G = Marpa::R2::Scanless::G->new({ source => \$ebnf });
    return bless [ $G, $pkg ] => 'Grammar::Marpa';
}

1;

__END__

=head1 NAME

Grammar::Marpa - No-frills overload wrapper around Marpa::R2::Scanless

=head1 VERSION

Version 1.000

=head1 SYNOPSIS

    use Grammar::Marpa;

    my $dsl = <<'END_OF_DSL';
    :default ::= action => ::first
    :start ::= Expression
    Expression ::= Term
    Term ::= Factor
           | Term '+' Term action => do_add
    Factor ::= Number
             | Factor '*' Factor action => do_multiply
    Number ~ digits
    digits ~ [\d]+
    :discard ~ whitespace
    whitespace ~ [\s]+
    END_OF_DSL

    sub M::do_add {
        my (undef, $t1, undef, $t2) = @_;
        return $t1 + $t2;
    }

    sub M::do_multiply {
        my (undef, $t1, undef, $t2) = @_;
        return $t1 * $t2;
    }

    my $g = Grammar::Marpa($dsl, 'M');

    '1 + 2 * 3' =~ $g;

    say $^R; # '7'

=head1 DESCRIPTION

This module provides a quick & dirty interface to the very basics of
Marpa::R2's Scanless interface, including overloading the '=~' operator
in a way that is only I<slightly> inconvenient.

=head1 CONSTRUCTORS

=head2 Grammar::Marpa(GRAMMAR, PACKAGE)

Create a new grammar object, based on a well-formed SLIF EBNF grammar (which
must be provided as a scalar string) and using the specified package to provide
the semantics of the grammar.

=head1 USAGE

=head2 '=~'

Once you have a grammar object, you can parse a string by performing

    $string =~ $grammar;

=head2 $^R

Once you have parsed a string with a grammar object, the $^R variable will
contain the value of the last parse.

=cut
