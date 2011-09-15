%function [Urot,alpha,beta]=coordrot(U,IFLAG)
%modified Jan 08 by K. Anderson-Teixeira to implement planar fit technique,
%as described in Wilczak et al. 2001.
%program retains ability to do double or triple rotation. 

function [Urot,uvwmeanrot]=UNM_coordrot(U,SONDIAG)

    %Marcy's code: 
    
    % 1/21/2001 - modified to not consider NaNs when calculating means
    %
    % Routine to rotate the 3 X N wind vector matrix U=U(u,v,w) components .
    % The rotation can be either in a the horizontal (x,y) plane, or 3D
    % in (x,y,z), depending upon IFLAG.  
    %
    % IFLAG = 1
    % rotate only in the horizontal plane, such that the mean crosswind
    % velocity is zero
    %
    % IFLAG = 0 OR NO IFLAG
    % perform rotation of all axes such that both the mean crosswind and
    % vertical wind are zero
    
    IFLAG=0; %or 1, see above
     
    %if nargin==1
    %   IFLAG=0;
    %end

    ubar = mean(U(1, find(SONDIAG)));
    vbar = mean(U(2, find(SONDIAG)));
    wbar = mean(U(3, find(SONDIAG)));

    % ubar=mean(U(1, find(~isnan(U(1,:))) ));
    % vbar=mean(U(2, find(~isnan(U(2,:))) ));
    % wbar=mean(U(3, find(~isnan(U(3,:))) ));

    alpha = atan2(vbar,ubar);

    if IFLAG % rotate 3D

       beta = 0;

    else

       uhor = sqrt(ubar^2+vbar^2);
       beta = atan2(wbar,uhor);
       
    end
    
    %Urot are rotated 10Hz data with 3D rotation
    Urot(1,:) =  U(1,:).*cos(alpha).*cos(beta) + U(2,:).*sin(alpha).*cos(beta) + U(3,:).*sin(beta);
    Urot(2,:) = -U(1,:).*sin(alpha)            + U(2,:).*cos(alpha)                        ;
    Urot(3,:) = -U(1,:).*cos(alpha).*sin(beta) - U(2,:).*sin(alpha).*sin(beta) + U(3,:).*cos(beta);    
    
    Umeanrot = mean(Urot(1,find(SONDIAG)));
    Vmeanrot = mean(Urot(2,find(SONDIAG)));
    Wmeanrot = mean(Urot(3,find(SONDIAG)));
    uvwmeanrot = [Umeanrot Vmeanrot Wmeanrot];
    
    return