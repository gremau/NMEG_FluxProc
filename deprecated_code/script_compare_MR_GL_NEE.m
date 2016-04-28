% within MPI Jena online gapfiller/partitioner output, compare data filled using
% Markus Reichstein's (MR) algorithm to data filled using Gita Lasslop's (GL)
% algorithm.

[MR, GL] = UNM_parse_gapfilled_partitioned_output( 1, 2010 );

% plot GL filling
figure()
h_orig = plot( MR.NEEorig, 'ko' );
ylim( [-8, 6] )
%xlim( [ 4000, 6000 ] );
hold on
h_GL = plot( GL.NEE_HBLR, 'r.' );
title( 'GL gapfilled fluxes (UNM Ameriflux files from here)' );
legend( [ h_orig, h_GL ], 'submitted to gapfiller', 'GL filled NEE' ); %

% plot MR filling
figure()
h_orig = plot( MR.NEEorig, 'ko' );
ylim( [-8, 6] )
%xlim( [ 4000, 6000 ] );
hold on
h_MR = plot( MR.NEE_f, 'r.' );
title( 'MR gapfilled fluxes' );
legend( [ h_orig, h_MR ], 'submitted to gapfiller', 'MR filled NEE' ); %

figure()
plot( MR.qcNEE, '.' );
title( MR.qcNEE); 
xlim( [ 4000, 6000 ] );