function  out  = replace_consecutive_with_condition( in, cond )
% REPLACE_CONSECUTIVE_WITH_CONDITION - replaces consecutive identical values
% within an array where a given condition is satisfied.
%
% MCon 2012 PAR record features several instances of high, constant values for
% several days at a time.  This function finds these bogus data and replaces
% them with NaN.  The condition (daytime, in this case) is necessary to avoid
% replacing nighttime PAR values, which should contain consecutive zeros (or
% near-zeros).
%
% USAGE
%     out  = replace_daytime_consecutive( in, cond );
%
% INPUTS
%    in: numeric vector; the input data to be searched and repaired
%    cond: logical vector; same size as in; only consecutive values where
%        cond is true are removed.
%
% OUTPUTS:
%    out: data from in with consecutive daytime values removed
%
% author: Timothy W. Hilton, UNM, 2013

runs = rle( in );
in_row = reshape( in, 1, [] );
runs = rle( in_row );
vals = runs{ 1 };
lengths = runs{ 2 };

% set whole array to false, then set instances of >=2 consecutive identical
% values to true.
vals( : ) = false;
vals( lengths > 2 ) = true;

idx = rle( { vals, lengths } );

% make sure index vectors are both row vectors
cond = reshape( cond, 1, [] );
idx = reshape( idx, 1, [] );

out = in;
out( idx & cond ) = NaN;
