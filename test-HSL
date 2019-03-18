#! perl
# Show Term::ANSIColor 216-cube of colors 000..555 arrayed as HSL grid
#
# Copyright 2019 William Ricker modifying code by Andy Lester
# License Same As Perl


use Modern::Perl 2017;

use Convert::Color;
use Convert::Color::HSL;
use Convert::Color::RGB;

use Term::ANSIColor;

use Readonly;
# use Data::Dump qw/dd/; # needed in commented out traces

my Readonly $degrees = 12;  ## This is the number that avoids collisions
my Readonly $columns = 360 / $degrees; 


    my $where_href = _save_rgb_grid();
    _show_hue_sat_grid(1, 0,  $where_href);
    _show_hue_sat_grid(0, 0,  $where_href);
#   _show_hue_sat_grid(0, 1,  $where_href);  # 1 for Skip ; leave the sparse matrix gaps blank


############ SUBROUTINES ###########


# Helper to scale Term::ANSIColor 0..5 R,G,B to 0.0 .. 1.0 standard
sub _five_to_1{
    return shift()/5;
}

# our %Where;


sub _where {
    # pass in HSL object, returns xyz grid to display it on
    # if $degrees selected properly, won't cause collisions
    my $hsl = shift;
    my ($h, $s, $l) = $hsl->hsl;
    my $c = $hsl->chroma;
    my $y =  int 10*$l  ;  
    my $z =  int 10*$s ;
    my $x = sprintf "%0d", ($degrees * int( ($h+($degrees/2))/$degrees  ));
    return  [ $x, $y, $z] ;
}


## HSL "Grid"

# show Hue Sat Lum grid
# Modeled on Ack3 _show_rgb_grid, but with HSL iteration over sparce save matrix
# If a position is blank, repeat previous color
# 
#
# Because 20 columns wide, 
#    omits 'rgb' prefix
#    stacks text over background 
#
# arguments
# Reversed = 1 | 0
# Skip : true will not repeat values but leave blank space
# Where = the hashref returned by sibling
#
#
sub _show_hue_sat_grid {
    my ($reversed, $skip, $where )  = @_;
    die unless 'HASH' eq ref $where;
    my (%Where) = ($where->%*);

    my @Hues =  map { $degrees * $_ } 0 .. ($columns-1); 
    say "ddd=Hue Degrees";
    say join( q( ), map { sprintf "%03d",$_ } @Hues),
        " l s";
    for my $z (sort {$b <=> $a} keys %Where){
        # say "s $z" ; # dd $Where{$z};
        for my $y (sort {$b <=> $a} keys $Where{$z}->%*){
            # say "l $y"; # dd $Where{$z}->{$y};
            my $code='rgb000'; # default if hue=0 ever missing
            for my $x (@Hues) {

                my $skippable;
                if ( defined $Where{$z}->{$y}->{$x}) { 
                    my $i = 0;

                    # a few tight hue angles get 324 336  so pick other one in Reversed
                    $i=1 if ($reversed > 0 and 1 < scalar $Where{$z}->{$y}->{$x}->@*);
                    # if ( 1 < scalar $Where{$z}->{$y}->{$x}->@*){ dd $Where{$z}->{$y};};

                    $code = $Where{$z}->{$y}->{$x}->[0]->{code} // $code; ## repeat if position not used
                }
                else {
                    $skippable=1;
                }

                if ($skip and $skippable) {
                    print q(    );
                }
                else {
                    print( ($reversed ?  Term::ANSIColor::colored( substr($code,3,3), $code )
                                      :  Term::ANSIColor::colored( substr($code,3,3), "reverse $code" )
                                     ),
                            ' ') ;
                }
            }
            say "$y $z";
        }
        say "";
    }
   
 }


 # Save the RGB Grid values into HSL grid  
 # This saves a sparse matrix in nested hash form
 #
 # Modeled on Ack3 _show_rgb_grid, but with HSL and save instead of print
 # saves into %Where for sibling
sub _save_rgb_grid {
    # Optional statistics
    # my (%Hues,%Lums,%Sats);
    my %Where;
    for my $r ( 0 .. 5 ) {
        for my $g ( 0 .. 5 ) {
            for my $b ( 0 ..5 ) {

                my $rgb = "$r$g$b";
                my $code = "rgb$r$g$b";
                my $hsl = Convert::Color::RGB->new(map {(_five_to_1($_))} ($r, $g, $b))->as_hsl;
                my @HSL = ($hsl->hsl);
                # Optional collect stats 
                # my { ($h,$s,$l)=@HSL; $Hues{int $h+0.5}++; $Lums{$l}++; $Sats{$s}++; }
                my $hsl_code = sprintf q(h:%3d,s:%4.2f,l:%4.2f), @HSL;
                my ($x,$y, $z) = _where($hsl)->@*;
#                warn "Mapping white to [$x,$y, $z]" if 5==$r and 5==$g and 5==$b;
#                warn "[$x,$y] conflict #{[$Where{$y}->{$x}]} = $code (h=$HSL[0])"
#                    if defined $Where{$y}->{$x} ;
                push $Where{$z}->{$y}->{$x}->@* , { code => $code, hsl=> $hsl } ;

            }
        }
    }

    # say "Hues"; for my $k (sort {$a <=> $b} keys %Hues){ say "$Hues{$k}\t$k"; } 
    # say "Lums"; for my $k (sort {$a <=> $b} keys %Lums){ say "$Lums{$k}\t$k"; } 
    # say "Sats"; for my $k (sort {$a <=> $b}keys %Sats){ say "$Sats{$k}\t$k"; } 
    return \%Where;
}


 
=for samples 

# Inspecting Convert::Color POD sample values deeply 

use Data::Dump qw/dd/;

my $red = Convert::Color::HSL->new( 0, 1, 0.5 );
 
# Can also parse strings
say q(pink);
my $pink = Convert::Color::HSL->new( '0,1,0.8' );
dd $pink;
dd $pink->as_rgb;
dd $pink->as_rgb->as_hsl;

my $cyan = Convert::Color->new( 'hsl:300,1,0.5' );

say q(cyan);
dd $cyan;
dd $cyan->as_rgb;

say "132";
my $onethreetwo= Convert::Color::RGB->new(map {(_five_to_1($_))} (1, 3, 2));
dd $onethreetwo;
dd $onethreetwo->as_hsl->hsl;
dd $onethreetwo->as_hsl->chroma;

=cut

