function rh_hmp = thmp_and_h2ohmp_2_rhhmp( t_hmp, h2o_hmp)
% THMP_AND_H2OHMP_2_RHHMP - calculate relative humidity from Vaisala HMP
% probe data.
%
% Helper function for UNM_RemoveBadData.  Calculate relative humidity (rh_hmp),
% in percent, from t_hmp and h2o_hmp according to datalogger code equation
% provided by LANL.  The original LANL datalogger code is below, in Matlab
% comments.  This code rearranges the LANL equations to calculate rh_hmp.
%
% USAGE:
%     rh_hmp = thmp_and_h2ohmp_2_rhhmp( t_hmp, h2o_hmp)
%
% INPUTS
%     t_hmp: hmp temperature, C
%     h2o_hmp: hmp vapor density (mg m-3)
%
% OUTPUTS:
%     rh_hmp: relative humidity, 0 to 100
%
% author: Timothy W. Hilton, UNM, May 2012
    
%constants:
    A_0 = 6.107800;           %Coefficients for the sixth order approximating
    A_1 = 4.436519e-1;        % saturation vapor pressure polynomial (Lowe,
    A_2 = 1.428946e-2;       % Paul R., 1976.:  An approximating polynomial for
    A_3 = 2.650648e-4;       % computation of saturation vapor pressure, J. Appl.
    A_4 = 3.031240e-6;       % Meteor., 16, 100-103).
    A_5 = 2.034081e-8;
    A_6 = 6.136821e-11;
    Rv =  0.0004615;         %Gas constant for water vapor [J/(mg K)].
    
    e_sat = ( 0.1 * ( A_0 + t_hmp .* ( A_1 + t_hmp .* ( A_2 + t_hmp .* ...
                                                      ( A_3 + t_hmp .* ...
                                                      ( A_4 + t_hmp .* ...
                                                      (A_5 + t_hmp .* ...
                                                      A_6)))))));
    
    rh_hmp = ( ( ( t_hmp + 273.15 ) * Rv ) .* h2o_hmp ) ./ ( e_sat * 0.01  );
    
    %----------
    % original LANL datalogger code:
    %
    %    'Measure the HMP45C temperature and fraction humidity.
    %    VoltDiff (t_hmp,2,mV1000,9,TRUE,200,250,0.1,0)
    %
    %   'Find the engineering units for the HMP45C temperature and humidity.
    %    t_hmp = t_hmp-40
    %    rh_hmp = rh_hmp*0.01
    %
    %   'Find the HMP45C vapor pressure, in kPa, using a sixth order polynomial
    %(Lowe, 1976).
    %    e_sat =
    %0.1*(A_0+t_hmp*(A_1+t_hmp*(A_2+t_hmp*(A_3+t_hmp*(A_4+t_hmp*(A_5+t_hmp*A_6))))))
    %    e = e_sat*rh_hmp
    %
    %   'Compute the HMP45C vapor density.
    %    h2o_hmp = e/((t_hmp+273.15)*RV)
    %
    %
    %Const RV = 0.0004615                'Gas constant for water vapor [J/(mg
    %K)].
    %
    %
    %Const A_0 = 6.107800                    'Coefficients for the sixth order
    %approximating
    %Const A_1 = 4.436519e-1            ' saturation vapor pressure polynomial
    %(Lowe,
    %Const A_2 = 1.428946e-2            ' Paul R., 1976.:  An approximating
    %polynomial for
    %Const A_3 = 2.650648e-4            ' computation of saturation vapor
    %pressure, J. Appl.
    %Const A_4 = 3.031240e-6            ' Meteor., 16, 100-103).
    %Const A_5 = 2.034081e-8
    %Const A_6 = 6.136821e-11